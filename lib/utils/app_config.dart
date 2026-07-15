import 'package:flutter/foundation.dart' show kIsWeb, TargetPlatform, defaultTargetPlatform;

/// 应用配置
/// 固定参数在此配置，对接真实接口时修改对应值
class AppConfig {
  AppConfig._();

  /// 是否使用 Mock 数据（true=Mock, false=真实API）
  static bool get useMock => false;

  /// API 基础地址（cetus/sentino IoT 平台，主线已迁自托管 api-iot.sentino.jp）
  static const String baseUrl = 'https://api-iot.sentino.jp/api';

  /// coucou-server（dragonflow）基础地址：coucou 账号登录 + 旧 IoT 认证关联。
  /// stage=api-coucou-stage.sentino.jp；prod=api.coucou.fun（发版时切）。
  static const String coucouBaseUrl = 'https://api-coucou-stage.sentino.jp';

  /// 客户端标识符，格式: base64(clientId:clientSecret)
  static const String clientId =
      'Y2V0dXMtaW90LWFwcDpvbEFESkNtV2xGSVZYWTFxMWx4MHdVclViemU3WHdlUg==';

  ///包名
  static const String packageName = 'jp.sentino.general';

  /// 应用 ID
  static const String appId = 'krkfvb4s5e91hq';

  /// 技术支持邮箱
  static const String supportEmail = 'support@sentino.jp';

  /// 渠道标识符
  static const String channelIdentifier = 'kfvb4s5e';

  /// 数据中心编码
  static const String dataCenterCode = 'kr';

  /// 应用版本号
  static const String appVersion = '1.0.0-2604131800';

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
  static const String h5BaseUrl = 'https://h5-iot.sentino.jp';

  /// 智能体接口平台类型：'platform' 或 'sentino'
  /// platform → /business-app/v1/agents/...
  /// sentino → /business-app/v1/sentino-agents/...
  static const String agentPlatform = 'sentino';

  /// MQTT 服务器地址
  static const String mqttHost = 'mqtt-iot.sentino.jp';

  /// MQTT 端口
  static const int mqttPort = 1883;

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
