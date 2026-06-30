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
    if (name.isEmpty && other.name.isNotEmpty) name = other.name;
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
          if (!_isTargetDevice(result)) continue;

          final deviceId = result.device.remoteId.str;
          final fresh = _parseScanResult(result);

          // 跨回调累积:先把记录登记进缓冲区,再用后续广播补齐缺失字段。
          // 关键:不能在字段不完整时 remove —— 本机型广播总长约 56B > 单包 31B
          // 上限,必然把 uuid(厂商数据)与 productId(服务数据)拆进
          // ADV_IND 与 SCAN_RSP 两包。若不完整就 remove,两半永远无法在
          // updateFrom 里凑齐(先有鸡先有蛋死锁),设备永远进不了列表。
          final existing = _scannedDevices[deviceId];
          if (existing != null) {
            existing.updateFrom(fresh);
          } else {
            _scannedDevices[deviceId] = fresh;
            debugPrint(
              'BleService: matched deviceId=$deviceId '
              'plat="${result.device.platformName}" '
              'adv="${result.advertisementData.advName}"',
            );
          }
          final info = _scannedDevices[deviceId]!;

          if (_isIdentityComplete(info)) {
            debugPrint(
              'BleService: found device ${info.name} '
              'uuid=${info.uuid} pid=${info.productId} rssi=${info.rssi}',
            );
          }
        }

        // 只把身份完整(uuid + productId 均非空)的设备暴露给上层;
        // 不完整的留在缓冲区等待后续广播补齐。
        _scanController.add(
          _scannedDevices.values.where(_isIdentityComplete).toList(),
        );
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

  /// 解析广播里的设备名。
  ///
  /// iOS 上 `device.platformName`(= CBPeripheral.name)在扫描阶段常为空、
  /// 为系统跨启动缓存的陈旧名、或与 GAP(0x2A00)名不一致,与设备实际广播的
  /// Local Name 是两个独立字段。广播名应优先取 `advertisementData.advName`
  /// (= kCBAdvDataLocalName,每包刷新且不跨启动缓存),再兜底 platformName。
  static String _resolveName(ScanResult result) {
    final adv = result.advertisementData.advName.trim();
    if (adv.isNotEmpty) return adv;
    return result.device.platformName.trim();
  }

  /// 是否为目标设备(Sentino 待配网设备,广播名 "RY")。
  ///
  /// 名称匹配优先用广播名;再兜底用广播携带的 Sentino 服务 UUID(A101),
  /// 以彻底摆脱 iOS 名称字段不可靠的问题。
  static bool _isTargetDevice(ScanResult result) {
    if (_resolveName(result) == 'RY') return true;
    return result.advertisementData.serviceUuids.any(
      (g) => g.toString().toLowerCase().contains('a101'),
    );
  }

  /// 身份是否完整:uuid(厂商数据)与 productId(服务数据)均非空。
  static bool _isIdentityComplete(BleDeviceInfo info) =>
      (info.uuid?.trim().isNotEmpty ?? false) &&
      (info.productId?.trim().isNotEmpty ?? false);

  BleDeviceInfo _parseScanResult(ScanResult result) {
    final serviceData = GenericBleAdvertisementParser.parseServiceData(
      result.advertisementData.serviceData,
    );
    final mfgInfo = GenericBleAdvertisementParser.parseManufacturerData(
      result.advertisementData.manufacturerData,
    );

    return BleDeviceInfo(
      device: result.device,
      name: _resolveName(result),
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
