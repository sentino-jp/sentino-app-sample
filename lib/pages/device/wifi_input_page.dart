import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/ag_button.dart';
import '../../widgets/ag_text_field.dart';

/// WiFi info input page
class WifiInputPage extends StatefulWidget {
  const WifiInputPage({super.key});

  @override
  State<WifiInputPage> createState() => _WifiInputPageState();
}

class _WifiInputPageState extends State<WifiInputPage> {
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _ssidController.text.trim().isNotEmpty &&
      _passwordController.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.wifiConfig)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.enterWifiInfo,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 24),
              AgTextField(
                controller: _ssidController,
                hintText: l.wifiName,
                prefixIcon: const Icon(Icons.wifi),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              AgTextField(
                controller: _passwordController,
                hintText: l.wifiPassword,
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
              const Spacer(),
              AgButton(
                text: l.startPairing,
                onPressed: _canSubmit
                    ? () => context.pop<Map<String, String>>({
                          'ssid': _ssidController.text.trim(),
                          'password': _passwordController.text,
                        })
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
