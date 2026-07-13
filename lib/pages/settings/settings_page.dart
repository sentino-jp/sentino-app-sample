import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_router.dart';
import '../../theme/app_colors.dart';

/// 设置页面：主题切换、语言设置、账号安全、关于应用
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          _menuItem(context, Icons.palette, l10n.themeSettings, () {
            context.push(AppRoutes.themeMode);
          }),
          _menuItem(context, Icons.language, l10n.languageSettings, () {
            context.push(AppRoutes.language);
          }),
          _menuItem(context, Icons.security, l10n.accountSecurity, () {
            context.push(AppRoutes.accountSecurity);
          }),
          if (context.read<AuthProvider>().isCoucouMode)
            _menuItem(context, Icons.link, '旧 IoT 认证', () {
              context.push(AppRoutes.legacyIotLink);
            }),
        ],
      ),
    );
  }

  Widget _menuItem(
      BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
