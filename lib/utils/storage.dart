import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

/// 本地存储工具类，封装 shared_preferences 操作
class StorageUtil {
  final SharedPreferences _prefs;

  StorageUtil(this._prefs);

  // --- 访问令牌 ---

  Future<bool> saveAccessToken(String token) {
    return _prefs.setString(AppConstants.keyAccessToken, token);
  }

  String? getAccessToken() {
    return _prefs.getString(AppConstants.keyAccessToken);
  }

  Future<bool> removeAccessToken() {
    return _prefs.remove(AppConstants.keyAccessToken);
  }

  // --- 用户 ID ---

  Future<bool> saveUserId(String uid) {
    return _prefs.setString(AppConstants.keyUserId, uid);
  }

  String? getUserId() {
    return _prefs.getString(AppConstants.keyUserId);
  }

  // --- 主题模式 ---

  Future<bool> saveThemeMode(String mode) {
    return _prefs.setString(AppConstants.keyThemeMode, mode);
  }

  String? getThemeMode() {
    return _prefs.getString(AppConstants.keyThemeMode);
  }

  // --- 通用 ---

  Future<bool> clear() {
    return _prefs.clear();
  }

  bool get isLoggedIn => getAccessToken() != null;
}
