import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../routes/app_router.dart';
import '../../theme/app_colors.dart';

/// 账号安全页：修改密码入口
class AccountSecurityPage extends StatelessWidget {
  const AccountSecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountSecurity)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.lock_outline, color: AppColors.primary),
            title: Text(l10n.changePassword),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () => context.push(AppRoutes.changePassword),
          ),
        ],
      ),
    );
  }
}
