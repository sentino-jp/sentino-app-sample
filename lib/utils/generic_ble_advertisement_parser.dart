import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '/utils/generic_ble_packet_protocol.dart';

/// 通用 BLE 广播解析工具
///
/// 用途：
/// - 从广播中的 manufacturerData / serviceData 提取设备标识信息
/// - 当前主要用于解析厂商自定义数据（含绑定状态、通信能力、设备ID等）
class GenericBleAdvertisementParser {
  /// 去掉字节数组末尾的 0（部分设备会把固定长度字段用 0 填充）
  static List<int> _trimZeroTail(List<int> bytes) {
    var end = bytes.length;
    while (end > 0 && bytes[end - 1] == 0) {
      end--;
    }
    return bytes.sublist(0, end);
  }

  /// 按协议解析 serviceData 负载
  ///
  /// 当前约定：
  /// - 当 [type] == 0 时尝试解析 PID（产品/设备标识）
  /// - payload 长度在 14~16 之间才尝试解析（协议约束/经验值）
  static ServiceDataInfo? _parseServiceDataBytes({
    required int type,
    required List<int> payload,
  }) {
    String? pid;
    if (type == 0) {
      if (payload.length >= 14 && payload.length <= 16) {
        final cleaned = _trimZeroTail(payload);
        try {
          // 关键逻辑：如果都是可打印 ASCII，则直接按字符串解码；否则按 hex 输出
          final isPrintable = cleaned.every((b) => b >= 32 && b <= 126);
          if (isPrintable && cleaned.isNotEmpty) {
            pid = utf8.decode(cleaned, allowMalformed: true).trim();
          } else {
            pid = cleaned
                .map((e) => e.toRadixString(16).padLeft(2, '0'))
                .join();
          }
        } catch (_) {
          pid = cleaned.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
        }
      }
    }
    return ServiceDataInfo(type: type, payload: payload, pid: pid);
  }

  /// 解析 Manufacturer Data（厂商自定义广播数据）
  static ManufacturerDataInfo? parseManufacturerData(
    Map<int, List<int>> manufacturerData,
  ) {
    if (!manufacturerData.containsKey(
      GenericBleProtocolConfig.manufacturerKey,
    )) {
      return null;
    }

    final bytes = manufacturerData[GenericBleProtocolConfig.manufacturerKey]!;
    if (bytes.length < 6) return null;

    // 根据后端协议文档解析 ManufacturerData：
    // 0: config_flag（配网状态标志）
    // 1: protocol_version（协议版本）
    // 2: encryption_method（加密方式）
    // 3~4: commun_capability（通信能力，高字节在前）
    // 5: 标识类型（0-uuid，1-mac）
    // 6..: 标识内容（uuid 为 ASCII 文本，业务侧最多取 19 字节）
    final flag = bytes[0];
    final protocolVersion = bytes[1];
    final encryptionMode = bytes[2];
    final commAbility = (bytes[3] << 8) | bytes[4];
    final idType = bytes[5];

    final idStart = 6;
    final idEnd = bytes.length > idStart + 19 ? idStart + 19 : bytes.length;
    final idBytes = bytes.length > idStart
        ? bytes.sublist(idStart, idEnd)
        : <int>[];

    return ManufacturerDataInfo(
      flag: flag,
      protocolVersion: protocolVersion,
      encryptionMode: encryptionMode,
      commAbility: commAbility,
      idType: idType,
      idBytes: idBytes,
    );
  }

  /// 解析 Service Data
  ///
  /// 当前兼容两种形式：
  /// - UUID 文本包含 'a101'（不同平台/设备可能会把服务 UUID 表现为不同形式）
  /// - 数据前缀为 0xA1,0x01（协议头），第三个字节为 type
  static ServiceDataInfo? parseServiceData(Map<Guid, List<int>> serviceData) {
    for (final entry in serviceData.entries) {
      final uuidText = entry.key.toString().toLowerCase();
      final bytes = entry.value;
      if (bytes.isEmpty) continue;

      if (uuidText.contains('a101')) {
        final type = bytes[0];
        final payload = bytes.length > 1 ? bytes.sublist(1) : const <int>[];
        return _parseServiceDataBytes(type: type, payload: payload);
      }

      if (bytes.length >= 3 && bytes[0] == 0xA1 && bytes[1] == 0x01) {
        final type = bytes[2];
        final payload = bytes.length > 3 ? bytes.sublist(3) : const <int>[];
        return _parseServiceDataBytes(type: type, payload: payload);
      }
    }
    return null;
  }
}

