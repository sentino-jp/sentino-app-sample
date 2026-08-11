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
import '../../utils/toast_util.dart';
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
  // 登录模式：coucou（dragonflow 统一账号，默认）| cetus（旧 IoT 账号，原方案不变）
  String _loginMode = 'coucou';

  /// Google 登录在本平台是否可用。取决于运行平台，一次求值即可（build 期不会变）。
  late final bool _googleAvailable =
      context.read<AuthProvider>().isGoogleSignInAvailable;

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
    final ok = _loginMode == 'coucou'
        ? await auth.loginCoucou(_uidController.text.trim(), _passwordController.text)
        : await auth.login(_uidController.text.trim(), _passwordController.text,
            AppConfig.defaultAreaCode, AppConfig.defaultCountryKey);
    if (ok && mounted) context.go(AppRoutes.home);
  }

  /// Google 登录：系统级 SDK 直出 id_token → 后端验签建 coucou 会话。
  /// 与账密登录同样受隐私勾选门禁（合规要求一致，不因入口不同放宽）。
  ///
  /// 门禁不做成 `onPressed: null`：OutlinedButton 置灰在深色背景下几乎看不出，
  /// 表现为「按钮长得能点、点了没反应」，用户无从知道卡在隐私勾选上。
  /// 故按钮始终可点，未勾选时明确告知原因。
  Future<void> _handleGoogleLogin() async {
    if (!_agreePrivacy) {
      ToastUtil.showInfo(AppLocalizations.of(context)!.agreePrivacyRequired);
      return;
    }
    final auth = context.read<AuthProvider>();
    final ok = await auth.loginWithGoogle();
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
                          width: 120, height: 120, fit: BoxFit.contain),
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
              const SizedBox(height: 40),
              // CouCou 账号 = 主力登录（默认，直接表单）；旧 IoT 账号 = 次要入口（底部切换）。
              // cetus 模式下显示小标题提示当前处于旧 IoT 登录。
              if (_loginMode == 'cetus') ...[
                Center(
                  child: Text('旧 IoT 账号登录',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(color: AppColors.primary)),
                ),
                const SizedBox(height: 16),
              ],
              AgTextField(
                controller: _uidController,
                hintText: l.enterAccount,
                prefixIcon: const Icon(Icons.person_outline),
                errorText: _uidController.text.isNotEmpty && !Validators.isValidUid(_uidController.text)
                    ? l.invalidEmail : null,
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
              // Google 登录只在 coucou 模式给：它换回的是 dragonflow 会话，
              // 旧 IoT(cetus) 账号体系没有对应的三方登录端点。
              // 平台不支持时（web/desktop，或非 Android/iOS）隐藏而非置灰——点了也没面板可弹。
              if (_loginMode == 'coucou' && _googleAvailable) ...[
                const SizedBox(height: 12),
                Row(children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(l.orContinueWith,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey)),
                  ),
                  const Expanded(child: Divider()),
                ]),
                const SizedBox(height: 12),
                Consumer<AuthProvider>(builder: (context, auth, _) {
                  return SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      // 隐私勾选的门禁在 _handleGoogleLogin 里做（未勾选给提示而非静默禁用）。
                      // 这里只挡 loading，避免重复触发。
                      onPressed: auth.isLoading ? null : _handleGoogleLogin,
                      // 与 coucou-mobile 同款文字 G 标（Google 蓝），不引额外图片资源。
                      icon: const Text('G',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF4285F4))),
                      label: Text(l.continueWithGoogle,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            Theme.of(context).colorScheme.onSurface,
                        // 跟随主题而非写死 grey.shade400——后者在深色背景下偏灰、
                        // 与背景对比不足，按钮显得不像可点的控件。
                        side: BorderSide(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.45),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  );
                }),
              ],
              const SizedBox(height: 16),
              // 注册 / 忘记密码：两模式都显示。把当前登录模式透传给目标页（extra），
              // 决定其走 dragonflow 前置码流（coucou）还是 cetus 旧实现——注册/找回时用户未登录，
              // 不能靠 storage.isCoucouMode（缺省 cetus 会误判），故显式传 _loginMode。
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () =>
                        context.push(AppRoutes.forgotPassword, extra: _loginMode),
                    child: Text(l.forgotPassword),
                  ),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.register, extra: _loginMode),
                    child: Text(l.registerAccount),
                  ),
                ],
              ),
              // 旧 IoT 账号登录：次要入口（非主力）——存量 cetus 用户用；新用户走 CouCou 账号。
              Center(
                child: TextButton(
                  onPressed: () => setState(() =>
                      _loginMode = _loginMode == 'coucou' ? 'cetus' : 'coucou'),
                  child: Text(
                    _loginMode == 'coucou' ? '使用旧 IoT 账号登录' : '返回 CouCou 账号登录',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
