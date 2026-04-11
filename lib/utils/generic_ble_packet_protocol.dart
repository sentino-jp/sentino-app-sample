import 'dart:typed_data';

/// 通用 BLE 配置常量
///
/// 说明：
/// - 这些参数属于“BLE 协议层/配网协议层”的约定值
/// - 从 [AppConfig] 挪到这里，避免把 BLE 协议细节混入 App 的全局网络配置中
class GenericBleProtocolConfig {
  /// BLE 厂商数据 Key
  static const int manufacturerKey = 0x0000;

  /// 下发 Wi-Fi/设备参数（BLE）
  static const String protocolNetworkSet = 'thing.network.set';

  /// 下发参数结果回包（BLE）
  static const String protocolNetworkSetResponse = 'thing.network.set.response';

  /// 获取设备扫描到的 Wi-Fi 列表（BLE）
  static const String protocolNetworkGetWifis = 'thing.network.getwifis';

  /// Wi-Fi 列表回包（BLE）
  static const String protocolNetworkGetWifisResponse =
      'thing.network.getwifis.response';
}

/// BLE 分包协议的单个数据包结构
///
/// 字段含义：
/// - [type]：包类型（业务自定义）
/// - [seq]：当前包序号（从 0 开始）
/// - [totalPackets]：总包数
/// - [totalLength]：原始数据总长度
/// - [dataLength]：本包数据长度
/// - [data]：本包承载的数据片段
class BlePacket {
  final int type;
  final int seq;
  final int totalPackets;
  final int totalLength;
  final int dataLength;
  final List<int> data;

  BlePacket({
    required this.type,
    required this.seq,
    required this.totalPackets,
    required this.totalLength,
    required this.dataLength,
    required this.data,
  });
}

/// BLE 分包协议（编码/解码）
///
/// 包格式（固定头 + 元信息 + 数据 + 校验）：
/// - Header(1)：0xFF
/// - Type(1)
/// - Seq(2) Big Endian
/// - TotalPackets(2) Big Endian
/// - TotalLength(2) Big Endian
/// - DataLength(1)
/// - Data(N)
/// - Checksum(1)：上述字段（除 Header、除自身）逐字节累加取低 8 位
class BleProtocol {
  static const int header = 0xFF;
  static const int maxPacketLength = 128;
  // FF(1) + 类型(1) + 序号(2) + 总包数(2) + 总长度(2) + 数据长度(1) + 校验(1) = 10
  static const int overhead = 10;
  static const int maxDataLength = maxPacketLength - overhead;

  /// 将数据编码为BLE数据包列表（字节数组）
  static List<List<int>> encode(List<int> data, {int type = 1}) {
    List<List<int>> packets = [];
    int totalLength = data.length;
    // 关键逻辑：向上取整得到总包数；空数据也至少输出 1 个包（仅头部信息）
    int totalPackets = (totalLength / maxDataLength).ceil();
    if (totalPackets == 0) totalPackets = 1;

    for (int i = 0; i < totalPackets; i++) {
      int start = i * maxDataLength;
      int end = (start + maxDataLength) > totalLength
          ? totalLength
          : (start + maxDataLength);
      List<int> chunk = data.sublist(start, end);

      int seq = i;
      int dataLength = chunk.length;

      // 校验和: 类型 + 序号 + 总包数 + 总长度 + 数据长度 + 数据
      int checksum = type;
      checksum += (seq >> 8) & 0xFF;
      checksum += seq & 0xFF;
      checksum += (totalPackets >> 8) & 0xFF;
      checksum += totalPackets & 0xFF;
      checksum += (totalLength >> 8) & 0xFF;
      checksum += totalLength & 0xFF;
      checksum += dataLength;
      for (int byte in chunk) {
        checksum += byte;
      }
      // 关键逻辑：仅保留低 8 位，保证结果在 0~255
      checksum = checksum & 0xFF;

      // 关键逻辑：按协议写入固定头、元信息、数据片段与校验
      ByteData writer = ByteData(overhead + dataLength);
      int offset = 0;
      writer.setUint8(offset++, header);
      writer.setUint8(offset++, type);
      writer.setUint16(offset, seq, Endian.big);
      offset += 2;
      writer.setUint16(offset, totalPackets, Endian.big);
      offset += 2;
      writer.setUint16(offset, totalLength, Endian.big);
      offset += 2;
      writer.setUint8(offset++, dataLength);

      for (int k = 0; k < chunk.length; k++) {
        writer.setUint8(offset++, chunk[k]);
      }

      writer.setUint8(offset++, checksum);

      packets.add(writer.buffer.asUint8List().toList());
    }
    return packets;
  }

  /// 将单个数据包字节解码为BlePacket结构
  static BlePacket? decode(List<int> bytes) {
    // 最小长度检查 (Header + Type + Seq + TP + TL + DL + Checksum) = 10
    if (bytes.length < 10) return null;

    ByteData reader = ByteData.sublistView(Uint8List.fromList(bytes));
    int offset = 0;

    int h = reader.getUint8(offset++);
    // 关键逻辑：不匹配协议头，直接视为非本协议数据
    if (h != header) return null;

    int type = reader.getUint8(offset++);
    int seq = reader.getUint16(offset, Endian.big);
    offset += 2;
    int totalPackets = reader.getUint16(offset, Endian.big);
    offset += 2;
    int totalLength = reader.getUint16(offset, Endian.big);
    offset += 2;
    int dataLength = reader.getUint8(offset++);

    // 验证长度
    if (bytes.length < offset + dataLength + 1) return null;

    List<int> data = bytes.sublist(offset, offset + dataLength);
    offset += dataLength;

    int receivedChecksum = reader.getUint8(offset);

    // 验证校验和
    int calcChecksum = type;
    calcChecksum += (seq >> 8) & 0xFF;
    calcChecksum += seq & 0xFF;
    calcChecksum += (totalPackets >> 8) & 0xFF;
    calcChecksum += totalPackets & 0xFF;
    calcChecksum += (totalLength >> 8) & 0xFF;
    calcChecksum += totalLength & 0xFF;
    calcChecksum += dataLength;
    for (int byte in data) {
      calcChecksum += byte;
    }
    calcChecksum = calcChecksum & 0xFF;

    // 关键逻辑：校验失败时返回 null，调用方可选择丢包或重传
    if (calcChecksum != receivedChecksum) {
      return null;
    }

    return BlePacket(
      type: type,
      seq: seq,
      totalPackets: totalPackets,
      totalLength: totalLength,
      dataLength: dataLength,
      data: data,
    );
  }
}
