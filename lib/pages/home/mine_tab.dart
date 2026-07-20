import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../routes/app_router.dart';
import '../../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/app_config.dart';
import '../../utils/mqtt_logger.dart';
import '../../utils/toast_util.dart';

/// 我的 Tab：用户头像、账号信息、设置入�?
class MineTab extends StatefulWidget {
  const MineTab({super.key});

  @override
  State<MineTab> createState() => _MineTabState();
}

class _MineTabState extends State<MineTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().loadUserProfile();
    });
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512);
    if (image == null || !mounted) return;
    await context.read<AuthProvider>().uploadAvatar(image.path);
  }

  Future<void> _editNickname(String currentName) async {
    final l = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.editNickname),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: l.enterNickname),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l.confirm),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newName == null || newName.isEmpty || !mounted) return;
    final auth = context.read<AuthProvider>();
    try {
      await auth.updateNickname(newName);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final user = auth.userProfile;
        // coucou 模式不支持昵称/头像编辑（走 dragonflow 账号，无 cetus profile 写入链路）→ 隐藏编辑入口。
        final canEdit = !auth.isCoucouMode;
        return SingleChildScrollView(
          child: Column(
            children: [
              // 用户信息头部
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryToBlackGradient,
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: canEdit ? _pickAvatar : null,
                      child: Stack(
                        children: [
                          user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                              ? CircleAvatar(
                                  radius: 40,
                                  backgroundImage: NetworkImage(user.avatarUrl!),
                                )
                              : const CircleAvatar(
                                  radius: 40,
                                  backgroundColor: Colors.white,
                                  child: Icon(Icons.person, size: 48, color: AppColors.primary),
                                ),
                          if (canEdit)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt, size: 16, color: AppColors.primary),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    canEdit
                        ? GestureDetector(
                            onTap: () => _editNickname(
                                user?.nickname ?? user?.displayName ?? ''),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  user?.displayName ?? '',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(color: Colors.white),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.edit, size: 14, color: Colors.white70),
                              ],
                            ),
                          )
                        : Text(
                            user?.displayName ?? '',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: Colors.white),
                          ),
                    if (user?.email != null || user?.phoneNumber != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          user?.email ?? user?.phoneNumber ?? '',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.white70),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _menuItem(context, Icons.settings, AppLocalizations.of(context)!.settings, () {
                context.push(AppRoutes.settings);
              }),
              _menuItem(context, Icons.info_outline, AppLocalizations.of(context)!.about, () {
                context.push(AppRoutes.about);
              }),
              _menuItem(context, Icons.privacy_tip_outlined, AppLocalizations.of(context)!.privacyPolicy, () {
                context.push(AppRoutes.webview, extra: {
                  'title': AppLocalizations.of(context)!.privacyPolicy,
                  'url': AppConfig.privacyPolicyUrl(language: context.read<LocaleProvider>().language),
                });
              }),
              _menuItem(context, Icons.description_outlined, AppLocalizations.of(context)!.userAgreement, () {
                context.push(AppRoutes.webview, extra: {
                  'title': AppLocalizations.of(context)!.userAgreement,
                  'url': AppConfig.userAgreementUrl(language: context.read<LocaleProvider>().language),
                });
              }),
              _buildCacheItem(context),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await context.read<AuthProvider>().logout();
                      if (context.mounted) {
                        context.go(AppRoutes.login);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(AppLocalizations.of(context)!.logout),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCacheItem(BuildContext context) {
    return FutureBuilder<String>(
      future: AppMqttLogger.getSizeString(),
      builder: (context, snapshot) {
        final size = snapshot.data ?? '0B';
        return ListTile(
          leading: const Icon(Icons.cleaning_services_outlined, color: AppColors.primary),
          title: Text(AppLocalizations.of(context)!.clearCache),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(size, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ]),
          onTap: () async {
            final l = AppLocalizations.of(context)!;
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(l.clearCache),
                content: Text(l.clearCacheConfirm),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
                  TextButton(onPressed: () => Navigator.pop(ctx, true),
                      child: Text(l.confirm, style: const TextStyle(color: AppColors.error))),
                ],
              ),
            ) ?? false;
            if (ok) {
              await AppMqttLogger.clear();
              if (context.mounted) {
                ToastUtil.showSuccess(l.clearCacheSuccess);
                setState(() {});
              }
            }
          },
        );
      },
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
