import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/device_provider.dart';
import '../../routes/app_router.dart';
import '../../theme/app_colors.dart';
import '../../utils/validators.dart';
import '../../widgets/ag_button.dart';
import '../../widgets/ag_text_field.dart';

enum PairingMode { verifyCode, barcode }

/// 验证码配网 / 条形码配网 页面
class FourgPairingPage extends StatefulWidget {
  final PairingMode initialMode;
  const FourgPairingPage({super.key, this.initialMode = PairingMode.verifyCode});
  @override
  State<FourgPairingPage> createState() => _FourgPairingPageState();
}

class _FourgPairingPageState extends State<FourgPairingPage> {
  final _codeController = TextEditingController();
  final _focusNode = FocusNode();
  late PairingMode _mode;
  bool _isLoading = false;
  bool? _bindSuccess;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }
  String? _errorMessage;

  @override
  void dispose() { _codeController.dispose(); _focusNode.dispose(); super.dispose(); }

  String? _codeErrorText(AppLocalizations l) {
    final code = _codeController.text;
    if (code.isEmpty) return null;
    if (_mode == PairingMode.verifyCode && !Validators.isValidBindCode(code)) return l.bindCodeError;
    if (_mode == PairingMode.barcode && code.trim().isEmpty) return l.enterBarcode;
    return null;
  }

  bool get _canSubmit {
    if (_isLoading) return false;
    if (_mode == PairingMode.verifyCode) return Validators.isValidBindCode(_codeController.text);
    return _codeController.text.trim().isNotEmpty;
  }

  Future<void> _handleBind() async {
    setState(() { _isLoading = true; _errorMessage = null; _bindSuccess = null; });
    try {
      final provider = context.read<DeviceProvider>();
      final assetId = provider.assets.isNotEmpty ? provider.assets.first.assetId : '';
      final code = _codeController.text.trim();
      if (_mode == PairingMode.verifyCode) {
        await provider.bindDeviceBy4gCode(assetId, code);
      } else {
        await provider.bindDeviceByBarcode(assetId, code);
      }
      if (!mounted) return;
      setState(() { _isLoading = false; _bindSuccess = true; });
      final assetIds = provider.assets.map((a) => a.assetId).toList();
      if (assetIds.isNotEmpty) await provider.loadDevices(assetIds);
    } catch (e) {
      if (!mounted) return;
      setState(() { _isLoading = false; _errorMessage = e.toString().replaceFirst('Exception: ', ''); });
    }
  }

  void _reset() { setState(() { _codeController.clear(); _bindSuccess = null; _errorMessage = null; }); }

  Future<void> _openScanner() async {
    final result = await context.push<String>(AppRoutes.barcodeScanner);
    if (result != null && result.isNotEmpty && mounted) setState(() => _codeController.text = result);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(_mode == PairingMode.verifyCode ? l.verifyCodePairing : l.barcodePairing)),
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: _bindSuccess == true ? _buildSuccess(l) : _buildForm(l))),
    );
  }

  Widget _buildForm(AppLocalizations l) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        ChoiceChip(
            label: Text(l.verifyCode,
                style: TextStyle(
                    color: _mode == PairingMode.verifyCode
                        ? Colors.white
                        : AppColors.primary)),
            selected: _mode == PairingMode.verifyCode,
            selectedColor: AppColors.primary,
            backgroundColor: Colors.grey[200],
            onSelected: (_) => setState(() {
                  _mode = PairingMode.verifyCode;
                  _codeController.clear();
                  _focusNode.requestFocus();
                })),
        const SizedBox(width: 8),
        ChoiceChip(
            label: Text(l.barcode,
                style: TextStyle(
                    color: _mode == PairingMode.barcode
                        ? Colors.white
                        : AppColors.primary)),
            selected: _mode == PairingMode.barcode,
            selectedColor: AppColors.primary,
            backgroundColor: Colors.grey[200],
            onSelected: (_) => setState(() {
                  _mode = PairingMode.barcode;
                  _codeController.clear();
                  _focusNode.requestFocus();
                })),
      ]),
      const SizedBox(height: 16),
      Text(_mode == PairingMode.verifyCode ? l.enterBindCode : l.enterBarcode,
          style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      Text(_mode == PairingMode.verifyCode ? l.bindCodeHint : l.barcodeHint,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
      const SizedBox(height: 24),
      AgTextField(controller: _codeController,
          focusNode: _focusNode,
          hintText: _mode == PairingMode.verifyCode ? l.enterFiveDigitCode : l.enterBarcode,
          prefixIcon: Icon(_mode == PairingMode.verifyCode ? Icons.pin : Icons.qr_code),
          keyboardType: _mode == PairingMode.verifyCode ? TextInputType.number : TextInputType.text,
          maxLength: _mode == PairingMode.verifyCode ? 5 : null,
          errorText: _codeErrorText(l),
          suffixIcon: _mode == PairingMode.barcode
              ? IconButton(icon: const Icon(Icons.camera_alt, color: AppColors.primary),
                  onPressed: _openScanner, tooltip: l.scanBarcode) : null,
          onChanged: (_) => setState(() {})),
      if (_errorMessage != null) ...[const SizedBox(height: 8),
        Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 14))],
      const Spacer(),
      AgButton(text: l.bindDevice, isLoading: _isLoading, onPressed: _canSubmit ? _handleBind : null),
    ]);
  }

  Widget _buildSuccess(AppLocalizations l) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.check_circle, size: 64, color: AppColors.success),
      const SizedBox(height: 16),
      Text(l.bindSuccess, style: const TextStyle(fontSize: 18)),
      const SizedBox(height: 24),
      AgButton(text: l.done, onPressed: () => context.pop()),
      const SizedBox(height: 12),
      TextButton(onPressed: _reset, child: Text(l.continueBind)),
    ]));
  }
}
