import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// BLE scan result with parsed device info
class BleDeviceInfo {
  final BluetoothDevice device;
  final String name;
  final String? uuid;
  final String? productId;
  final int rssi;
  final List<int> manufacturerData;

  BleDeviceInfo({
    required this.device,
    required this.name,
    this.uuid,
    this.productId,
    required this.rssi,
    this.manufacturerData = const [],
  });
}

/// BLE pairing service using flutter_blue_plus
class BleService {
  static final BleService _instance = BleService._();
  factory BleService() => _instance;
  BleService._();

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  final _scannedDevices = <String, BleDeviceInfo>{};
  final _scanController = StreamController<List<BleDeviceInfo>>.broadcast();

  /// Stream of scanned BLE devices
  Stream<List<BleDeviceInfo>> get scanResults => _scanController.stream;

  /// Current scanned devices
  List<BleDeviceInfo> get devices => _scannedDevices.values.toList();

  /// Check if Bluetooth is supported and on
  Future<bool> isBluetoothAvailable() async {
    if (kIsWeb) return false;
    try {
      final isSupported = await FlutterBluePlus.isSupported;
      if (!isSupported) return false;
      // 先检查当前状态，如果未知则等待状态更新
      var state = FlutterBluePlus.adapterStateNow;
      if (state == BluetoothAdapterState.unknown) {
        state = await FlutterBluePlus.adapterState
            .where((s) => s != BluetoothAdapterState.unknown)
            .first
            .timeout(const Duration(seconds: 3),
                onTimeout: () => BluetoothAdapterState.off);
      }
      debugPrint('BleService: adapterState=$state');
      return state == BluetoothAdapterState.on;
    } catch (e) {
      debugPrint('BleService: isBluetoothAvailable error: $e');
      return false;
    }
  }

  /// Start scanning for BLE devices
  /// Filters for devices with name "RY" (IoT devices, matching Android)
  Future<void> startScan({Duration timeout = const Duration(seconds: 15)}) async {
    _scannedDevices.clear();
    _scanController.add([]);

    await stopScan();

    try {
      _scanSubscription = FlutterBluePlus.onScanResults.listen((results) {
        for (final r in results) {
          final name = r.device.platformName;
          // Android 过滤：设备名完全等于 "RY"（与 Android ScanFilter.setDeviceName 一致）
          if (name != 'RY') continue;

          final info = _parseScanResult(r);
          _scannedDevices[r.device.remoteId.str] = info;
          debugPrint('BleService: found device ${info.name} uuid=${info.uuid} pid=${info.productId} rssi=${info.rssi}');
        }
        _scanController.add(_scannedDevices.values.toList());
      });

      // 不使用 withServices 过滤，设备广播中可能不包含 Service UUID
      await FlutterBluePlus.startScan(
        timeout: timeout == Duration.zero ? const Duration(hours: 1) : timeout,
        androidUsesFineLocation: true,
      );
    } catch (e) {
      debugPrint('BleService: startScan error: $e');
    }
  }

  /// Stop scanning
  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
      await _scanSubscription?.cancel();
      _scanSubscription = null;
    } catch (e) {
      debugPrint('BleService: stopScan error: $e');
    }
  }

  /// Connect to a BLE device
  Future<BluetoothDevice?> connectDevice(BleDeviceInfo deviceInfo) async {
    try {
      await deviceInfo.device.connect(timeout: const Duration(seconds: 10));
      return deviceInfo.device;
    } catch (e) {
      debugPrint('BleService: connectDevice error: $e');
      return null;
    }
  }

  /// 主服务 UUID (1910) 和写特征 UUID (2b11)，与 Android 一致
  static final Guid _serviceUuid = Guid('00001910-0000-1000-8000-00805f9b34fb');
  static final Guid _writeCharUuid = Guid('00002b11-0000-1000-8000-00805f9b34fb');
  static final Guid _notifyCharUuid = Guid('00002b10-0000-1000-8000-00805f9b34fb');

  /// Discover services and find the pairing write characteristic (UUID 2b11)
  Future<BluetoothCharacteristic?> findPairingCharacteristic(
      BluetoothDevice device) async {
    try {
      final services = await device.discoverServices();
      for (final service in services) {
        if (service.uuid == _serviceUuid) {
          for (final char in service.characteristics) {
            if (char.uuid == _writeCharUuid) {
              return char;
            }
          }
        }
      }
      // Fallback: 如果没找到指定 UUID，尝试通用可写特征
      for (final service in services) {
        for (final char in service.characteristics) {
          if (char.properties.write || char.properties.writeWithoutResponse) {
            return char;
          }
        }
      }
    } catch (e) {
      debugPrint('BleService: findPairingCharacteristic error: $e');
    }
    return null;
  }

  /// Send pairing data (WiFi credentials) to device via BLE
  Future<bool> sendPairingData(
    BluetoothCharacteristic characteristic,
    Map<String, dynamic> data,
  ) async {
    try {
      final jsonStr = jsonEncode(data);
      final bytes = utf8.encode(jsonStr);

      // Send in chunks if data is large (BLE MTU is typically 20-512 bytes)
      const chunkSize = 20;
      for (var i = 0; i < bytes.length; i += chunkSize) {
        final end = (i + chunkSize > bytes.length) ? bytes.length : i + chunkSize;
        final chunk = bytes.sublist(i, end);
        await characteristic.write(chunk, withoutResponse: false);
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return true;
    } catch (e) {
      debugPrint('BleService: sendPairingData error: $e');
      return false;
    }
  }

  /// Disconnect from device
  Future<void> disconnect(BluetoothDevice device) async {
    try {
      await device.disconnect();
    } catch (e) {
      debugPrint('BleService: disconnect error: $e');
    }
  }

  /// Parse scan result to extract device info
  /// Android 从广播数据 0xFF (Manufacturer Specific Data) 中解析 UUID
  /// UUID 位于 manufacturer data 的倒数第 17 到倒数第 2 字节（16字节）
  BleDeviceInfo _parseScanResult(ScanResult result) {
    String? uuid;
    String? productId;
    final manufacturerData = <int>[];

    // 解析 manufacturer data 获取设备 UUID
    if (result.advertisementData.manufacturerData.isNotEmpty) {
      for (final entry in result.advertisementData.manufacturerData.entries) {
        manufacturerData.addAll(entry.value);
      }
      // Android: ByteUtils.subBytes(data, length - 17, 16) 取 UUID
      if (manufacturerData.length >= 17) {
        try {
          final uuidBytes = manufacturerData.sublist(
              manufacturerData.length - 17, manufacturerData.length - 1);
          uuid = uuidBytes
              .map((b) => b.toRadixString(16).padLeft(2, '0'))
              .join();
          debugPrint('BleService: parsed UUID from manufacturer data: $uuid');
        } catch (e) {
          debugPrint('BleService: UUID parse error: $e');
        }
      }
    }

    return BleDeviceInfo(
      device: result.device,
      name: result.device.platformName,
      uuid: uuid,
      productId: productId,
      rssi: result.rssi,
      manufacturerData: manufacturerData,
    );
  }

  /// Dispose resources
  void dispose() {
    stopScan();
    _scanController.close();
  }
}
