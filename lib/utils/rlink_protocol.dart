import 'dart:typed_data';

/// RLink BLE 通信协议工具（与 Android RlinkPackDataUtil 对齐）
/// 帧格式: FF + cmdType(1B) + index(2B) + totalPacks(2B) + totalLength(2B) + dataLength(1B) + data(nB) + CRC(1B)
class RlinkProtocol {
  static int mtuSize = 128;
  static const int _typeSize = 1;
  static const int _indexSize = 2;
  static const int _allHexSize = 2;
  static const int _pakSize = 2;
  static const int _idexHexSize = 1;
  static const int _crcSize = 1;
  static const int _headerSize = 1; // FF

  /// 单包有效数据长度
  static int get _payloadSize =>
      mtuSize - _indexSize - _allHexSize - _pakSize - _typeSize - _crcSize - _idexHexSize - _crcSize;

  /// 将 JSON 字符串打包为 RLink 协议帧列表（每帧为 byte 数组）
  static List<Uint8List> pack(String json, {String cmdType = '01'}) {
    final hexData = _stringToHex(json);
    final chunks = _splitString(hexData, _payloadSize);
    final totalLength = hexData.length;
    final totalPacks = chunks.length;
    final result = <Uint8List>[];

    for (var i = 0; i < chunks.length; i++) {
      final chunk = chunks[i];
      final index = _toHex(i, 4);
      final allIndex = _toHex(totalPacks, 4);
      final allSize = _toHex(totalLength, 4);
      final dataLen = _toHex(chunk.length, 2);

      var frame = '$cmdType$index$allIndex$allSize$dataLen$chunk';
      final crc = _calcCrc(frame);
      frame = 'FF$frame$crc';

      result.add(_hexToBytes(frame));
    }
    return result;
  }

  static String _stringToHex(String s) {
    final sb = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      sb.write(s.codeUnitAt(i).toRadixString(16).padLeft(2, '0'));
    }
    return sb.toString();
  }

  static List<String> _splitString(String src, int length) {
    final result = <String>[];
    for (var i = 0; i < src.length; i += length) {
      final end = (i + length > src.length) ? src.length : i + length;
      result.add(src.substring(i, end));
    }
    return result;
  }

  static String _toHex(int value, int digits) =>
      value.toRadixString(16).padLeft(digits, '0').toUpperCase();

  static String _calcCrc(String hex) {
    var sum = 0;
    for (var i = 0; i < hex.length; i += 2) {
      sum += int.parse(hex.substring(i, i + 2), radix: 16);
    }
    return (sum & 0xFF).toRadixString(16).padLeft(2, '0').toUpperCase();
  }

  static Uint8List _hexToBytes(String hex) {
    hex = hex.toLowerCase();
    final bytes = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return bytes;
  }
}
