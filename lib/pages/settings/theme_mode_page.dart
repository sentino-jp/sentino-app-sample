import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_colors.dart';

/// 主题切换页：明亮/暗黑/跟随系统三选一
class ThemeModePage extends StatelessWidget {
  const ThemeModePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.themeSettings)),
      body: Consumer<ThemeProvider>(
        builder: (context, provider, _) {
          return ListView(
            children: [
              _themeOption(context, provider, AppThemeMode.light,
                  Icons.light_mode, l10n.lightMode),
              _themeOption(context, provider, AppThemeMode.dark,
                  Icons.dark_mode, l10n.darkMode),
              _themeOption(context, provider, AppThemeMode.system,
                  Icons.settings_brightness, l10n.followSystem),
            ],
          );
        },
      ),
    );
  }

  Widget _themeOption(BuildContext context, ThemeProvider provider,
      AppThemeMode mode, IconData icon, String title) {
    final isSelected = provider.themeMode == mode;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.primary : Colors.grey),
      title: Text(title),
      trailing:
          isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
      onTap: () => provider.setThemeMode(mode),
    );
  }
}
