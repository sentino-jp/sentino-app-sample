import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../utils/generic_ble_advertisement_parser.dart';
import '../utils/generic_ble_packet_protocol.dart';

/// BLE scan result with parsed device info.
class BleDeviceInfo {
  final BluetoothDevice device;
  String name;
  String? uuid;
  String? productId;
  int rssi;
  String? imageUrl;
  bool infoLoaded;
  int configFlag;

  BleDeviceInfo({
    required this.device,
    required this.name,
    this.uuid,
    this.productId,
    required this.rssi,
    this.imageUrl,
    this.infoLoaded = false,
    this.configFlag = 1,
  });

  void updateFrom(BleDeviceInfo other) {
    uuid ??= other.uuid;
    productId ??= other.productId;
    rssi = other.rssi;
    configFlag = other.configFlag;
  }
}

class BlePairingCharacteristics {
  final BluetoothCharacteristic write;
  final BluetoothCharacteristic? notify;

  const BlePairingCharacteristics({required this.write, this.notify});
}

class BleWifiNetwork {
  final String ssid;
  final int? rssi;
  final bool? security;
  final Map<String, dynamic> raw;

  const BleWifiNetwork({
    required this.ssid,
    this.rssi,
    this.security,
    this.raw = const {},
  });
}

/// BLE pairing service using flutter_blue_plus.
class BleService {
  static final BleService _instance = BleService._();
  factory BleService() => _instance;
  BleService._();

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  final _scannedDevices = <String, BleDeviceInfo>{};
  final _scanController = StreamController<List<BleDeviceInfo>>.broadcast();

  static final Guid _serviceUuid = Guid('00001910-0000-1000-8000-00805f9b34fb');
  static final Guid _writeCharUuid = Guid(
    '00002b11-0000-1000-8000-00805f9b34fb',
  );
  static final Guid _notifyCharUuid = Guid(
    '00002b10-0000-1000-8000-00805f9b34fb',
  );

  /// Stream of scanned BLE devices.
  Stream<List<BleDeviceInfo>> get scanResults => _scanController.stream;

  /// Current scanned devices.
  List<BleDeviceInfo> get devices => _scannedDevices.values.toList();

