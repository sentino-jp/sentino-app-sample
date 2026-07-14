import 'package:flutter/material.dart';
import '../models/auth_result.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../utils/api_client.dart';
import '../utils/toast_util.dart';

/// 用户认证状态管理 Provider
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthProvider({required AuthService authService})
      : _authService = authService;

  bool _isLoading = false;
  String? _errorMessage;
  AuthResult? _authResult;
  User? _userProfile;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AuthResult? get authResult => _authResult;
  User? get userProfile => _userProfile;

  /// 当前登录用户邮箱(解 JWT email claim);旧 IoT 认证页默认填充用。
  String? get currentEmail => _authService.currentEmail;
  bool get isLoggedIn => _authService.isLoggedIn;
  bool get isCoucouMode => _authService.isCoucouMode;

  /// 登录
  Future<bool> login(
      String uid, String password, String areaCode, String countryKey) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _authResult =
          await _authService.login(uid, password, areaCode, countryKey);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      final msg = _extractMessage(e);
      _errorMessage = msg;
      ToastUtil.showError(msg);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// coucou / dragonflow 统一账号登录
  Future<bool> loginCoucou(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.loginCoucou(email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      final msg = _extractMessage(e);
      _errorMessage = msg;
      ToastUtil.showError(msg);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 旧 IoT 认证：显式关联存量 cetus 账号（页面自管 loading/结果）。
  Future<Map<String, dynamic>> linkLegacyIot(String cetusEmail, String cetusPassword) {
    return _authService.linkLegacyIot(cetusEmail, cetusPassword);
  }

  /// 注册
  Future<bool> register(
      String uid, String password, String verifyCode, String areaCode, String countryKey) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.register(uid, password, verifyCode, areaCode, countryKey);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      final msg = _extractMessage(e);
      _errorMessage = msg;
      ToastUtil.showError(msg);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 发送注册验证码
  Future<({int intervalSeconds, int codeLength})?> sendRegisterCode(String input, String countryCode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _authService.sendRegisterCode(input, countryCode);
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      final msg = _extractMessage(e);
      _errorMessage = msg;
      ToastUtil.showError(msg);
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// 获取验证码发送间隔剩余时间
  Future<({int timeLeft, int codeLength})> getCodeInterval(String account) async {
    try {
      return await _authService.getCodeInterval(account);
    } catch (_) {
      return (timeLeft: 0, codeLength: 6);
    }
  }

  /// 检查验证码是否有效
  Future<bool> checkVerifyCode(String account, String verifyCode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final valid = await _authService.checkVerifyCode(account, verifyCode);
      _isLoading = false;
      notifyListeners();
      return valid;
    } catch (e) {
      final msg = _extractMessage(e);
      _errorMessage = msg;
      ToastUtil.showError(msg);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 发送忘记密码验证信息
  Future<bool> forgotPassword(String uid, String areaCode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.forgotPassword(uid, areaCode);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 重置密码
  Future<bool> resetPassword(
      String uid, String verifyCode, String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.resetPassword(uid, verifyCode, newPassword);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 修改密码
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.changePassword(oldPassword, newPassword);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 登出
  Future<void> logout() async {
    await _authService.logout();
    _authResult = null;
    _userProfile = null;
    notifyListeners();
  }

  /// 获取用户资料
  Future<void> loadUserProfile() async {
    try {
      _userProfile = await _authService.getUserProfile();
      notifyListeners();
    } catch (e) {
      debugPrint('loadUserProfile error: $e');
    }
  }

  /// 上传头像
  Future<bool> uploadAvatar(String filePath) async {
    _isLoading = true;
    notifyListeners();
    try {
      final url = await _authService.uploadAvatar(filePath);
      await _authService.updateUserInfo({'avatarUrl': url});
      await loadUserProfile();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 清除错误信息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// 修改昵称
  Future<bool> updateNickname(String nickname) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.updateUserInfo({'nickname': nickname});
      await loadUserProfile();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Extract user-friendly message from exception
  String _extractMessage(Object e) {
    if (e is ApiException) return e.message;
    return e.toString().replaceFirst('Exception: ', '');
  }
}
