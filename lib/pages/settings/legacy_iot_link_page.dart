import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/toast_util.dart';
import '../../widgets/ag_button.dart';
import '../../widgets/ag_text_field.dart';

/// 旧 IoT 认证：coucou 登录态下，用旧 Sentino IoT 账密显式关联存量账号。
/// 后端 grant_type=password 桥到真实 cetus 账号（password 模式）→ 既有设备同步可见。
/// 设计见 coucou-iot-auth-federation-design.md（UID 默认 + 显式关联）。
class LegacyIotLinkPage extends StatefulWidget {
  const LegacyIotLinkPage({super.key});

  @override
  State<LegacyIotLinkPage> createState() => _LegacyIotLinkPageState();
}

class _LegacyIotLinkPageState extends State<LegacyIotLinkPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _emailController.text.trim().isNotEmpty &&
      _passwordController.text.isNotEmpty &&
      !_submitting;

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final res = await context
          .read<AuthProvider>()
          .linkLegacyIot(_emailController.text.trim(), _passwordController.text);
      if (!mounted) return;
      final devices = res['devices'];
      final count = devices is List ? devices.length : 0;
      ToastUtil.showSuccess('关联成功，已同步 $count 台设备');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) ToastUtil.showError(e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('旧 IoT 认证')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '关联你原有的 Sentino IoT 账号，把既有设备同步到当前 CouCou 账号。',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              AgTextField(
                controller: _emailController,
                hintText: '旧 IoT 账号（邮箱）',
                prefixIcon: const Icon(Icons.person_outline),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              AgTextField(
                controller: _passwordController,
                hintText: '旧 IoT 密码',
                obscureText: _obscure,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 24),
              AgButton(
                text: '关联',
                isLoading: _submitting,
                onPressed: _canSubmit ? _submit : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
