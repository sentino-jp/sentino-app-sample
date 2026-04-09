import '../models/auth_result.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';
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

  /// 登录并持久化令牌
  Future<AuthResult> login(
      String uid, String password, String areaCode, String countryKey) async {
    final result =
        await _repository.login(uid, password, areaCode, countryKey);
    await _storage.saveAccessToken(result.accessToken);
    await _storage.saveUserId(result.uid);
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

  /// 注册并持久化令牌
  Future<AuthResult> register(
      String uid, String password, String areaCode, String countryKey) async {
    final result =
        await _repository.register(uid, password, areaCode, countryKey);
    await _storage.saveAccessToken(result.accessToken);
    await _storage.saveUserId(result.uid);
    return result;
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

  /// 获取用户资料
  Future<User> getUserProfile() => _repository.getUserProfile();

  /// 上传头像
  Future<String> uploadAvatar(String filePath) => _repository.uploadAvatar(filePath);

  /// 更新用户信息
  Future<void> updateUserInfo(Map<String, dynamic> params) =>
      _repository.updateUserInfo(params);
}
