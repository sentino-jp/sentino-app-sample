import 'constants.dart';

/// 输入验证工具类
class Validators {
  Validators._();

  /// 验证用户标识（账号）是否有效。
  /// 有效条件：非空且不全为空白字符。
  static bool isValidUid(String uid) {
    return uid.trim().isNotEmpty;
  }

  /// 验证密码是否有效。
  /// 有效条件：非空且不全为空白字符。
  static bool isValidPassword(String password) {
    return password.trim().isNotEmpty;
  }

  /// 验证密码是否符合复杂度规则。
  /// 规则：长度不小于 passwordMinLength（6）位，且不全为空白字符。
  static bool isPasswordComplex(String password) {
    if (password.trim().isEmpty) return false;
    return password.length >= AppConstants.passwordMinLength;
  }

  /// 验证 4G 绑定码格式。
  /// 规则：恰好 5 位纯数字。
  static bool isValidBindCode(String code) {
    if (code.length != AppConstants.bindCodeLength) return false;
    return RegExp(r'^\d{5}$').hasMatch(code);
  }
}
