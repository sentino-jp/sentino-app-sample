import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/storage.dart';
import '../pages/splash/splash_page.dart';
import '../pages/auth/login_page.dart';
import '../pages/auth/register_page.dart';
import '../pages/auth/forgot_password_page.dart';
import '../pages/auth/change_password_page.dart';
import '../pages/home/home_page.dart';
import '../pages/device/device_detail_page.dart';
import '../pages/device/device_panel_page.dart';
import '../pages/device/device_info_page.dart';
import '../pages/device/ble_pairing_page.dart';
import '../pages/device/fourg_pairing_page.dart';
import '../pages/device/wifi_input_page.dart';
import '../pages/device/barcode_scanner_page.dart';
import '../services/ble_service.dart';
import '../pages/common/webview_page.dart';
import '../pages/agent/agent_list_page.dart';
import '../pages/agent/agent_detail_page.dart';
import '../pages/agent/agent_create_page.dart';
import '../pages/agent/chat_history_page.dart';
import '../models/agent.dart';
import '../pages/ota/ota_upgrade_page.dart';
import '../pages/settings/settings_page.dart';
import '../pages/settings/account_security_page.dart';
import '../pages/settings/legacy_iot_link_page.dart';
import '../pages/settings/theme_mode_page.dart';
import '../pages/settings/about_page.dart';
import '../pages/settings/language_page.dart';

import '../utils/toast_util.dart';

/// 路由路径常量
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String changePassword = '/change-password';
  static const String home = '/home';
  static const String deviceDetail = '/device-detail/:deviceId';
  static const String devicePanel = '/device/:deviceId';
  static const String deviceInfo = '/device-info/:deviceId';
  static const String blePairing = '/ble-pairing';
  static const String fourgPairing = '/4g-pairing';
  static const String wifiInput = '/wifi-input';
  static const String agentList = '/agents';
  static const String agentDetail = '/agent/:agentId';
  static const String agentCreate = '/agent-create';
  static const String otaUpgrade = '/ota/:deviceId';
  static const String settings = '/settings';
  static const String accountSecurity = '/account-security';
  static const String legacyIotLink = '/legacy-iot-link';
  static const String themeMode = '/theme-mode';
  static const String language = '/language';
  static const String about = '/about';
  static const String barcodeScanner = '/barcode-scanner';
  static const String chatHistory = '/chat-history/:agentId';
  static const String webview = '/webview';
}

/// 应用路由配置
class AppRouter {
  final StorageUtil storage;

  AppRouter({required this.storage});

  /// 无需登录即可访问的路径
  static const _publicPaths = {
    AppRoutes.splash,
    AppRoutes.login,
    AppRoutes.register,
    AppRoutes.forgotPassword,
    AppRoutes.webview,
  };

  late final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    navigatorKey: ToastUtil.navigatorKey,
    debugLogDiagnostics: true,
    redirect: _guard,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        // extra = 登录模式（'coucou' | 'cetus'）；缺省 coucou（dragonflow 主账号）
        builder: (context, state) =>
            RegisterPage(mode: state.extra is String ? state.extra as String : 'coucou'),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) =>
            ForgotPasswordPage(mode: state.extra is String ? state.extra as String : 'coucou'),
      ),
      GoRoute(
        path: AppRoutes.changePassword,
        builder: (context, state) => const ChangePasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.devicePanel,
        builder: (context, state) =>
            DevicePanelPage(deviceId: state.pathParameters['deviceId']!),
      ),
      GoRoute(
        path: AppRoutes.deviceDetail,
        builder: (context, state) =>
            DeviceDetailPage(deviceId: state.pathParameters['deviceId']!),
      ),
      GoRoute(
        path: AppRoutes.deviceInfo,
        builder: (context, state) =>
            DeviceInfoPage(deviceId: state.pathParameters['deviceId']!),
      ),
      GoRoute(
        path: AppRoutes.blePairing,
        builder: (context, state) => const BlePairingPage(),
      ),
      GoRoute(
        path: AppRoutes.fourgPairing,
        builder: (context, state) {
          final mode = state.extra as PairingMode? ?? PairingMode.verifyCode;
          return FourgPairingPage(initialMode: mode);
        },
      ),
      GoRoute(
        path: AppRoutes.wifiInput,
        builder: (context, state) =>
            WifiInputPage(deviceInfo: state.extra as BleDeviceInfo?),
      ),
      GoRoute(
        path: AppRoutes.agentList,
        builder: (context, state) => const AgentListPage(),
      ),
      GoRoute(
        path: AppRoutes.agentDetail,
        builder: (context, state) => AgentDetailPage(
          agentId: state.pathParameters['agentId']!,
          agent: state.extra as Agent?,
        ),
      ),
      GoRoute(
        path: AppRoutes.agentCreate,
        builder: (context, state) =>
            AgentCreatePage(agent: state.extra as Agent?),
      ),
      GoRoute(
        path: AppRoutes.otaUpgrade,
        builder: (context, state) =>
            OtaUpgradePage(deviceId: state.pathParameters['deviceId']!),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.accountSecurity,
        builder: (context, state) => const AccountSecurityPage(),
      ),
      GoRoute(
        path: AppRoutes.legacyIotLink,
        builder: (context, state) => const LegacyIotLinkPage(),
      ),
      GoRoute(
        path: AppRoutes.themeMode,
        builder: (context, state) => const ThemeModePage(),
      ),
      GoRoute(
        path: AppRoutes.about,
        builder: (context, state) => const AboutPage(),
      ),
      GoRoute(
        path: AppRoutes.language,
        builder: (context, state) => const LanguagePage(),
      ),
      GoRoute(
        path: AppRoutes.barcodeScanner,
        builder: (context, state) => const BarcodeScannerPage(),
      ),
      GoRoute(
        path: AppRoutes.chatHistory,
        builder: (context, state) {
          final extra = state.extra as Map<String, String>? ?? {};
          return ChatHistoryPage(
            agentId: state.pathParameters['agentId']!,
            targetId: extra['targetId'] ?? '',
            targetType: extra['targetType'] ?? 'device',
            agentAvatarUrl: extra['agentAvatarUrl'],
          );
        },
      ),
      GoRoute(
        path: AppRoutes.webview,
        builder: (context, state) {
          final args = state.extra as Map<String, String>? ?? {};
          return WebViewPage(
            title: args['title'] ?? '',
            url: args['url'] ?? '',
          );
        },
      ),
    ],
  );

  /// 登录状态路由守卫
  String? _guard(BuildContext context, GoRouterState state) {
    final isLoggedIn = storage.isLoggedIn;
    final isPublic = _publicPaths.contains(state.matchedLocation);

    // 已登录用户访问 splash/login 时跳转到首页
    if (isLoggedIn &&
        (state.matchedLocation == AppRoutes.splash ||
            state.matchedLocation == AppRoutes.login)) {
      return AppRoutes.home;
    }

    // 未登录用户访问受保护页面时跳转到登录页
    if (!isLoggedIn && !isPublic) {
      return AppRoutes.login;
    }

    return null;
  }
}
