import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 雷达扫描动画组件，带设备图标散布在环上
/// 参照 Android AutoScanActivity 的旋转扫描动画效果
class RadarScanWidget extends StatefulWidget {
  final double size;
  final List<RadarDevice> devices;
  final void Function(RadarDevice device)? onDeviceTap;
  final bool isScanning;

  const RadarScanWidget({
    super.key,
    this.size = 300,
    this.devices = const [],
    this.onDeviceTap,
    this.isScanning = true,
  });

  @override
  State<RadarScanWidget> createState() => _RadarScanWidgetState();
}

class _RadarScanWidgetState extends State<RadarScanWidget>
    with TickerProviderStateMixin {
  late AnimationController _sweepController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    if (widget.isScanning) {
      _sweepController.repeat();
      _pulseController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant RadarScanWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning && !_sweepController.isAnimating) {
      _sweepController.repeat();
      _pulseController.repeat();
    } else if (!widget.isScanning && _sweepController.isAnimating) {
      _sweepController.stop();
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _sweepController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 雷达环
          CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _RadarRingsPainter(),
          ),
          // 脉冲波纹动画
          if (widget.isScanning)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _PulseRingPainter(progress: _pulseAnimation.value),
                );
              },
            ),
          // 扫描线旋转动画
          if (widget.isScanning)
            AnimatedBuilder(
              animation: _sweepController,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _RadarSweepPainter(
                      angle: _sweepController.value * 2 * pi),
                );
              },
            ),
          // 中心蓝牙图标
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 16,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(Icons.bluetooth, color: Colors.white, size: 26),
          ),
          // 设备图标
          ..._buildDeviceIcons(),
        ],
      ),
    );
  }

  List<Widget> _buildDeviceIcons() {
    final center = widget.size / 2;
    final maxRadius = widget.size / 2 - 30;
    final devices = widget.devices;
    final result = <Widget>[];

    for (var i = 0; i < devices.length; i++) {
      final angle = (2 * pi / max(devices.length, 1)) * i - pi / 2;
      final ringFactor = 0.4 + (i % 3) * 0.2;
      final radius = maxRadius * ringFactor;
      final x = center + radius * cos(angle) - 22;
      final y = center + radius * sin(angle) - 28;

      final device = devices[i];
      result.add(Positioned(
        left: x,
        top: y,
        child: _DeviceIcon(
          device: device,
          index: i,
          onTap: () => widget.onDeviceTap?.call(device),
        ),
      ));
    }
    return result;
  }
}

/// 设备图标组件，带出现动画
class _DeviceIcon extends StatefulWidget {
  final RadarDevice device;
  final int index;
  final VoidCallback? onTap;

  const _DeviceIcon({
    required this.device,
    required this.index,
    this.onTap,
  });

  @override
  State<_DeviceIcon> createState() => _DeviceIconState();
}

class _DeviceIconState extends State<_DeviceIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _appearController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _appearController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _appearController, curve: Curves.elasticOut),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _appearController, curve: Curves.easeIn),
    );
    // 延迟出现，产生逐个弹出效果
    Future.delayed(Duration(milliseconds: 150 * widget.index), () {
      if (mounted) _appearController.forward();
    });
  }

  @override
  void dispose() {
    _appearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _appearController,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).cardColor,
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: widget.device.imageUrl != null &&
                      widget.device.imageUrl!.isNotEmpty
                  ? Image.network(widget.device.imageUrl!, fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => const Icon(Icons.speaker,
                          size: 22, color: AppColors.primary))
                  : const Icon(Icons.speaker,
                      size: 22, color: AppColors.primary),
            ),
            const SizedBox(height: 3),
            SizedBox(
              width: 56,
              child: Text(
                widget.device.name,
                style:
                    const TextStyle(fontSize: 9, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 雷达设备数据
class RadarDevice {
  final String id;
  final String name;
  final String? imageUrl;
  final dynamic raw;

  const RadarDevice({
    required this.id,
    required this.name,
    this.imageUrl,
    this.raw,
  });
}

/// 雷达环绘制
class _RadarRingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2 - 10;

    // 绘制 3 个同心圆环
    for (var i = 1; i <= 3; i++) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = AppColors.primary.withValues(alpha: 0.08 + i * 0.04);
      canvas.drawCircle(center, maxRadius * i / 3, paint);
    }

    // 十字线
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.3
      ..color = AppColors.primary.withValues(alpha: 0.08);
    canvas.drawLine(
        Offset(center.dx, 10), Offset(center.dx, size.height - 10), linePaint);
    canvas.drawLine(
        Offset(10, center.dy), Offset(size.width - 10, center.dy), linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 脉冲波纹绘制
class _PulseRingPainter extends CustomPainter {
  final double progress;
  _PulseRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2 - 10;
    final radius = maxRadius * progress;
    final opacity = (1.0 - progress) * 0.3;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = AppColors.primary.withValues(alpha: opacity);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _PulseRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// 扫描线绘制（扇形渐变 + 扫描线）
class _RadarSweepPainter extends CustomPainter {
  final double angle;
  _RadarSweepPainter({required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2 - 10;

    // 扇形渐变尾迹
    final rect = Rect.fromCircle(center: center, radius: maxRadius);
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: angle - 0.8,
        endAngle: angle,
        colors: [
          Colors.transparent,
          AppColors.primary.withValues(alpha: 0.08),
          AppColors.primary.withValues(alpha: 0.2),
        ],
        stops: const [0.0, 0.5, 1.0],
        transform: GradientRotation(angle - 0.8),
      ).createShader(rect);

    canvas.save();
    canvas.clipPath(Path()..addOval(rect));
    canvas.drawPaint(sweepPaint);
    canvas.restore();

    // 扫描线
    final lineEnd = Offset(
      center.dx + maxRadius * cos(angle),
      center.dy + maxRadius * sin(angle),
    );
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = LinearGradient(
        colors: [
          AppColors.primary.withValues(alpha: 0.6),
          AppColors.primary.withValues(alpha: 0.1),
        ],
      ).createShader(Rect.fromPoints(center, lineEnd));
    canvas.drawLine(center, lineEnd, linePaint);

    // 扫描线末端光点
    final dotPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(lineEnd, 3, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _RadarSweepPainter oldDelegate) =>
      oldDelegate.angle != angle;
}
