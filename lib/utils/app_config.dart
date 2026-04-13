import 'package:flutter/foundation.dart' show kIsWeb, TargetPlatform, defaultTargetPlatform;

/// 应用配置
/// 固定参数在此配置，对接真实接口时修改对应值
class AppConfig {
  AppConfig._();

  /// 是否使用 Mock 数据（true=Mock, false=真实API）
  static bool get useMock => false;

  /// API 基础地址
  static const String baseUrl = 'https://api.cetus-ai.com/api';

  /// 客户端标识符，格式: base64(clientId:clientSecret)
  static const String clientId =
      'Y2V0dXMtaW90LWFwcDpvbEFESkNtV2xGSVZYWTFxMWx4MHdVclViemU3WHdlUg==';

  /// 应用 ID
  static const String appId = 'cnsgdnmp2xhgf8';

  /// 渠道标识符
  static const String channelIdentifier = 'sgdnmp2x';

  /// 数据中心编码
  static const String dataCenterCode = 'cn';

  /// 应用版本号
  static const String appVersion = '1.0.0-2604131124';

  /// 默认语言
  static const String defaultLanguage = 'en_US';

  /// 系统类型
  static String get osName {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'other';
    }
  }

  /// 包名
  static const String packageName = 'com.cetusai.smart';

  /// 客户端申请的权限范围
  static const String scope = 'all';

  /// 加密方式
  static const String encryptType = 'AES/ECB/PKCS5Padding';

  /// 默认国际区号
  static const String defaultAreaCode = '86';

  /// 默认国家代码
  static const String defaultCountryKey = 'CN';

  /// 问题反馈 URL（H5）
  static const String feedbackUrl = '';

  /// FAQ URL
  static const String faqUrl = '';

  /// H5 域名
  static const String h5BaseUrl = 'https://h5.cetus-ai.com';

  /// 智能体接口平台类型：'platform' 或 'sentino'
  /// platform → /business-app/v1/agents/...
  /// sentino → /business-app/v1/sentino-agents/...
  static const String agentPlatform = 'sentino';

  /// MQTT 服务器地址
  static const String mqttHost = 'mqtt.cetus-ai.com';

  /// MQTT 端口
  static const int mqttPort = 2883;

  /// 构建协议页完整 URL（拼接 appId、language、apiPath）
  static String _buildAgreementUrl(String path, String language) {
    final apiPath = Uri.encodeComponent(baseUrl);
    return '$h5BaseUrl/agreement/$path?appId=$appId&language=$language&apiPath=$apiPath';
  }

  /// 隐私政策 URL
  static String privacyPolicyUrl({String language = 'zh_CN'}) =>
      _buildAgreementUrl('private-policy', language);

  /// 用户协议 URL
  static String userAgreementUrl({String language = 'zh_CN'}) =>
      _buildAgreementUrl('user-agreement', language);
}
