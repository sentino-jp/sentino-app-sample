import '../models/auth_result.dart';
import '../models/user.dart';

/// 用户认证数据访问抽象接口
abstract class AuthRepository {
  Future<AuthResult> login(
      String uid, String password, String areaCode, String countryKey);

  Future<AuthResult> register(
      String uid, String password, String areaCode, String countryKey);

  Future<void> forgotPassword(String uid, String areaCode);

  Future<void> resetPassword(
      String uid, String verifyCode, String newPassword);

  Future<void> changePassword(String oldPassword, String newPassword);

  Future<void> logout();

  Future<User> getUserProfile();

  Future<String> uploadAvatar(String filePath);

  Future<void> updateUserInfo(Map<String, dynamic> params);
}
