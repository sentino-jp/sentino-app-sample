import 'dart:typed_data';

class GenericBleProtocolConfig {
  static const int manufacturerId = 0x0000;
  static const String protocolNetworkSet = 'thing.network.set';
  static const String protocolNetworkSetResponse = 'thing.network.set.response';
  static const String protocolNetworkGetWifis = 'thing.network.getwifis';
  static const String protocolNetworkGetWifisResponse =
      'thing.network.getwifis.response';
}

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

class BleProtocol {
  static const int header = 0xFF;
  static const int maxPacketLength = 128;
  static const int overhead = 10;
  static const int maxDataLength = maxPacketLength - overhead;

  static List<List<int>> encode(List<int> data, {int type = 1}) {
    List<List<int>> packets = [];
    int totalLength = data.length;
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
      checksum = checksum & 0xFF;

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

  static BlePacket? decode(List<int> bytes) {
    if (bytes.length < 10) return null;

    ByteData reader = ByteData.sublistView(Uint8List.fromList(bytes));
    int offset = 0;

    int h = reader.getUint8(offset++);
    if (h != header) return null;

    int type = reader.getUint8(offset++);
    int seq = reader.getUint16(offset, Endian.big);
    offset += 2;
    int totalPackets = reader.getUint16(offset, Endian.big);
    offset += 2;
    int totalLength = reader.getUint16(offset, Endian.big);
    offset += 2;
    int dataLength = reader.getUint8(offset++);

    if (bytes.length < offset + dataLength + 1) return null;

    List<int> data = bytes.sublist(offset, offset + dataLength);
    offset += dataLength;

    int receivedChecksum = reader.getUint8(offset);

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
