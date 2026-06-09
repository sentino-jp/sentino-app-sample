import '../../models/auth_result.dart';
import '../../models/user.dart';
import '../auth_repository.dart';

/// Mock 用户认证 Repository，提供模拟数据用于开发和测试
class MockAuthRepository implements AuthRepository {
  // 模拟已注册用户
  final Map<String, String> _users = {
    'demo@demo.com': 'demo123',
  };

  String? _currentToken;

  @override
  Future<AuthResult> login(
      String uid, String password, String areaCode, String countryKey) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final stored = _users[uid];
    if (stored == null) {
      throw Exception('账号不存在');
    }
    if (stored != password) {
      throw Exception('密码错误');
    }
    _currentToken = 'mock_token_${DateTime.now().millisecondsSinceEpoch}';
    return AuthResult(accessToken: _currentToken!, uid: uid);
  }

  @override
  Future<void> register(
      String uid, String password, String verifyCode, String areaCode, String countryKey) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (_users.containsKey(uid)) {
      throw Exception('用户已存在');
    }
    _users[uid] = password;
  }

  @override
  Future<({int intervalSeconds, int codeLength})> sendRegisterCode(String input, String countryCode) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return (intervalSeconds: 60, codeLength: 6);
  }

  @override
  Future<({int timeLeft, int codeLength})> getCodeInterval(String account) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return (timeLeft: 0, codeLength: 6);
  }

  @override
  Future<bool> checkVerifyCode(String account, String verifyCode) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return verifyCode == '123456';
  }

  @override
  Future<void> forgotPassword(String uid, String areaCode) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!_users.containsKey(uid)) {
      throw Exception('账号不存在');
    }
  }

  @override
  Future<void> resetPassword(
      String uid, String verifyCode, String newPassword) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!_users.containsKey(uid)) {
      throw Exception('账号不存在');
    }
    _users[uid] = newPassword;
  }

  @override
  Future<void> changePassword(String oldPassword, String newPassword) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentToken = null;
  }

  @override
  Future<User> getUserProfile() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const User(uid: 'demo', nickname: 'Demo User', userName: 'demo');
  }

  @override
  Future<String> uploadAvatar(String filePath) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return 'https://example.com/avatar/mock.jpg';
  }

  @override
  Future<void> updateUserInfo(Map<String, dynamic> params) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
