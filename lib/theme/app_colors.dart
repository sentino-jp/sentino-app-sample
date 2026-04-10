import 'package:flutter/material.dart';

/// AG Play 品牌色和应用色彩定义
/// 主色调：深红色，红色向黑色渐变，科技感扁平化
class AppColors {
  AppColors._();

  // 品牌主色调 - 深红色渐变
  static const Color primary = Color(0xFFB71C1C);
  static const Color primaryLight = Color(0xFFD32F2F);
  static const Color primaryDark = Color(0xFF7F0000);
  static const Color primaryDeep = Color(0xFF4A0000);

  // 科技感辅助色
  static const Color accent = Color(0xFFFF5252);
  static const Color subtle = Color(0x14B71C1C); // primary 8% opacity

  // 渐变色
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryLight, primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryToBlackGradient = LinearGradient(
    colors: [primary, primaryDark, Color(0xFF1A0000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 明亮模式
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Colors.white;
  static const Color lightOnBackground = Color(0xFF1A1A1A);
  static const Color lightOnSurface = Color(0xFF2D2D2D);
  static const Color lightSecondaryText = Color(0xFF8E8E93);
  static const Color lightDivider = Color(0xFFF0F0F0);
  static const Color lightCard = Color(0xFFFFFFFF);

  // 暗黑模式
  static const Color darkBackground = Color(0xFF0D0D0D);
  static const Color darkSurface = Color(0xFF1C1C1E);
  static const Color darkOnBackground = Color(0xFFE5E5EA);
  static const Color darkOnSurface = Color(0xFFD1D1D6);
  static const Color darkSecondaryText = Color(0xFF8E8E93);
  static const Color darkDivider = Color(0xFF38383A);
  static const Color darkCard = Color(0xFF1C1C1E);

  // 功能色
  static const Color success = Color(0xFF34C759);
  static const Color error = Color(0xFFFF3B30);
  static const Color warning = Color(0xFFFF9500);
  static const Color info = Color(0xFF007AFF);

  // 设备状态色
  static const Color online = Color(0xFF34C759);
  static const Color offline = Color(0xFFC7C7CC);

  // Tag 色
  static const Color tagBg = Color(0x28B71C1C);
  static const Color tagText = Color(0xFFB71C1C);
}
