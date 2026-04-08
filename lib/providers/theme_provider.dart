import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

/// 主题模式枚举：明亮、暗黑、跟随系统
enum AppThemeMode { light, dark, system }

/// 主题状态管理 Provider
///
/// 支持明亮/暗黑/跟随系统三种模式切换，
/// 使用 shared_preferences 持久化主题偏好。
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';

  AppThemeMode _themeMode = AppThemeMode.system;
  final SharedPreferences _prefs;

  ThemeProvider(this._prefs) {
    _loadThemeMode();
  }

  AppThemeMode get themeMode => _themeMode;

  ThemeData get lightTheme => AppTheme.light;
  ThemeData get darkTheme => AppTheme.dark;

  ThemeMode get materialThemeMode {
    switch (_themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  void _loadThemeMode() {
    final stored = _prefs.getString(_themeKey);
    if (stored != null) {
      _themeMode = parseThemeMode(stored);
    }
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    await _prefs.setString(_themeKey, mode.name);
    notifyListeners();
  }

  /// 将字符串解析为 AppThemeMode，无效值返回 system
  static AppThemeMode parseThemeMode(String value) {
    switch (value) {
      case 'light':
        return AppThemeMode.light;
      case 'dark':
        return AppThemeMode.dark;
      case 'system':
        return AppThemeMode.system;
      default:
        return AppThemeMode.system;
    }
  }
}
