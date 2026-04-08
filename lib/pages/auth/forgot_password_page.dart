import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_router.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_config.dart';
import '../../utils/toast_util.dart';
import '../../utils/validators.dart';
import '../../widgets/ag_button.dart';
import '../../widgets/ag_text_field.dart';

/// 忘记密码页
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _uidController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPwdController = TextEditingController();
  bool _codeSent = false;
  bool _obscurePassword = true;
  String? _successMessage;

  @override
  void dispose() {
    _uidController.dispose();
    _codeController.dispose();
    _newPwdController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.forgotPassword(_uidController.text.trim(), AppConfig.defaultAreaCode);
    if (ok && mounted) setState(() => _codeSent = true);
  }

  Future<void> _resetPassword() async {
    final l = AppLocalizations.of(context)!;
    final auth = context.read<AuthProvider>();
    final ok = await auth.resetPassword(
        _uidController.text.trim(), _codeController.text.trim(), _newPwdController.text);
    if (ok && mounted) {
      ToastUtil.showSuccess(l.resetSuccess);
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.forgotPassword)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              AgTextField(controller: _uidController, hintText: l.enterAccount,
                  prefixIcon: const Icon(Icons.person_outline),
                  onChanged: (_) => setState(() {})),
              if (_codeSent) ...[
                const SizedBox(height: 16),
                AgTextField(controller: _codeController, hintText: l.enterVerifyCode,
                    prefixIcon: const Icon(Icons.verified_outlined),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {})),
                const SizedBox(height: 16),
                AgTextField(controller: _newPwdController, hintText: l.enterNewPassword,
                    obscureText: _obscurePassword,
                    prefixIcon: const Icon(Icons.lock_outline),
                    errorText: _newPwdController.text.isNotEmpty &&
                            !Validators.isPasswordComplex(_newPwdController.text)
                        ? l.passwordTooShort : null,
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword)),
                    onChanged: (_) => setState(() {})),
              ],
              const SizedBox(height: 8),
              Consumer<AuthProvider>(builder: (context, auth, _) {
                if (auth.errorMessage != null) {
                  return Padding(padding: const EdgeInsets.only(bottom: 8),
                      child: Text(auth.errorMessage!,
                          style: const TextStyle(color: AppColors.error, fontSize: 14)));
                }
                return const SizedBox.shrink();
              }),
              if (_successMessage != null)
                Padding(padding: const EdgeInsets.only(bottom: 8),
                    child: Text(_successMessage!,
                        style: const TextStyle(color: AppColors.success, fontSize: 14))),
              const SizedBox(height: 16),
              Consumer<AuthProvider>(builder: (context, auth, _) {
                if (!_codeSent) {
                  return AgButton(text: l.getVerifyCode, isLoading: auth.isLoading,
                      onPressed: Validators.isValidUid(_uidController.text) ? _sendCode : null);
                }
                return AgButton(text: l.resetPassword, isLoading: auth.isLoading,
                    onPressed: _codeController.text.trim().isNotEmpty &&
                            Validators.isPasswordComplex(_newPwdController.text)
                        ? _resetPassword : null);
              }),
            ],
          ),
        ),
      ),
    );
  }
}
