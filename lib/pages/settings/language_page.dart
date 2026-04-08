import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../theme/app_colors.dart';

/// 语言设置页
class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.languageSettings)),
      body: Consumer<LocaleProvider>(
        builder: (context, provider, _) {
          return ListView(
            children: [
              // 跟随系统选项
              ListTile(
                title: Text(l10n.followSystem),
                trailing: provider.isFollowSystem
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () => provider.followSystem(),
              ),
              const Divider(),
              // 手动选择语言
              ...SupportedLocales.all.map((locale) {
                final isSelected = !provider.isFollowSystem &&
                    provider.locale?.languageCode == locale.languageCode;
                return ListTile(
                  title: Text(SupportedLocales.getDisplayName(locale)),
                  subtitle: Text(
                    SupportedLocales.languageCodes[locale.languageCode] ?? '',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () => provider.setLocale(locale),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
