import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// MQTT 日志记录工具，数据存储在 SharedPreferences，最多保留 1 天
class AppMqttLogger {
  static const String _key = 'mqtt_logs';
  static const int _maxAge = 24 * 60 * 60 * 1000; // 1 天（毫秒）

  static Future<void> log(String type, String message) async {
    final prefs = await SharedPreferences.getInstance();
    final logs = _getLogs(prefs);
    logs.add({
      'ts': DateTime.now().millisecondsSinceEpoch,
      'type': type,
      'msg': message,
    });
    // 清理超过 1 天的日志
    final cutoff = DateTime.now().millisecondsSinceEpoch - _maxAge;
    logs.removeWhere((l) => (l['ts'] as int? ?? 0) < cutoff);
    await prefs.setString(_key, jsonEncode(logs));
  }

  static Future<List<Map<String, dynamic>>> getLogs() async {
    final prefs = await SharedPreferences.getInstance();
    return _getLogs(prefs);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static List<Map<String, dynamic>> _getLogs(SharedPreferences prefs) {
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  static Future<String> getSizeString() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key) ?? '';
    final bytes = raw.length;
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)}M';
  }
}
