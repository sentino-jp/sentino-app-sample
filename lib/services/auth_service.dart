import 'dart:convert';

import '../models/auth_result.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';
import '../repositories/api/coucou_api.dart';
import '../utils/storage.dart';

/// 用户认证业务逻辑层
class AuthService {
  final AuthRepository _repository;
  final StorageUtil _storage;

  AuthService({
    required AuthRepository repository,
    required StorageUtil storage,
  })  : _repository = repository,
        _storage = storage;

  /// coucou-server（dragonflow）客户端：coucou 账号登录 + 旧 IoT 认证关联。
  late final CoucouApi _coucouApi = CoucouApi(storage: _storage);

  /// 登录并持久化令牌
  Future<AuthResult> login(
      String uid, String password, String areaCode, String countryKey) async {
    final result =
        await _repository.login(uid, password, areaCode, countryKey);
    await _storage.saveAccessToken(result.accessToken);
    await _storage.saveUserId(result.uid);
    await _storage.saveLoginMode('cetus');
    // 如果 userId 看起来不像真正的 ID（可能是 userName），尝试从 profile 获取
    if (!result.uid.contains(RegExp(r'\d{10,}'))) {
      try {
        final profile = await _repository.getUserProfile();
        if (profile.uid != null && profile.uid!.isNotEmpty) {
          await _storage.saveUserId(profile.uid!);
        }
      } catch (_) {}
    }
    return result;
  }

  /// coucou / dragonflow 统一账号登录：拿 dragonflow JWT 存为 access_token，标记 loginMode=coucou。
  Future<void> loginCoucou(String email, String password) async {
    final token = await _coucouApi.login(email, password);
    await _storage.saveAccessToken(token);
    await _storage.saveLoginMode('coucou');
  }

  /// 旧 IoT 认证：用旧 cetus 账密显式关联存量账号（需已 coucou 登录持 JWT）。返回后端 body（linked / devices…）。
  Future<Map<String, dynamic>> linkLegacyIot(String cetusEmail, String cetusPassword) {
    return _coucouApi.linkLegacyIot(cetusEmail, cetusPassword);
  }

  /// 当前登录用户邮箱：解 dragonflow JWT 的 email claim。
  /// coucou 模式下最可靠——不依赖 cetus profile（后者在 coucou 态取不到）。无 token / 无 email → null。
  String? get currentEmail {
    final tok = _storage.getAccessToken();
    if (tok == null || tok.isEmpty) return null;
    try {
      final parts = tok.split('.');
      if (parts.length != 3) return null;
      var p = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      p = p.padRight(p.length + (4 - p.length % 4) % 4, '='); // base64url 补 padding
      final map = jsonDecode(utf8.decode(base64.decode(p))) as Map<String, dynamic>;
      final email = map['email'];
      return (email is String && email.isNotEmpty) ? email : null;
    } catch (_) {
      return null;
    }
  }

  /// 注册。cetus：注册后需手动登录。coucou：**前置码流**，带 code 注册即自动登录（存 token + loginMode=coucou）。
  Future<void> register(
      String uid, String password, String verifyCode, String areaCode, String countryKey,
      {bool coucou = false}) async {
    if (coucou) {
      final token = await _coucouApi.register(uid, password, verifyCode);
      await _storage.saveAccessToken(token);
      await _storage.saveLoginMode('coucou');
      return;
    }
    await _repository.register(uid, password, verifyCode, areaCode, countryKey);
  }

  /// 发送注册验证码（coucou 走 dragonflow /register/send-code）
  Future<({int intervalSeconds, int codeLength})> sendRegisterCode(String input, String countryCode,
      {bool coucou = false}) {
    if (coucou) return _coucouApi.sendRegisterCode(input);
    return _repository.sendRegisterCode(input, countryCode);
  }

  /// 获取验证码发送间隔剩余时间（秒）及验证码长度。
  /// coucou 无独立间隔查询端点：返回 timeLeft=0（放行重发，冷却由上游 429 兜底），码长固定 6。
  Future<({int timeLeft, int codeLength})> getCodeInterval(String account, {bool coucou = false}) {
    if (coucou) return Future.value((timeLeft: 0, codeLength: 6));
    return _repository.getCodeInterval(account);
  }

  /// 检查验证码是否有效（coucou 走 /register/verify-code 预校验，不消费）
  Future<bool> checkVerifyCode(String account, String verifyCode, {bool coucou = false}) {
    if (coucou) return _coucouApi.checkRegisterCode(account, verifyCode);
    return _repository.checkVerifyCode(account, verifyCode);
  }

  /// 发送忘记密码验证信息（coucou 走 /forgot-password 发码，恒 200）
  Future<void> forgotPassword(String uid, String areaCode, {bool coucou = false}) {
    if (coucou) return _coucouApi.forgotPassword(uid).then((_) {});
    return _repository.forgotPassword(uid, areaCode);
  }

  /// 检查找回密码验证码是否有效（coucou 走 /forgot-password/verify-code 预校验）
  Future<bool> checkForgotCode(String account, String verifyCode, {bool coucou = false}) {
    if (coucou) return _coucouApi.checkForgotCode(account, verifyCode);
    return _repository.checkVerifyCode(account, verifyCode);
  }

  /// 重置密码（coucou 走 /reset-password：email + code + new_password）
  Future<void> resetPassword(
      String uid, String verifyCode, String newPassword,
      {bool coucou = false}) {
    if (coucou) return _coucouApi.resetPassword(uid, verifyCode, newPassword);
    return _repository.resetPassword(uid, verifyCode, newPassword);
  }

  /// 修改密码
  Future<void> changePassword(String oldPassword, String newPassword) {
    return _repository.changePassword(oldPassword, newPassword);
  }

  /// 登出并清除令牌和用户 ID
  Future<void> logout() async {
    await _repository.logout();
    await _storage.removeAccessToken();
    await _storage.removeUserId();
  }

  /// 检查是否已登录
  bool get isLoggedIn => _storage.isLoggedIn;

  /// 当前是否 coucou 登录模式（决定是否展示旧 IoT 认证入口）。
  bool get isCoucouMode => _storage.isCoucouMode;

  /// 获取用户资料
  Future<User> getUserProfile() => _repository.getUserProfile();

  /// 上传头像
  Future<String> uploadAvatar(String filePath) => _repository.uploadAvatar(filePath);

  /// 更新用户信息
  Future<void> updateUserInfo(Map<String, dynamic> params) =>
      _repository.updateUserInfo(params);
}