  /// Check if Bluetooth is supported and on.
  Future<bool> isBluetoothAvailable() async {
    if (kIsWeb) return false;
    try {
      final isSupported = await FlutterBluePlus.isSupported;
      if (!isSupported) return false;

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

  /// Start scanning for BLE devices.
  Future<void> startScan({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    _scannedDevices.clear();
    _scanController.add([]);

    await stopScan();

    try {
      _scanSubscription = FlutterBluePlus.onScanResults.listen((results) {
        for (final result in results) {
          final name = result.device.platformName;
          if (name != 'RY') continue;
          final fresh = _parseScanResult(result);
          final deviceId = result.device.remoteId.str;
          final existing = _scannedDevices[deviceId];
          final info = existing ?? fresh;
          if (existing != null) {
            existing.updateFrom(fresh);
          }

          if (info.uuid == null ||
              info.uuid!.trim().isEmpty ||
              info.productId == null ||
              info.productId!.trim().isEmpty) {
            _scannedDevices.remove(deviceId);
            continue;
          }
          debugPrint('BleService: found deviceId $deviceId');
          _scannedDevices[deviceId] = info;
          debugPrint(
            'BleService: found device ${info.name} uuid=${info.uuid} pid=${info.productId} rssi=${info.rssi}',
          );
        }
        _scanController.add(_scannedDevices.values.toList());
      });

      await FlutterBluePlus.startScan(
        timeout: timeout == Duration.zero ? const Duration(hours: 1) : timeout,
        androidUsesFineLocation: true,
      );
    } catch (e) {
      debugPrint('BleService: startScan error: $e');
    }
  }

  /// Stop scanning.
  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
      await _scanSubscription?.cancel();
      _scanSubscription = null;
    } catch (e) {
      debugPrint('BleService: stopScan error: $e');
    }
  }

  /// Connect to a BLE device.
  Future<BluetoothDevice?> connectDevice(BleDeviceInfo deviceInfo) async {
    try {
      if (!deviceInfo.device.isConnected) {
        await deviceInfo.device.connect(timeout: const Duration(seconds: 10));
      }
      return deviceInfo.device;
    } catch (e) {
      debugPrint('BleService: connectDevice error: $e');
      return null;
    }
  }

  /// Discover services and find the pairing write characteristic.
  Future<BluetoothCharacteristic?> findPairingCharacteristic(
    BluetoothDevice device,
  ) async {
    final chars = await findPairingCharacteristics(device);
    return chars?.write;
  }

  Future<BluetoothCharacteristic?> findNotifyCharacteristic(
    BluetoothDevice device,
  ) async {
    final chars = await findPairingCharacteristics(device);
    return chars?.notify;
  }

  Future<BlePairingCharacteristics?> findPairingCharacteristics(
    BluetoothDevice device,
  ) async {
    try {
      final services = await device.discoverServices();
      BluetoothCharacteristic? writeChar;
      BluetoothCharacteristic? notifyChar;

      for (final service in services) {
        if (service.uuid == _serviceUuid) {
          for (final char in service.characteristics) {
            if (char.uuid == _writeCharUuid) {
              writeChar = char;
            } else if (char.uuid == _notifyCharUuid) {
              notifyChar = char;
            }
          }
        }
      }

      if (writeChar != null) {
        return BlePairingCharacteristics(write: writeChar, notify: notifyChar);
      }

      for (final service in services) {
        for (final char in service.characteristics) {
          if (writeChar == null &&
              (char.properties.write || char.properties.writeWithoutResponse)) {
            writeChar = char;
          }
          if (notifyChar == null &&
              (char.properties.notify || char.properties.indicate)) {
            notifyChar = char;
          }
        }
      }

      if (writeChar != null) {
        return BlePairingCharacteristics(write: writeChar, notify: notifyChar);
      }
    } catch (e) {
      debugPrint('BleService: findPairingCharacteristics error: $e');
    }
    return null;
  }

  /// Send pairing data (JSON map) to device via BLE using BLE packet framing.
  Future<bool> sendPairingData(
    BluetoothCharacteristic characteristic,
    Map<String, dynamic> data,
  ) async {
    return sendPairingDataRaw(characteristic, jsonEncode(data));
  }

  /// Send raw string data to device via BLE using BleProtocol framing.
  Future<bool> sendPairingDataRaw(
    BluetoothCharacteristic characteristic,
    String data,
  ) async {
    try {
      final packets = BleProtocol.encodeUtf8(data);
      final withoutResponse =
          !characteristic.properties.write &&
          characteristic.properties.writeWithoutResponse;
      debugPrint('BleService: sending ${packets.length} BLE packets');
      for (final packet in packets) {
        await characteristic.write(packet, withoutResponse: withoutResponse);
        await Future.delayed(const Duration(milliseconds: 10));
      }
      return true;
    } catch (e) {
      debugPrint('BleService: sendPairingDataRaw error: $e');
      return false;
    }
  }

  Future<List<BleWifiNetwork>> requestDeviceWifiList(
    BluetoothDevice device, {
    Duration timeout = const Duration(seconds: 15),
    bool? scan = true,
  }) async {
    if (device.isDisconnected) {
      throw Exception('BLE_NOT_CONNECTED');
    }

    final chars = await findPairingCharacteristics(device);
    if (chars == null || chars.notify == null) {
      throw Exception('BLE_WIFI_SCAN_NOT_SUPPORTED');
    }

    final notifyChar = chars.notify!;
    final payloadAssembler = BlePacketAssembler();
    final completer = Completer<List<BleWifiNetwork>>();
    StreamSubscription<List<int>>? subscription;
    var latestNetworks = <BleWifiNetwork>[];

    try {
      subscription = notifyChar.onValueReceived.listen((value) {
        final payload = payloadAssembler.addBytes(value);
        if (payload == null) return;

        final text = BleProtocol.decodeUtf8Payload(payload);
        if (text == null || text.trim().isEmpty) return;

        debugPrint('BleService: wifi scan response=$text');
        final error = _parseWifiScanError(text);
        if (error != null) {
          if (!completer.isCompleted) {
            completer.completeError(Exception(error));
          }
          return;
        }

        final parsed = _parseWifiScanResponse(text);
        if (parsed == null) return;

        latestNetworks = parsed;
        if (!completer.isCompleted) {
          completer.complete(latestNetworks);
        }
      });

      notifyChar.device.cancelWhenDisconnected(subscription);
      await notifyChar.setNotifyValue(true);

      final request = <String, dynamic>{
        'type': GenericBleProtocolConfig.protocolNetworkGetWifis,
      };
      if (scan != null) {
        request['scan'] = scan;
      }

      final sent = await sendPairingData(chars.write, request);
      if (!sent) {
        throw Exception('BLE_WIFI_SCAN_REQUEST_FAILED');
      }

      return await completer.future.timeout(
        timeout,
        onTimeout: () => latestNetworks,
      );
    } finally {
      await subscription?.cancel();
    }
  }

  /// Disconnect from device.
  Future<void> disconnect(BluetoothDevice device) async {
    try {
      await device.disconnect();
    } catch (e) {
      debugPrint('BleService: disconnect error: $e');
    }
  }

  BleDeviceInfo _parseScanResult(ScanResult result) {
    final serviceData = GenericBleAdvertisementParser.parseServiceData(
      result.advertisementData.serviceData,
    );
    final mfgInfo = GenericBleAdvertisementParser.parseManufacturerData(
      result.advertisementData.manufacturerData,
    );

    return BleDeviceInfo(
      device: result.device,
      name: result.device.platformName,
      uuid: mfgInfo?.idText,
      productId: serviceData?.pid,
      rssi: result.rssi,
      configFlag: mfgInfo?.flag ?? 1,
    );
  }

  List<BleWifiNetwork>? _parseWifiScanResponse(String text) {
    dynamic decoded;
    try {
      decoded = jsonDecode(text);
    } catch (_) {
      return null;
    }

    if (decoded is! Map) return null;

    final map = decoded.map((key, value) => MapEntry(key.toString(), value));
    if (map['type']?.toString() !=
        GenericBleProtocolConfig.protocolNetworkGetWifisResponse) {
      return null;
    }

    final code = _parseInt(map['code']);
    if (code != null && code != 0) {
      return null;
    }

    final entries = _extractWifiEntries(map['data']);
    if (entries == null) return null;

    final bySsid = <String, BleWifiNetwork>{};
    for (final entry in entries) {
      final network = _toWifiNetwork(entry);
      if (network == null) continue;

      final existing = bySsid[network.ssid];
      if (existing == null ||
          ((network.rssi ?? -9999) > (existing.rssi ?? -9999))) {
        bySsid[network.ssid] = network;
      }
    }

    final networks = bySsid.values.toList()
      ..sort((a, b) => (b.rssi ?? -9999).compareTo(a.rssi ?? -9999));
    return networks;
  }

  String? _parseWifiScanError(String text) {
    dynamic decoded;
    try {
      decoded = jsonDecode(text);
    } catch (_) {
      return null;
    }

    if (decoded is! Map) return null;

    final map = decoded.map((key, value) => MapEntry(key.toString(), value));
    if (map['type']?.toString() !=
        GenericBleProtocolConfig.protocolNetworkGetWifisResponse) {
      return null;
    }

    final code = _parseInt(map['code']);
    if (code == null || code == 0) return null;

    final message = map['message']?.toString().trim();
    if (message != null && message.isNotEmpty) {
      return 'BLE_WIFI_SCAN_FAILED($code): $message';
    }
    return 'BLE_WIFI_SCAN_FAILED($code)';
  }

  List<dynamic>? _extractWifiEntries(dynamic value) {
    if (value is List) return value;
    if (value is String) return [value];

    if (value is Map) {
      final map = value.map((key, val) => MapEntry(key.toString(), val));
      final candidates = [
        map['wifis'],
        map['wifiList'],
        map['ssids'],
        map['list'],
        map['result'],
        map['data'],
      ];

      for (final candidate in candidates) {
        final entries = _extractWifiEntries(candidate);
        if (entries != null) return entries;
      }
    }

    return null;
  }

  BleWifiNetwork? _toWifiNetwork(dynamic entry) {
    if (entry is String) {
      final ssid = entry.trim();
      if (ssid.isEmpty) return null;
      return BleWifiNetwork(ssid: ssid);
    }

    if (entry is! Map) return null;

    final map = entry.map((key, value) => MapEntry(key.toString(), value));
    final ssid =
        (map['ssid'] ?? map['name'] ?? map['wifiName'] ?? map['apName'] ?? '')
            .toString()
            .trim();
    if (ssid.isEmpty) return null;

    return BleWifiNetwork(
      ssid: ssid,
      rssi: _parseInt(
        map['rssi'] ??
            map['level'] ??
            map['signal'] ??
            map['dbm'] ??
            map['power'],
      ),
      security: _parseBool(map['security']),
      raw: Map<String, dynamic>.from(map),
    );
  }

  int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  bool? _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value == null) return null;

    final normalized = value.toString().trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
    return null;
  }

  /// Dispose resources.
  void dispose() {
    stopScan();
    _scanController.close();
  }
}
