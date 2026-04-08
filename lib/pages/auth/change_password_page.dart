import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_router.dart';
import '../../theme/app_colors.dart';
import '../../utils/validators.dart';
import '../../widgets/ag_button.dart';
import '../../widgets/ag_text_field.dart';

/// 修改密码页
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _oldPwdController = TextEditingController();
  final _newPwdController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _oldPwdController.dispose();
    _newPwdController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      Validators.isValidPassword(_oldPwdController.text) &&
      Validators.isPasswordComplex(_newPwdController.text) &&
      _newPwdController.text == _confirmController.text;

  Future<void> _handleChange() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.changePassword(_oldPwdController.text, _newPwdController.text);
    if (ok && mounted) {
      await auth.logout();
      if (mounted) context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.changePassword)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              AgTextField(controller: _oldPwdController, hintText: l.enterOldPassword,
                  obscureText: _obscureOld, prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureOld ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureOld = !_obscureOld)),
                  onChanged: (_) => setState(() {})),
              const SizedBox(height: 16),
              AgTextField(controller: _newPwdController, hintText: l.enterNewPassword,
                  obscureText: _obscureNew, prefixIcon: const Icon(Icons.lock_outline),
                  errorText: _newPwdController.text.isNotEmpty &&
                          !Validators.isPasswordComplex(_newPwdController.text)
                      ? l.passwordTooShort : null,
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew)),
                  onChanged: (_) => setState(() {})),
              const SizedBox(height: 16),
              AgTextField(controller: _confirmController, hintText: l.confirmNewPassword,
                  obscureText: _obscureConfirm, prefixIcon: const Icon(Icons.lock_outline),
                  errorText: _confirmController.text.isNotEmpty &&
                          _newPwdController.text != _confirmController.text
                      ? l.passwordMismatch : null,
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm)),
                  onChanged: (_) => setState(() {})),
              const SizedBox(height: 8),
              Consumer<AuthProvider>(builder: (context, auth, _) {
                if (auth.errorMessage != null) {
                  return Padding(padding: const EdgeInsets.only(bottom: 8),
                      child: Text(auth.errorMessage!,
                          style: const TextStyle(color: AppColors.error, fontSize: 14)));
                }
                return const SizedBox.shrink();
              }),
              const SizedBox(height: 16),
              Consumer<AuthProvider>(builder: (context, auth, _) {
                return AgButton(text: l.confirmChange, isLoading: auth.isLoading,
                    onPressed: _canSubmit ? _handleChange : null);
              }),
            ],
          ),
        ),
      ),
    );
  }
}
