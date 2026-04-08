/// AG Play 应用常量定义
class AppConstants {
  AppConstants._();

  // 应用信息
  static const String appName = 'AG Play';
  static const String packageName = 'com.cetusai.smart';

  // 存储 Key
  static const String keyAccessToken = 'access_token';
  static const String keyUserId = 'user_id';
  static const String keyThemeMode = 'theme_mode';
  static const String keyLocale = 'app_locale';

  // 配网相关
  static const int bindPollingIntervalSeconds = 10;
  static const int bindPollingTimeoutSeconds = 120;
  static const int bindCodeLength = 5;

  // 密码规则
  static const int passwordMinLength = 6;
}
