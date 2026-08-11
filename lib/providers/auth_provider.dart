import 'package:flutter/material.dart';
import '../models/auth_result.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/native_oauth_client.dart';
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

  /// Google 原生登录（落 coucou / dragonflow 登录态，与 [loginCoucou] 等价）。
  ///
  /// 用户在系统面板上取消**不算失败**：返回 false 但不置错误、不弹 toast，
  /// 否则每次误触取消都会甩一条红字，体验上像是出了故障。
  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.loginWithGoogle();
      _isLoading = false;
      notifyListeners();
      return true;
    } on NativeOAuthCancelled {
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      final msg = _extractMessage(e);
      _errorMessage = msg;
      ToastUtil.showError(msg);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Google 登录在当前平台是否可用（登录页据此决定显不显示按钮）。
  bool get isGoogleSignInAvailable => _authService.isGoogleSignInAvailable;

  /// 旧 IoT 认证：显式关联存量 cetus 账号（页面自管 loading/结果）。
  Future<Map<String, dynamic>> linkLegacyIot(String cetusEmail, String cetusPassword) {
    return _authService.linkLegacyIot(cetusEmail, cetusPassword);
  }

  /// 注册
  Future<bool> register(
      String uid, String password, String verifyCode, String areaCode, String countryKey,
      {bool coucou = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.register(uid, password, verifyCode, areaCode, countryKey, coucou: coucou);
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
  Future<({int intervalSeconds, int codeLength})?> sendRegisterCode(String input, String countryCode,
      {bool coucou = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _authService.sendRegisterCode(input, countryCode, coucou: coucou);
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
  Future<({int timeLeft, int codeLength})> getCodeInterval(String account, {bool coucou = false}) async {
    try {
      return await _authService.getCodeInterval(account, coucou: coucou);
    } catch (_) {
      return (timeLeft: 0, codeLength: 6);
    }
  }

  /// 检查注册验证码是否有效
  Future<bool> checkVerifyCode(String account, String verifyCode, {bool coucou = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final valid = await _authService.checkVerifyCode(account, verifyCode, coucou: coucou);
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

  /// 检查找回密码验证码是否有效（coucou 走独立 scene=reset 预校验）
  Future<bool> checkForgotCode(String account, String verifyCode, {bool coucou = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final valid = await _authService.checkForgotCode(account, verifyCode, coucou: coucou);
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
  Future<bool> forgotPassword(String uid, String areaCode, {bool coucou = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.forgotPassword(uid, areaCode, coucou: coucou);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _extractMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 重置密码
  Future<bool> resetPassword(
      String uid, String verifyCode, String newPassword,
      {bool coucou = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.resetPassword(uid, verifyCode, newPassword, coucou: coucou);
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
    // 原生登录的两类 SDK 异常 toString() 是给日志看的英文调试串，不能直接甩给用户。
    if (e is NativeOAuthUnsupported) return '当前设备不支持 Google 登录，请改用账号密码登录';
    if (e is NativeOAuthFailure) return 'Google 登录失败，请重试';
    return e.toString().replaceFirst('Exception: ', '');
  }
}
