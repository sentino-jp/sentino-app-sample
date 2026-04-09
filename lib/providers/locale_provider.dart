import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 支持的语言列表，可扩展
class SupportedLocales {
  SupportedLocales._();

  static const Locale zhCN = Locale('zh', 'CN');
  static const Locale jaJP = Locale('ja', 'JP');
  static const Locale enUS = Locale('en', 'US');

  static const List<Locale> all = [zhCN, jaJP, enUS];

  static const Map<String, String> displayNames = {
    'zh': '简体中文',
    'ja': '日本語',
    'en': 'English',
  };

  /// 语言代码到接口 language 参数的映射
  /// 格式：zh_CN, en_US, ja_JP
  static const Map<String, String> languageCodes = {
    'zh': 'zh_CN',
    'ja': 'ja_JP',
    'en': 'en_US',
  };

  static String getDisplayName(Locale locale) {
    return displayNames[locale.languageCode] ?? locale.languageCode;
  }
}

/// 语言状态管理 Provider
///
/// 默认跟随手机系统语言设置，用户也可手动切换。
/// 通过 [language] 获取接口请求所需的 language 参数（如 zh_CN, en_US, ja_JP）。
class LocaleProvider extends ChangeNotifier {
  static const String _localeKey = 'app_locale';

  Locale? _locale; // null 表示跟随系统
  final SharedPreferences _prefs;
  void Function(String language)? onLanguageChanged;

  LocaleProvider(this._prefs) {
    _loadLocale();
  }

  /// 当前 Locale，null 表示跟随系统
  Locale? get locale => _locale;

  /// 获取当前生效的 Locale（考虑系统语言）
  Locale get effectiveLocale =>
      _locale ?? _systemLocale;

  /// 获取接口请求用的 language 参数
  /// 格式：zh_CN, en_US, ja_JP，跟随手机系统或用户手动设置
  String get language {
    final langCode = effectiveLocale.languageCode;
    return SupportedLocales.languageCodes[langCode] ?? 'en_US';
  }

  /// 是否跟随系统
  bool get isFollowSystem => _locale == null;

  Locale get _systemLocale => PlatformDispatcher.instance.locale;

  void _loadLocale() {
    final stored = _prefs.getString(_localeKey);
    if (stored != null) {
      _locale = _parseLocale(stored);
    }
    // 未存储时 _locale 为 null，跟随系统
  }

  /// 手动设置语言
  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    await _prefs.setString(
        _localeKey, '${locale.languageCode}_${locale.countryCode}');
    onLanguageChanged?.call(language);
    notifyListeners();
  }

  /// 恢复跟随系统
  Future<void> followSystem() async {
    _locale = null;
    await _prefs.remove(_localeKey);
    onLanguageChanged?.call(language);
    notifyListeners();
  }

  static Locale? _parseLocale(String value) {
    final parts = value.split('_');
    if (parts.length == 2) {
      return Locale(parts[0], parts[1]);
    }
    if (parts.length == 1) {
      return Locale(parts[0]);
    }
    return null;
  }
}
