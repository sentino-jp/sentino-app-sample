import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_router.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_config.dart';
import '../../utils/validators.dart';
import '../../widgets/ag_button.dart';
import '../../widgets/ag_text_field.dart';

/// 注册页
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _uidController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _uidController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      Validators.isValidUid(_uidController.text) &&
      Validators.isPasswordComplex(_passwordController.text) &&
      _passwordController.text == _confirmController.text;

  String? _confirmError(AppLocalizations l) {
    if (_confirmController.text.isEmpty) return null;
    if (_passwordController.text != _confirmController.text) return l.passwordMismatch;
    return null;
  }

  String? _passwordError(AppLocalizations l) {
    final pwd = _passwordController.text;
    if (pwd.isEmpty) return null;
    if (!Validators.isPasswordComplex(pwd)) return l.passwordTooShort;
    return null;
  }

  Future<void> _handleRegister() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
        _uidController.text.trim(), _passwordController.text, AppConfig.defaultAreaCode, AppConfig.defaultCountryKey);
    if (ok && mounted) {
      // 注册成功，跳回登录页
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.register)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              AgTextField(
                controller: _uidController, hintText: l.enterAccount,
                prefixIcon: const Icon(Icons.person_outline),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              AgTextField(
                controller: _passwordController, hintText: l.enterPassword,
                obscureText: _obscurePassword,
                prefixIcon: const Icon(Icons.lock_outline),
                errorText: _passwordError(l),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              AgTextField(
                controller: _confirmController, hintText: l.confirmNewPassword,
                obscureText: _obscureConfirm,
                prefixIcon: const Icon(Icons.lock_outline),
                errorText: _confirmError(l),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Consumer<AuthProvider>(builder: (context, auth, _) {
                if (auth.errorMessage != null) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(auth.errorMessage!,
                        style: const TextStyle(color: AppColors.error, fontSize: 14)),
                  );
                }
                return const SizedBox.shrink();
              }),
              const SizedBox(height: 16),
              Consumer<AuthProvider>(builder: (context, auth, _) {
                return AgButton(text: l.register, isLoading: auth.isLoading,
                    onPressed: _canSubmit ? _handleRegister : null);
              }),
              const SizedBox(height: 16),
              Center(child: TextButton(
                onPressed: () => context.pop(), child: Text(l.haveAccount))),
            ],
          ),
        ),
      ),
    );
  }
}
