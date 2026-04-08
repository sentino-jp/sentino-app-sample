import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';

/// 条形码扫描页：摄像头扫描 + 相册选图 + 手电筒 + 底部手动输入
class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  final _inputController = TextEditingController();
  bool _hasScanned = false;
  bool _showInput = false;

  @override
  void dispose() {
    _controller.dispose();
    _inputController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final code = barcodes.first.rawValue;
    if (code != null && code.isNotEmpty) {
      _hasScanned = true;
      context.pop(code);
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null || !mounted) return;

    final result = await _controller.analyzeImage(image.path);
    if (result != null && result.barcodes.isNotEmpty && mounted) {
      final code = result.barcodes.first.rawValue;
      if (code != null && code.isNotEmpty) {
        _hasScanned = true;
        context.pop(code);
      }
    }
  }

  void _submitManualInput() {
    final code = _inputController.text.trim();
    if (code.isNotEmpty) {
      context.pop(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(l.scanBarcode),
      ),
      body: Column(
        children: [
          // 摄像头扫描区域
          Expanded(
            child: Stack(
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: _onDetect,
                ),
                // 扫描框
                Center(
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: AppColors.primary, width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      children: [
                        // 四角装饰
                        ..._buildCorners(),
                      ],
                    ),
                  ),
                ),
                // 提示文字
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: Text(
                    l.putBarcodeInFrame,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          // 底部操作栏：手电筒 + 相册 + 手动输入
          Container(
            color: Colors.black,
            padding: const EdgeInsets.symmetric(
                horizontal: 24, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 功能按钮行
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _actionButton(
                      icon: ValueListenableBuilder(
                        valueListenable: _controller,
                        builder: (context, state, _) => Icon(
                          state.torchState == TorchState.on
                              ? Icons.flash_on
                              : Icons.flash_off,
                          color: state.torchState == TorchState.on
                              ? AppColors.primary
                              : Colors.white,
                        ),
                      ),
                      label: l.flashlight,
                      onTap: () => _controller.toggleTorch(),
                    ),
                    _actionButton(
                      icon: const Icon(Icons.photo_library,
                          color: Colors.white),
                      label: l.selectFromGallery,
                      onTap: _pickFromGallery,
                    ),
                    _actionButton(
                      icon: Icon(
                        _showInput
                            ? Icons.keyboard_hide
                            : Icons.keyboard,
                        color: Colors.white,
                      ),
                      label: l.manualInput,
                      onTap: () =>
                          setState(() => _showInput = !_showInput),
                    ),
                  ],
                ),
                // 手动输入区域
                if (_showInput) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inputController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: l.enterBarcodeManually,
                            hintStyle:
                                const TextStyle(color: Colors.white38),
                            filled: true,
                            fillColor: Colors.white12,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _submitManualInput,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(l.confirm),
                      ),
                    ],
                  ),
                ],
                SizedBox(
                    height: MediaQuery.of(context).padding.bottom + 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required Widget icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(child: icon),
          ),
          const SizedBox(height: 6),
          Text(label,
              style:
                  const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  List<Widget> _buildCorners() {
    const size = 20.0;
    const thickness = 3.0;
    const color = AppColors.primary;

    Widget corner(
        {required Alignment alignment,
        required BorderRadius radius}) {
      return Align(
        alignment: alignment,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            border: Border(
              top: alignment.y < 0
                  ? const BorderSide(color: color, width: thickness)
                  : BorderSide.none,
              bottom: alignment.y > 0
                  ? const BorderSide(color: color, width: thickness)
                  : BorderSide.none,
              left: alignment.x < 0
                  ? const BorderSide(color: color, width: thickness)
                  : BorderSide.none,
              right: alignment.x > 0
                  ? const BorderSide(color: color, width: thickness)
                  : BorderSide.none,
            ),
          ),
        ),
      );
    }

    return [
      corner(
          alignment: Alignment.topLeft,
          radius: const BorderRadius.only(
              topLeft: Radius.circular(4))),
      corner(
          alignment: Alignment.topRight,
          radius: const BorderRadius.only(
              topRight: Radius.circular(4))),
      corner(
          alignment: Alignment.bottomLeft,
          radius: const BorderRadius.only(
              bottomLeft: Radius.circular(4))),
      corner(
          alignment: Alignment.bottomRight,
          radius: const BorderRadius.only(
              bottomRight: Radius.circular(4))),
    ];
  }
}
