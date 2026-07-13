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

  /// 注册（注册成功后需要用户手动登录）
  Future<void> register(
      String uid, String password, String verifyCode, String areaCode, String countryKey) async {
    await _repository.register(uid, password, verifyCode, areaCode, countryKey);
  }

  /// 发送注册验证码
  Future<({int intervalSeconds, int codeLength})> sendRegisterCode(String input, String countryCode) {
    return _repository.sendRegisterCode(input, countryCode);
  }

  /// 获取验证码发送间隔剩余时间（秒）及验证码长度
  Future<({int timeLeft, int codeLength})> getCodeInterval(String account) {
    return _repository.getCodeInterval(account);
  }

  /// 检查验证码是否有效
  Future<bool> checkVerifyCode(String account, String verifyCode) {
    return _repository.checkVerifyCode(account, verifyCode);
  }

  /// 发送忘记密码验证信息
  Future<void> forgotPassword(String uid, String areaCode) {
    return _repository.forgotPassword(uid, areaCode);
  }

  /// 重置密码
  Future<void> resetPassword(
      String uid, String verifyCode, String newPassword) {
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