class ManufacturerDataInfo {
  /// 配网状态标志（示例：0x01-待配网）
  final int flag;

  /// 协议版本（示例：0x03-双模配网）
  final int protocolVersion;

  /// 加密方式（0-不加密）
  final int encryptionMode;

  /// 通信能力（高字节在前的 16bit 位图）
  final int commAbility;

  /// 标识类型：0-uuid（ASCII），1-mac（hex）
  final int idType;

  final List<int> idBytes;

  ManufacturerDataInfo({
    required this.flag,
    required this.protocolVersion,
    required this.encryptionMode,
    required this.commAbility,
    required this.idType,
    required this.idBytes,
  });

  List<int> get _cleanedIdBytes =>
      GenericBleAdvertisementParser._trimZeroTail(idBytes);

  /// 尝试把 [idBytes] 当作 UTF-8 文本解析（仅当全部是可打印 ASCII）
  String? get idAsUtf8 {
    try {
      // UUID 内容为 ASCII，部分设备会用 0 填充尾部，这里先去尾 0 再判断是否可打印
      final cleaned = _cleanedIdBytes;
      if (cleaned.isEmpty) return null;
      if (cleaned.any((b) => b == 0)) return null;
      if (cleaned.every((b) => b >= 32 && b <= 126)) {
        return utf8.decode(cleaned, allowMalformed: true);
      }
    } catch (_) {}
    return null;
  }

  /// UUID（仅当 [idType]==0 且内容为 ASCII 时）
  String? get uuid => idType == 0 ? idAsUtf8 : null;

  /// MAC（仅当 [idType]==1）
  ///
  /// 兼容两类情况：
  /// - 原始 6 字节 MAC：格式化为 AA:BB:CC:DD:EE:FF
  /// - ASCII 文本 MAC：如 "aabbccddeeff" 或 "aa:bb:cc:dd:ee:ff"
  String? get mac {
    if (idType != 1) return null;

    final ascii = idAsUtf8?.trim();
    if (ascii != null && ascii.isNotEmpty) {
      final normalized = ascii.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
      if (normalized.length == 12) {
        final pairs = <String>[];
        for (var i = 0; i < 12; i += 2) {
          pairs.add(normalized.substring(i, i + 2).toUpperCase());
        }
        return pairs.join(':');
      }
      return ascii;
    }

    final cleaned = _cleanedIdBytes;
    if (cleaned.length < 6) return null;
    return cleaned
        .take(6)
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(':');
  }

  /// 统一输出设备标识：
  /// - idType=0 优先输出 uuid
  /// - idType=1 优先输出 mac
  /// - 其余兜底输出可打印 ASCII 或 hex
  String get idText => (uuid ?? mac ?? idAsUtf8 ?? idHex).trim();

  /// 是否待配网（0x01-待配网）
  bool get isPendingProvision => flag == 0x01;

  /// 是否具备 2.4G WiFi 能力（bit2=1 => 0x0004）
  bool get hasWifi24G => (commAbility & 0x0004) != 0;

  /// 将 [idBytes] 以 hex 字符串输出，便于调试/兜底展示
  String get idHex =>
      idBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');

  @override
  String toString() {
    final id = (idAsUtf8 ?? idHex);
    return 'ManufacturerDataInfo(flag: $flag, protocolVersion: $protocolVersion, encryptionMode: $encryptionMode, commAbility: $commAbility, idType: $idType, id: $id)';
  }
}

/// Service Data 解析结果
class ServiceDataInfo {
  final int type;
  final List<int> payload;
  final String? pid;

  ServiceDataInfo({required this.type, required this.payload, this.pid});

  @override
  String toString() {
    // 关键逻辑：只输出前 20 个字节，避免日志过长
    final hex = payload
        .take(20)
        .map((e) => e.toRadixString(16).padLeft(2, '0'))
        .join();
    final tail = payload.length > 20 ? '…' : '';
    return 'ServiceDataInfo(type: $type, pid: $pid, payloadLen: ${payload.length}, payloadHex: $hex$tail)';
  }
}
