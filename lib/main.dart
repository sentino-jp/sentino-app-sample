import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'providers/agent_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/device_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/ota_provider.dart';
import 'providers/theme_provider.dart';
import 'repositories/agent_repository.dart';
import 'repositories/auth_repository.dart';
import 'repositories/device_repository.dart';
import 'repositories/ota_repository.dart';
import 'repositories/api/api_agent_repository.dart';
import 'repositories/api/api_auth_repository.dart';
import 'repositories/api/api_device_repository.dart';
import 'repositories/api/api_ota_repository.dart';
import 'repositories/mock/mock_agent_repository.dart';
import 'repositories/mock/mock_auth_repository.dart';
import 'repositories/mock/mock_device_repository.dart';
import 'repositories/mock/mock_ota_repository.dart';
import 'routes/app_router.dart';
import 'services/agent_service.dart';
import 'services/auth_service.dart';
import 'services/device_service.dart';
import 'services/ota_service.dart';
import 'utils/api_client.dart';
import 'utils/app_config.dart';
import 'utils/storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final storage = StorageUtil(prefs);
  final localeProvider = LocaleProvider(prefs);
  final appRouter = AppRouter(storage: storage);

  // 根据配置选择 Mock 或真实 API Repository
  late final AuthRepository authRepo;
  late final DeviceRepository deviceRepo;
  late final AgentRepository agentRepo;
  late final OtaRepository otaRepo;

  if (AppConfig.useMock) {
    authRepo = MockAuthRepository();
    deviceRepo = MockDeviceRepository();
    agentRepo = MockAgentRepository();
    otaRepo = MockOtaRepository();
  } else {
    final apiClient = ApiClient(
      baseUrl: AppConfig.baseUrl,
      storage: storage,
      language: localeProvider.language,
    );
    localeProvider.onLanguageChanged = apiClient.setLanguage;
    authRepo = ApiAuthRepository(api: apiClient);
    deviceRepo = ApiDeviceRepository(api: apiClient);
    agentRepo = ApiAgentRepository(api: apiClient);
    otaRepo = ApiOtaRepository(api: apiClient);
  }

  final authService = AuthService(repository: authRepo, storage: storage);
  final deviceService = DeviceService(repository: deviceRepo);
  final agentService = AgentService(repository: agentRepo);
  final otaService = OtaService(repository: otaRepo);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider(
            create: (_) => AuthProvider(authService: authService)),
        ChangeNotifierProvider(
            create: (_) => DeviceProvider(deviceService: deviceService)),
        ChangeNotifierProvider(
            create: (_) => AgentProvider(agentService: agentService)),
        ChangeNotifierProvider(
            create: (_) => OtaProvider(otaService: otaService)),
      ],
      child: AgPlayApp(appRouter: appRouter),
    ),
  );
}
