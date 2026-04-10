import 'dart:typed_data';

/// RLink BLE 通信协议工具（严格对齐 Android RlinkPackDataUtil）
/// 帧格式: FF + cmdType(1B) + index(2B) + totalPacks(2B) + totalLength(2B) + dataLength(1B) + data(nB) + CRC(1B)
class RlinkProtocol {
  static int mtuSize = 128;
  static const int _typeSize = 1;
  static const int _indexSize = 2;
  static const int _allHexSize = 2;
  static const int _pakSize = 2;
  static const int _idexHexSize = 1;
  static const int _crcSize = 1;

  /// 单包有效数据字节数（对应 Android PN_PACK_LOOP_SIZE）
  static int get _payloadSize =>
      mtuSize - _indexSize - _allHexSize - _pakSize - _typeSize - _crcSize - _idexHexSize - _crcSize;

  /// 打包原始 JSON 字符串（对应 Android rnLinkDataPacking）
  /// 输入是原始字符串，内部先转 hex 再分包
  static List<Uint8List> pack(String json, {String cmdType = '01'}) {
    final hexData = _stringToHex(json);
    return _packHex(hexData, json.length, cmdType);
  }

  /// 打包已加密的 hex 字符串（对应 Android rnLinkDataPackingNew）
  /// 输入已经是 hex 字符串（如加密 API 返回的数据）
  static List<Uint8List> packHex(String hexData, {String cmdType = '01'}) {
    return _packHex(hexData, hexData.length ~/ 2, cmdType);
  }

  /// 内部打包逻辑
  /// hexData: hex 字符串形式的数据
  /// dataByteLen: 原始数据的字节长度（用于 totalLength 字段）
  static List<Uint8List> _packHex(String hexData, int dataByteLen, String cmdType) {
    // 每包 hex 字符数 = payloadSize * 2（因为 1 字节 = 2 hex 字符）
    final chunkHexLen = _payloadSize * 2;
    final chunks = _splitString(hexData, chunkHexLen);
    final totalPacks = chunks.length;
    final result = <Uint8List>[];

    for (var i = 0; i < chunks.length; i++) {
      final chunk = chunks[i];
      final index = _toHex(i, 4);
      final allIndex = _toHex(totalPacks, 4);
      // totalLength = 原始数据字节数（与 Android hexAllSize 一致）
      final allSize = _toHex(dataByteLen, 4);
      // dataLength = 当前包的字节数
      final dataLen = _toHex(chunk.length ~/ 2, 2);

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
