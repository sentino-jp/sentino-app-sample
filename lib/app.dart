import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'routes/app_router.dart';
import 'utils/toast_util.dart';

/// AG Play 应用根组件
class AgPlayApp extends StatelessWidget {
  final AppRouter appRouter;

  const AgPlayApp({super.key, required this.appRouter});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();

    return MaterialApp.router(
      title: 'Sentino',
      scaffoldMessengerKey: ToastUtil.messengerKey,
      theme: themeProvider.lightTheme,
      darkTheme: themeProvider.darkTheme,
      themeMode: themeProvider.materialThemeMode,
      locale: localeProvider.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: appRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
