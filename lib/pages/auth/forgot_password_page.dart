import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// 忘记密码页：Step1 输入邮箱 → Step2 输入验证码 → Step3 设置新密码
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

enum _ForgotStep { email, code, password }

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _uidController = TextEditingController();
  final _newPwdController = TextEditingController();
  final _confirmPwdController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  _ForgotStep _step = _ForgotStep.email;
  int _codeLength = 6;
  List<TextEditingController> _codeControllers = [];
  List<FocusNode> _codeFocusNodes = [];
  int _countdown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _uidController.dispose();
    _newPwdController.dispose();
    _confirmPwdController.dispose();
    for (final c in _codeControllers) { c.dispose(); }
    for (final f in _codeFocusNodes) { f.dispose(); }
    _timer?.cancel();
    super.dispose();
  }

  void _initCodeFields(int length) {
    for (final c in _codeControllers) { c.dispose(); }
    for (final f in _codeFocusNodes) { f.dispose(); }
    _codeLength = length;
    _codeControllers = List.generate(length, (_) => TextEditingController());
    _codeFocusNodes = List.generate(length, (_) => FocusNode());
  }

  String get _verifyCode => _codeControllers.map((c) => c.text).join();

  Future<void> _sendCode({bool isResend = false}) async {
    final auth = context.read<AuthProvider>();
    final email = _uidController.text.trim();

    if (isResend) {
      try {
        final result = await auth.getCodeInterval(email);
        if (result.codeLength > 0 && result.codeLength != _codeLength) {
          _initCodeFields(result.codeLength);
        }
        if (result.timeLeft > 0) {
          _startCountdown(result.timeLeft);
          return;
        }
      } catch (_) {}
    }

    final ok = await auth.forgotPassword(email, AppConfig.defaultAreaCode);
    if (ok && mounted) {
      if (_codeControllers.isEmpty) _initCodeFields(_codeLength);
      setState(() => _step = _ForgotStep.code);
      _startCountdown(60);
      if (_codeFocusNodes.isNotEmpty) _codeFocusNodes[0].requestFocus();
    }
  }

  void _startCountdown(int seconds) {
    _timer?.cancel();
    setState(() => _countdown = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown <= 1) {
        t.cancel();
        if (mounted) setState(() => _countdown = 0);
      } else {
        if (mounted) setState(() => _countdown--);
      }
    });
  }

  Future<void> _goToPasswordStep() async {
    if (_verifyCode.length != _codeLength) return;
    final auth = context.read<AuthProvider>();
    final email = _uidController.text.trim();
    final l = AppLocalizations.of(context)!;

    final valid = await auth.checkVerifyCode(email, _verifyCode);
    if (!valid) {
      if (mounted) ToastUtil.showError(l.invalidVerifyCode);
      return;
    }
    if (mounted) setState(() => _step = _ForgotStep.password);
  }

  Future<void> _resetPassword() async {
    final l = AppLocalizations.of(context)!;
    final auth = context.read<AuthProvider>();
    final ok = await auth.resetPassword(
        _uidController.text.trim(), _verifyCode, _newPwdController.text);
    if (ok && mounted) {
      ToastUtil.showSuccess(l.resetSuccess);
      context.go(AppRoutes.login);
    }
  }

  void _showNotReceivedHelp(AppLocalizations l) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
      appBar: AppBar(title: Text(l.notReceivedCodeTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.notReceivedCodeHint,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6)),
            const SizedBox(height: 8),
            SelectableText(AppConfig.supportEmail,
                style: const TextStyle(color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    )));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.forgotPassword)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: switch (_step) {
            _ForgotStep.email => _buildEmailStep(l),
            _ForgotStep.code => _buildCodeStep(l),
            _ForgotStep.password => _buildPasswordStep(l),
          },
        ),
      ),
    );
  }

  Widget _buildEmailStep(AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        AgTextField(
          controller: _uidController, hintText: l.enterAccount,
          prefixIcon: const Icon(Icons.person_outline),
          errorText: _uidController.text.isNotEmpty && !Validators.isValidUid(_uidController.text)
              ? l.invalidEmail : null,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        Consumer<AuthProvider>(builder: (context, auth, _) {
          if (auth.errorMessage != null) {
            return Padding(padding: const EdgeInsets.only(bottom: 8),
                child: Text(auth.errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 14)));
          }
          return const SizedBox.shrink();
        }),
        const SizedBox(height: 16),
        Consumer<AuthProvider>(builder: (context, auth, _) {
          return AgButton(text: l.getVerifyCode, isLoading: auth.isLoading,
              onPressed: Validators.isValidUid(_uidController.text) ? _sendCode : null);
        }),
      ],
    );
  }

  Widget _buildCodeStep(AppLocalizations l) {
    final email = _uidController.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Text(l.enterVerifyCode,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text(l.verifyCodeSent(email),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_codeLength, (i) {
            final boxWidth = (MediaQuery.of(context).size.width - 64 - (_codeLength - 1) * 8) / _codeLength;
            return SizedBox(
              width: boxWidth.clamp(32.0, 48.0), height: 52,
              child: TextField(
                controller: _codeControllers[i],
                focusNode: _codeFocusNodes[i],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                style: TextStyle(fontSize: boxWidth > 40 ? 22 : 18, fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[400]!)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (val) {
                  if (val.isNotEmpty && i < _codeLength - 1) _codeFocusNodes[i + 1].requestFocus();
                  if (val.isEmpty && i > 0) _codeFocusNodes[i - 1].requestFocus();
                  setState(() {});
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 24),
        _countdown > 0
            ? Text(l.resendCodeCountdown(_countdown), style: TextStyle(color: Colors.grey[500], fontSize: 14))
            : GestureDetector(onTap: () => _sendCode(isResend: true),
                child: Text(l.resendCode, style: const TextStyle(color: AppColors.primary, fontSize: 14))),
        const SizedBox(height: 8),
        GestureDetector(onTap: () => _showNotReceivedHelp(l),
            child: Text(l.notReceivedCode, style: const TextStyle(color: AppColors.primary, fontSize: 13))),
        const SizedBox(height: 8),
        Consumer<AuthProvider>(builder: (context, auth, _) {
          if (auth.errorMessage != null) {
            return Padding(padding: const EdgeInsets.only(bottom: 8),
                child: Text(auth.errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 14)));
          }
          return const SizedBox.shrink();
        }),
        const SizedBox(height: 16),
        AgButton(text: l.nextStep, onPressed: _verifyCode.length == _codeLength ? _goToPasswordStep : null),
      ],
    );
  }

  Widget _buildPasswordStep(AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        AgTextField(controller: _newPwdController, hintText: l.enterNewPassword,
            obscureText: _obscurePassword, prefixIcon: const Icon(Icons.lock_outline),
            errorText: _newPwdController.text.isNotEmpty && !Validators.isPasswordComplex(_newPwdController.text)
                ? l.passwordTooShort : null,
            suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword)),
            onChanged: (_) => setState(() {})),
        const SizedBox(height: 16),
        AgTextField(controller: _confirmPwdController, hintText: l.confirmNewPassword,
            obscureText: _obscureConfirm, prefixIcon: const Icon(Icons.lock_outline),
            errorText: _confirmPwdController.text.isNotEmpty && _newPwdController.text != _confirmPwdController.text
                ? l.passwordMismatch : null,
            suffixIcon: IconButton(icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm)),
            onChanged: (_) => setState(() {})),
        const SizedBox(height: 8),
        Consumer<AuthProvider>(builder: (context, auth, _) {
          if (auth.errorMessage != null) {
            return Padding(padding: const EdgeInsets.only(bottom: 8),
                child: Text(auth.errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 14)));
          }
          return const SizedBox.shrink();
        }),
        const SizedBox(height: 16),
        Consumer<AuthProvider>(builder: (context, auth, _) {
          return AgButton(text: l.resetPassword, isLoading: auth.isLoading,
              onPressed: Validators.isPasswordComplex(_newPwdController.text) &&
                      _newPwdController.text == _confirmPwdController.text
                  ? _resetPassword : null);
        }),
      ],
    );
  }
}
