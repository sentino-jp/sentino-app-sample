// 应用入口，通过 Skill Initializers 初始化各业务模块
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'repositories/api/coucou_api.dart';
import 'routes/app_router.dart';
import 'services/mqtt_service.dart';
import 'skills/initializers/agent_skill.dart';
import 'skills/initializers/auth_skill.dart';
import 'skills/initializers/device_skill.dart';
import 'skills/initializers/ota_skill.dart';
import 'skills/skill_config.dart';
import 'utils/api_client.dart';
import 'utils/app_config.dart';
import 'utils/storage.dart';
import 'utils/toast_util.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final prefs = await SharedPreferences.getInstance();
  final storage = StorageUtil(prefs);
  // 初始化设备指纹(从硬件标识派生,会话去重用)——须在 CoucouApi 创建前完成,使请求头能同步读到。
  await storage.initDeviceFingerprint();
  final localeProvider = LocaleProvider(prefs);
  final appRouter = AppRouter(storage: storage);

  // 构建 SkillConfig（Mock 或 API 模式）
  ApiClient? apiClient;
  if (!AppConfig.useMock) {
    apiClient = ApiClient(
      baseUrl: AppConfig.baseUrl,
      storage: storage,
      language: localeProvider.language,
    );
    // 11013 或 401 时强制登出并跳转登录页。
    // coucou 模式例外:flutter 持 dragonflow JWT、不依赖 cetus session,cetus(api-iot) 调用 401 属正常
    // (无 cetus token),绝不能因此把 coucou 用户登出——否则登录后被 cetus 401 立即踢回登录页。
    apiClient.onForceLogout = () {
      if (storage.isCoucouMode) return;
      final nav = ToastUtil.navigatorKey.currentContext;
      if (nav != null) {
        GoRouter.of(nav).go(AppRoutes.login);
      }
    };
    localeProvider.onLanguageChanged = apiClient.setLanguage;
  }

  // coucou-server 客户端(独立 dio,连 coucouBaseUrl,与 cetus ApiClient 分离);下沉给 Device/Agent Skill 用。
  final coucouApi = CoucouApi(storage: storage);
  final config = SkillConfig(
    baseUrl: AppConfig.baseUrl,
    storage: storage,
    language: localeProvider.language,
    useMock: AppConfig.useMock,
    apiClient: apiClient,
    coucouApi: coucouApi,
  );

  // 通过 Skill Initializers 初始化各业务模块
  final authBundle = AuthSkillInitializer.initialize(config);
  final deviceBundle = DeviceSkillInitializer.initialize(config);
  final agentBundle = AgentSkillInitializer.initialize(config);
  final otaBundle = OtaSkillInitializer.initialize(config);
  final mqttService = MqttService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider.value(value: authBundle.provider),
        ChangeNotifierProvider.value(value: deviceBundle.provider),
        ChangeNotifierProvider.value(value: agentBundle.provider),
        ChangeNotifierProvider.value(value: otaBundle.provider),
        Provider.value(value: mqttService),
        Provider<CoucouApi>.value(value: coucouApi),
      ],
      child: AgPlayApp(appRouter: appRouter),
    ),
  );
}
