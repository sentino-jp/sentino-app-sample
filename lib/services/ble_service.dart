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
      final state = FlutterBluePlus.adapterStateNow;
      return state == BluetoothAdapterState.on;
    } catch (e) {
      debugPrint('BleService: isBluetoothAvailable error: $e');
      return false;
    }
  }

  /// Start scanning for BLE devices
  /// Filters for devices with names (likely IoT devices)
  Future<void> startScan({Duration timeout = const Duration(seconds: 15)}) async {
    _scannedDevices.clear();
    _scanController.add([]);

    await stopScan();

    try {
      _scanSubscription = FlutterBluePlus.onScanResults.listen((results) {
        for (final r in results) {
          if (r.device.platformName.isEmpty) continue;

          final info = _parseScanResult(r);
          _scannedDevices[r.device.remoteId.str] = info;
        }
        _scanController.add(_scannedDevices.values.toList());
      });

      await FlutterBluePlus.startScan(
        timeout: timeout,
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

  /// Discover services and find the pairing characteristic
  Future<BluetoothCharacteristic?> findPairingCharacteristic(
      BluetoothDevice device) async {
    try {
      final services = await device.discoverServices();
      for (final service in services) {
        for (final char in service.characteristics) {
          // Look for writable characteristic (used for sending pairing data)
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
  BleDeviceInfo _parseScanResult(ScanResult result) {
    String? uuid;
    String? productId;
    final manufacturerData = <int>[];

    // Parse manufacturer data to extract UUID and product ID
    if (result.advertisementData.manufacturerData.isNotEmpty) {
      for (final entry in result.advertisementData.manufacturerData.entries) {
        manufacturerData.addAll(entry.value);
      }
      // Try to parse UUID and productId from manufacturer data
      // Format varies by device, this is a common pattern
      if (manufacturerData.length >= 16) {
        try {
          uuid = String.fromCharCodes(
              manufacturerData.sublist(0, manufacturerData.length.clamp(0, 16)));
        } catch (_) {}
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
