import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
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

  Future<bool> removeUserId() {
    return _prefs.remove(AppConstants.keyUserId);
  }

  // --- 登录模式（coucou | cetus）---

  Future<bool> saveLoginMode(String mode) {
    return _prefs.setString(AppConstants.keyLoginMode, mode);
  }

  /// 当前登录模式；缺省视为 cetus（旧方案，向后兼容既有登录态）。
  String getLoginMode() {
    return _prefs.getString(AppConstants.keyLoginMode) ?? 'cetus';
  }

  bool get isCoucouMode => getLoginMode() == 'coucou';

  // --- 语言（与 LocaleProvider 共用 'app_locale' pref；null=跟随系统）---

  /// 用户显式选择的语言标签（形如 `zh_CN`）；未显式选择（跟随系统）返回 null。
  /// 供 CoucouApi 解析 Accept-Language（邮件多语言），与 LocaleProvider.language 口径一致。
  String? getLocaleOverrideTag() => _prefs.getString('app_locale');

  // --- 设备指纹（会话去重）---

  /// 读已缓存的设备指纹(同步,供请求头即时取);未初始化返回空串。
  String getDeviceFingerprint() {
    return _prefs.getString(AppConstants.keyDeviceFingerprint) ?? '';
  }

  /// 初始化设备指纹(app 启动时异步调一次):优先从**硬件标识**派生(Android ID / iOS identifierForVendor),
  /// 让同一台设备始终同一指纹;拿不到硬件 id 才退回随机 UUID(持久化后复用)。
  /// dragonflow 按 device_fingerprint_hash 去重会话——指纹须设备相关、不能全设备一样。
  Future<String> initDeviceFingerprint() async {
    final cached = _prefs.getString(AppConstants.keyDeviceFingerprint);
    if (cached != null && cached.isNotEmpty) return cached;
    String? hardwareId;
    try {
      final info = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        hardwareId = (await info.androidInfo).id; // Android ID(设备+签名相关,稳定)
      } else if (Platform.isIOS) {
        hardwareId = (await info.iosInfo).identifierForVendor; // 同厂商 app 内稳定
      }
    } catch (_) {
      hardwareId = null;
    }
    final fp = (hardwareId != null && hardwareId.isNotEmpty)
        ? 'hw:$hardwareId'
        : 'rnd:${const Uuid().v4()}'; // 兜底:拿不到硬件 id 用随机(仍每台不同)
    await _prefs.setString(AppConstants.keyDeviceFingerprint, fp);
    return fp;
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
