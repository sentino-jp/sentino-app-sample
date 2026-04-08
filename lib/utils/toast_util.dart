import 'package:flutter/material.dart';

/// 全局 Toast 工具，居中显示提示信息
class ToastUtil {
  ToastUtil._();

  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// 全局 navigatorKey，用于获取 Overlay
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static OverlayEntry? _currentEntry;

  /// 显示错误提示（居中）
  static void showError(String message) {
    _show(message, Colors.red[700]!, Icons.error_outline);
  }

  /// 显示成功提示（居中）
  static void showSuccess(String message) {
    _show(message, Colors.green[700]!, Icons.check_circle_outline);
  }

  /// 显示信息提示（居中）
  static void showInfo(String message) {
    _show(message, Colors.blueGrey[700]!, Icons.info_outline);
  }

  static void _show(String message, Color bgColor, IconData icon) {
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;

    final entry = OverlayEntry(builder: (context) {
      return _ToastOverlay(
        message: message,
        bgColor: bgColor,
        icon: icon,
        onDismiss: () {
          _currentEntry?.remove();
          _currentEntry = null;
        },
      );
    });

    _currentEntry = entry;
    overlay.insert(entry);
  }
}

/// 居中显示的 Toast Overlay 组件
class _ToastOverlay extends StatefulWidget {
  final String message;
  final Color bgColor;
  final IconData icon;
  final VoidCallback onDismiss;

  const _ToastOverlay({
    required this.message,
    required this.bgColor,
    required this.icon,
    required this.onDismiss,
  });

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: FadeTransition(
            opacity: _opacity,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 48),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: widget.bgColor.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        decoration: TextDecoration.none,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
