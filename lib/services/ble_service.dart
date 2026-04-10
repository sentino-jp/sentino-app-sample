import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../utils/generic_ble_packet_protocol.dart';

/// BLE scan result with parsed device info
class BleDeviceInfo {
  final BluetoothDevice device;
  String name;
  final String? uuid;
  final String? productId;
  final int rssi;
  final List<int> manufacturerData;
  String? imageUrl;
  bool infoLoaded;
  final int encryptType;
  final bool canBind;

  BleDeviceInfo({
    required this.device,
    required this.name,
    this.uuid,
    this.productId,
    required this.rssi,
    this.manufacturerData = const [],
    this.imageUrl,
    this.infoLoaded = false,
    this.encryptType = 0,
    this.canBind = true,
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
            .timeout(
              const Duration(seconds: 3),
              onTimeout: () => BluetoothAdapterState.off,
            );
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
  Future<void> startScan({
    Duration timeout = const Duration(seconds: 15),
  }) async {
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
          debugPrint(
            'BleService: found device ${info.name} uuid=${info.uuid} pid=${info.productId} rssi=${info.rssi}',
          );
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
  static final Guid _writeCharUuid = Guid(
    '00002b11-0000-1000-8000-00805f9b34fb',
  );
  static final Guid _notifyCharUuid = Guid(
    '00002b10-0000-1000-8000-00805f9b34fb',
  );

  /// Discover services and find the pairing write characteristic (UUID 2b11)
  Future<BluetoothCharacteristic?> findPairingCharacteristic(
    BluetoothDevice device,
  ) async {
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

  /// Send pairing data (JSON map) to device via BLE using RLink protocol
  Future<bool> sendPairingData(
    BluetoothCharacteristic characteristic,
    Map<String, dynamic> data,
  ) async {
    final jsonStr = jsonEncode(data);
    return sendPairingDataRaw(characteristic, jsonStr);
  }

  /// Send raw string data to device via BLE using RLink protocol
  Future<bool> sendPairingDataRaw(
    BluetoothCharacteristic characteristic,
    String data,
  ) async {
    try {
      final payloadBytes = utf8.encode(data);
      final packets = BleProtocol.encode(payloadBytes);
      debugPrint('BleService: sending ${packets.length} BLE packets');
      for (final packet in packets) {
        await characteristic.write(packet, withoutResponse: false);
        await Future.delayed(const Duration(milliseconds: 10));
      }
      return true;
    } catch (e) {
      debugPrint('BleService: sendPairingDataRaw error: $e');
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
  /// Android BleManager.scanResultDeal 解析逻辑：
  /// - 0xFF (Manufacturer Data): data[length-17..length-1] = UUID (16字节 UTF-8 字符串)
  /// - 0x16 (Service Data): data[3..end] = PID (UTF-8 字符串)
  /// - data[2] bit6: 绑定标志, bit7: 配网标志
  /// - data[4]: 加密类型
  BleDeviceInfo _parseScanResult(ScanResult result) {
    String? uuid;
    String? productId;
    int encryptType = 0;
    bool canBind = true;
    final manufacturerData = <int>[];

    // 解析 manufacturer data (0xFF) 获取设备 UUID
    if (result.advertisementData.manufacturerData.isNotEmpty) {
      for (final entry in result.advertisementData.manufacturerData.entries) {
        manufacturerData.addAll(entry.value);
      }
      // Android: ByteUtils.byteArrayToString(ByteUtils.subBytes(data, length - 17, 16))
      // flutter_blue_plus 的 value 不含 company ID 的 2 字节
      final data = manufacturerData;
      if (data.length >= 17) {
        try {
          // 取倒数第 17 到倒数第 1 字节（16字节），转 UTF-8 字符串，去尾部 0
          final uuidBytes = data.sublist(data.length - 17, data.length - 1);
          // 去尾部 0
          var len = uuidBytes.length;
          for (var i = 0; i < uuidBytes.length; i++) {
            if (uuidBytes[i] == 0) {
              len = i;
              break;
            }
          }
          uuid = String.fromCharCodes(uuidBytes.sublist(0, len));
          debugPrint(
            'BleService: parsed UUID=$uuid (${uuidBytes.length} bytes)',
          );
        } catch (e) {
          debugPrint('BleService: UUID parse error: $e');
        }
      }
      // 解析绑定标志和加密类型
      if (data.length > 4) {
        canBind = ((data[2] >> 6) & 1) == 0;
        encryptType = data[4] & 0xFF;
        debugPrint('BleService: canBind=$canBind, encryptType=$encryptType');
      }
    }

    // 解析 Service Data (0x16) 获取 PID
    if (result.advertisementData.serviceData.isNotEmpty) {
      for (final entry in result.advertisementData.serviceData.entries) {
        final data = entry.value;
        // Android: ByteUtils.byteArrayToString(ByteUtils.subBytes(data, 3, data.length - 3))
        if (data.length > 3) {
          try {
            final pidBytes = data.sublist(3);
            var len = pidBytes.length;
            for (var i = 0; i < pidBytes.length; i++) {
              if (pidBytes[i] == 0) {
                len = i;
                break;
              }
            }
            productId = String.fromCharCodes(pidBytes.sublist(0, len));
            debugPrint('BleService: parsed PID=$productId');
          } catch (e) {
            debugPrint('BleService: PID parse error: $e');
          }
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
      encryptType: encryptType,
      canBind: canBind,
    );
  }

  /// Dispose resources
  void dispose() {
    stopScan();
    _scanController.close();
  }
}
