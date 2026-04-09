import 'package:dio/dio.dart';
import '../../models/auth_result.dart';
import '../../models/user.dart';
import '../../utils/api_client.dart';
import '../auth_repository.dart';

/// Real API auth repository
class ApiAuthRepository implements AuthRepository {
  final ApiClient _api;

  ApiAuthRepository({required ApiClient api}) : _api = api;

  @override
  Future<AuthResult> login(
      String uid, String password, String areaCode, String countryKey) async {
    final resp = await _api.postForm('/auth/oauth/token', data: {
      'username': uid,
      'password': password,
      'areaCode': areaCode,
      'countryKey': countryKey,
      'grant_type': 'password',
    }, fromData: (d) {
      final map = d as Map<String, dynamic>;
      return AuthResult(
        accessToken: map['access_token'] ?? map['accessToken'] ?? '',
        uid: map['userId'] ?? map['memberId'] ?? map['uid'] ?? uid,
      );
    });
    return resp.data!;
  }

  @override
  Future<AuthResult> register(
      String uid, String password, String areaCode, String countryKey) async {
    final resp = await _api
        .post('business-app/v1/user/register/registryByUserName', data: {
      'userName': uid,
      'password': password,
      'areaCode': areaCode,
      'countryKey': countryKey,
    }, fromData: (d) {
      final map = d as Map<String, dynamic>;
      return AuthResult(
        accessToken: map['access_token'] ?? map['accessToken'] ?? '',
        uid: map['userId'] ?? map['memberId'] ?? map['uid'] ?? uid,
      );
    });
    return resp.data!;
  }

  @override
  Future<void> forgotPassword(String uid, String areaCode) async {
    // Determine type based on input: email or phone
    final passwordFindType = uid.contains('@') ? 'email_code' : 'sms_code';
    // V2 API uses QueryMap params
    await _api.post(
      'business-app/v2/user/password/find/sendFindPasswordCode',
      queryParameters: {
        'input': uid,
        'passwordFindType': passwordFindType,
      },
    );
  }

  @override
  Future<void> resetPassword(
      String uid, String verifyCode, String newPassword) async {
    final passwordFindType = uid.contains('@') ? 'email_code' : 'sms_code';
    await _api.post(
      'business-app/v1/user/password/find/resetPassword',
      data: {
        'input': uid,
        'password': newPassword,
        'passwordFindType': passwordFindType,
        'verifyCode': verifyCode,
      },
    );
  }

  @override
  Future<void> changePassword(String oldPassword, String newPassword) async {
    // changePassword in Android uses verification code flow, not old password
    // For simple password change with old password:
    await _api.post(
      'business-app/v1/user/password/update/updatePassword',
      data: {
        'password': newPassword,
        'passwordUpdateType': 'password',
        'oldPassword': oldPassword,
      },
    );
  }

  @override
  Future<void> logout() async {
    try {
      await _api.post('/auth/oauth/logout');
    } catch (_) {}
  }

  @override
  Future<User> getUserProfile() async {
    final resp = await _api.post('business-app/v1/user/profile',
        fromData: (d) => User.fromJson(d as Map<String, dynamic>));
    return resp.data!;
  }

  @override
  Future<String> uploadAvatar(String filePath) async {
    final file = await MultipartFile.fromFile(filePath, filename: 'avatar.jpg');
    final formData = FormData.fromMap({'file': file});
    final response = await _api.dio.post(
      'business-app/v1/file/uploadFile',
      data: formData,
    );
    final data = response.data as Map<String, dynamic>;
    final code = data['code'] as int? ?? -1;
    if (code != 200) {
      throw ApiException(
        bizCode: code,
        message: data['message']?.toString() ?? 'Failed to upload avatar',
      );
    }
    return data['data']?.toString() ?? '';
  }

  @override
  Future<void> updateUserInfo(Map<String, dynamic> params) async {
    await _api.post('business-app/v1/user/updateInfo', data: params);
  }
}
