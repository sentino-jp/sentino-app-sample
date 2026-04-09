import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../routes/app_router.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_config.dart';
import '../../utils/validators.dart';
import '../../widgets/ag_button.dart';
import '../../widgets/ag_text_field.dart';

/// 登录页
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _uidController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _agreePrivacy = false;

  @override
  void dispose() {
    _uidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      Validators.isValidUid(_uidController.text) &&
      Validators.isValidPassword(_passwordController.text) &&
      _agreePrivacy;

  Future<void> _handleLogin() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(
        _uidController.text.trim(), _passwordController.text, AppConfig.defaultAreaCode, AppConfig.defaultCountryKey);
    if (ok && mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(
          'v${AppConfig.appVersion}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Center(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Image.asset('assets/icon/logo.png',
                          width: 120, height: 105, fit: BoxFit.contain),
                    ),
                    const SizedBox(height: 12),
                    Text('SENTINO',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                            )),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              AgTextField(
                controller: _uidController,
                hintText: l.enterAccount,
                prefixIcon: const Icon(Icons.person_outline),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              AgTextField(
                controller: _passwordController,
                hintText: l.enterPassword,
                obscureText: _obscurePassword,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Row(children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _agreePrivacy,
                    onChanged: (v) =>
                        setState(() => _agreePrivacy = v ?? false),
                    activeColor: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodySmall,
                      children: [
                        TextSpan(
                          text: '${l.agreePrivacyPrefix} ',
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => setState(
                                () => _agreePrivacy = !_agreePrivacy),
                        ),
                        TextSpan(
                          text: l.userAgreement,
                          style: const TextStyle(color: AppColors.primary),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => context.push(AppRoutes.webview,
                                extra: {'title': l.userAgreement, 'url': AppConfig.userAgreementUrl(language: context.read<LocaleProvider>().language)}),
                        ),
                        TextSpan(
                          text: ' ${l.and} ',
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => setState(
                                () => _agreePrivacy = !_agreePrivacy),
                        ),
                        TextSpan(
                          text: l.privacyPolicy,
                          style: const TextStyle(color: AppColors.primary),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => context.push(AppRoutes.webview,
                                extra: {'title': l.privacyPolicy, 'url': AppConfig.privacyPolicyUrl(language: context.read<LocaleProvider>().language)}),
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              Consumer<AuthProvider>(builder: (context, auth, _) {
                if (auth.errorMessage != null) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(auth.errorMessage!,
                        style: const TextStyle(
                            color: AppColors.error, fontSize: 14)),
                  );
                }
                return const SizedBox.shrink();
              }),
              Consumer<AuthProvider>(builder: (context, auth, _) {
                return AgButton(
                  text: l.login,
                  isLoading: auth.isLoading,
                  onPressed: _canSubmit ? _handleLogin : null,
                );
              }),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => context.push(AppRoutes.forgotPassword),
                    child: Text(l.forgotPassword),
                  ),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.register),
                    child: Text(l.registerAccount),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
