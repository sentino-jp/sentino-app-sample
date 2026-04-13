import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_config.dart';
import '../../utils/toast_util.dart';
import '../../utils/validators.dart';
import '../../widgets/ag_button.dart';
import '../../widgets/ag_text_field.dart';

/// 注册页：Step1 输入邮箱+密码 → Step2 输入验证码
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

  bool _codeSent = false;
  int _codeLength = 6;
  List<TextEditingController> _codeControllers = [];
  List<FocusNode> _codeFocusNodes = [];
  int _countdown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _uidController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
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

  bool get _canNext =>
      Validators.isValidUid(_uidController.text) &&
      Validators.isPasswordComplex(_passwordController.text) &&
      _passwordController.text == _confirmController.text;

  String get _verifyCode => _codeControllers.map((c) => c.text).join();

  bool get _canRegister => _verifyCode.length == _codeLength;

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

  Future<void> _sendCode({bool isResend = false}) async {
    final auth = context.read<AuthProvider>();
    final email = _uidController.text.trim();

    // 重发时先查询剩余间隔
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
      } catch (_) {
        // 查询失败不阻塞重发
      }
    }

    final result = await auth.sendRegisterCode(email, AppConfig.defaultAreaCode);
    if (result != null && mounted) {
      _initCodeFields(result.codeLength);
      setState(() => _codeSent = true);
      _startCountdown(result.intervalSeconds);
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

  Future<void> _handleRegister() async {
    final auth = context.read<AuthProvider>();
    final email = _uidController.text.trim();
    final l = AppLocalizations.of(context)!;

    // 先校验验证码
    final valid = await auth.checkVerifyCode(email, _verifyCode);
    if (!valid) {
      if (mounted) {
        setState(() {});
        ToastUtil.showError(l.invalidVerifyCode);
      }
      return;
    }

    final ok = await auth.register(
      email,
      _passwordController.text,
      _verifyCode,
      AppConfig.defaultAreaCode,
      AppConfig.defaultCountryKey,
    );
    if (ok && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.register)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: _codeSent ? _buildStep2(l) : _buildStep1(l),
        ),
      ),
    );
  }

  Widget _buildStep1(AppLocalizations l) {
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
          return AgButton(text: l.nextStep, isLoading: auth.isLoading,
              onPressed: _canNext ? _sendCode : null);
        }),
        const SizedBox(height: 16),
        Center(child: TextButton(
          onPressed: () => context.pop(), child: Text(l.haveAccount))),
      ],
    );
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

  Widget _buildStep2(AppLocalizations l) {
    final email = _uidController.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Text(l.enterVerifyCode,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text(l.verifyCodeSent(email),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600])),
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
                style: TextStyle(
                  fontSize: boxWidth > 40 ? 22 : 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[400]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (val) {
                  if (val.isNotEmpty && i < _codeLength - 1) {
                    _codeFocusNodes[i + 1].requestFocus();
                  }
                  if (val.isEmpty && i > 0) {
                    _codeFocusNodes[i - 1].requestFocus();
                  }
                  setState(() {});
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 24),
        _countdown > 0
            ? Text(l.resendCodeCountdown(_countdown),
                style: TextStyle(color: Colors.grey[500], fontSize: 14))
            : GestureDetector(
                onTap: () => _sendCode(isResend: true),
                child: Text(l.resendCode,
                    style: const TextStyle(color: AppColors.primary, fontSize: 14)),
              ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showNotReceivedHelp(l),
          child: Text(l.notReceivedCode,
              style: const TextStyle(color: AppColors.primary, fontSize: 13)),
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
              onPressed: _canRegister ? _handleRegister : null);
        }),
      ],
    );
  }
}
