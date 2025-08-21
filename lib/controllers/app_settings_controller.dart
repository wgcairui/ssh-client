import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/font_settings.dart';
import '../models/theme_settings.dart';

/// 应用设置控制器
class AppSettingsController extends ChangeNotifier {
  static const String _fontSettingsKey = 'font_settings';
  static const String _themeSettingsKey = 'theme_settings';

  FontSettings _fontSettings = const FontSettings();
  ThemeSettings _themeSettings = const ThemeSettings();
  SharedPreferences? _prefs;
  bool _isInitialized = false;

  /// 获取字体设置
  FontSettings get fontSettings => _fontSettings;

  /// 获取主题设置
  ThemeSettings get themeSettings => _themeSettings;

  /// 是否已初始化
  bool get isInitialized => _isInitialized;

  /// 是否为暗色模式
  bool get isDarkMode {
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    switch (_themeSettings.themeMode) {
      case AppThemeMode.system:
        return brightness == Brightness.dark;
      case AppThemeMode.light:
        return false;
      case AppThemeMode.dark:
        return true;
    }
  }

  /// 初始化设置
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadSettings();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('初始化应用设置失败: $e');
    }
  }

  /// 加载设置
  Future<void> _loadSettings() async {
    if (_prefs == null) return;

    // 加载字体设置
    final fontSettingsJson = _prefs!.getString(_fontSettingsKey);
    if (fontSettingsJson != null) {
      try {
        final fontMap = <String, dynamic>{};
        final pairs = fontSettingsJson.split('&');
        for (final pair in pairs) {
          final kv = pair.split('=');
          if (kv.length == 2) {
            final key = kv[0];
            final value = kv[1];
            if (key == 'fontFamily') {
              fontMap[key] = value;
            } else if (key == 'fontSize' || key == 'terminalFontSize') {
              final parsedValue = double.tryParse(value) ?? 14.0;
              fontMap[key] = parsedValue.clamp(8.0, 50.0); // 确保范围有效
            } else if (key == 'fontWeight') {
              fontMap[key] = int.tryParse(value) ?? FontWeight.normal.index;
            }
          }
        }
        
        final loadedSettings = FontSettings.fromMap(fontMap);
        // 额外验证加载的设置
        if (loadedSettings.fontSize > 0 && loadedSettings.terminalFontSize > 0) {
          _fontSettings = loadedSettings;
          debugPrint('加载字体设置成功: fontSize=${_fontSettings.fontSize}');
        } else {
          debugPrint('加载的字体设置无效，使用默认设置');
          _fontSettings = const FontSettings();
        }
      } catch (e) {
        debugPrint('解析字体设置失败: $e，使用默认设置');
        _fontSettings = const FontSettings();
      }
    } else {
      debugPrint('未找到保存的字体设置，使用默认设置');
      _fontSettings = const FontSettings();
    }

    // 加载主题设置
    final themeSettingsJson = _prefs!.getString(_themeSettingsKey);
    if (themeSettingsJson != null) {
      try {
        final themeMap = <String, dynamic>{};
        final pairs = themeSettingsJson.split('&');
        for (final pair in pairs) {
          final kv = pair.split('=');
          if (kv.length == 2) {
            final key = kv[0];
            final value = kv[1];
            if (key == 'themeMode') {
              themeMap[key] = int.tryParse(value) ?? 0;
            } else if (key == 'useSystemAccentColor') {
              themeMap[key] = value == 'true';
            }
          }
        }
        _themeSettings = ThemeSettings.fromMap(themeMap);
      } catch (e) {
        debugPrint('解析主题设置失败: $e');
      }
    }
  }

  /// 保存设置
  Future<void> _saveSettings() async {
    if (_prefs == null) return;

    try {
      // 保存字体设置
      final fontMap = _fontSettings.toMap();
      final fontPairs = fontMap.entries.map((e) => '${e.key}=${e.value}').toList();
      await _prefs!.setString(_fontSettingsKey, fontPairs.join('&'));

      // 保存主题设置
      final themeMap = _themeSettings.toMap();
      final themePairs = themeMap.entries.map((e) => '${e.key}=${e.value}').toList();
      await _prefs!.setString(_themeSettingsKey, themePairs.join('&'));
    } catch (e) {
      debugPrint('保存应用设置失败: $e');
    }
  }

  /// 更新字体设置
  Future<void> updateFontSettings(FontSettings newSettings) async {
    if (_fontSettings == newSettings) return;

    _fontSettings = newSettings;
    await _saveSettings();
    notifyListeners();
  }

  /// 更新主题设置
  Future<void> updateThemeSettings(ThemeSettings newSettings) async {
    if (_themeSettings == newSettings) return;

    _themeSettings = newSettings;
    await _saveSettings();
    notifyListeners();
  }

  /// 更新字体家族
  Future<void> updateFontFamily(String fontFamily) async {
    await updateFontSettings(_fontSettings.copyWith(fontFamily: fontFamily));
  }

  /// 更新字体大小
  Future<void> updateFontSize(double fontSize) async {
    final clampedSize = fontSize.clamp(8.0, 50.0);
    await updateFontSettings(_fontSettings.copyWith(fontSize: clampedSize));
  }

  /// 更新终端字体大小
  Future<void> updateTerminalFontSize(double terminalFontSize) async {
    final clampedSize = terminalFontSize.clamp(8.0, 50.0);
    await updateFontSettings(_fontSettings.copyWith(terminalFontSize: clampedSize));
  }

  /// 更新字体权重
  Future<void> updateFontWeight(FontWeight fontWeight) async {
    await updateFontSettings(_fontSettings.copyWith(fontWeight: fontWeight));
  }

  /// 更新主题模式
  Future<void> updateThemeMode(AppThemeMode themeMode) async {
    await updateThemeSettings(_themeSettings.copyWith(themeMode: themeMode));
  }

  /// 切换主题模式
  Future<void> toggleThemeMode() async {
    final currentMode = _themeSettings.themeMode;
    AppThemeMode newMode;
    switch (currentMode) {
      case AppThemeMode.system:
        newMode = AppThemeMode.light;
        break;
      case AppThemeMode.light:
        newMode = AppThemeMode.dark;
        break;
      case AppThemeMode.dark:
        newMode = AppThemeMode.system;
        break;
    }
    await updateThemeMode(newMode);
  }

  /// 重置为默认设置
  Future<void> resetToDefaults() async {
    _fontSettings = const FontSettings();
    _themeSettings = const ThemeSettings();
    await _saveSettings();
    notifyListeners();
  }

  /// 获取当前的主题数据
  ThemeData getLightTheme() {
    final baseTheme = _themeSettings.getLightTheme();
    
    // 确保字体大小有效，避免 0 或负值
    final safeFontSize = _fontSettings.fontSize > 0 ? _fontSettings.fontSize : 14.0;
    
    // 避免使用 apply 的 fontSizeFactor，直接创建 TextTheme
    final originalTextTheme = baseTheme.textTheme;
    final customTextTheme = TextTheme(
      displayLarge: originalTextTheme.displayLarge?.copyWith(
        fontFamily: _fontSettings.fontFamily,
        fontSize: originalTextTheme.displayLarge?.fontSize != null 
          ? (originalTextTheme.displayLarge!.fontSize! * safeFontSize / 14.0).clamp(8.0, 100.0)
          : safeFontSize,
      ),
      displayMedium: originalTextTheme.displayMedium?.copyWith(
        fontFamily: _fontSettings.fontFamily,
        fontSize: originalTextTheme.displayMedium?.fontSize != null 
          ? (originalTextTheme.displayMedium!.fontSize! * safeFontSize / 14.0).clamp(8.0, 100.0)
          : safeFontSize,
      ),
      displaySmall: originalTextTheme.displaySmall?.copyWith(
        fontFamily: _fontSettings.fontFamily,
        fontSize: originalTextTheme.displaySmall?.fontSize != null 
          ? (originalTextTheme.displaySmall!.fontSize! * safeFontSize / 14.0).clamp(8.0, 100.0)
          : safeFontSize,
      ),
      headlineLarge: originalTextTheme.headlineLarge?.copyWith(
        fontFamily: _fontSettings.fontFamily,
        fontSize: originalTextTheme.headlineLarge?.fontSize != null 
          ? (originalTextTheme.headlineLarge!.fontSize! * safeFontSize / 14.0).clamp(8.0, 100.0)
          : safeFontSize,
      ),
      headlineMedium: originalTextTheme.headlineMedium?.copyWith(
        fontFamily: _fontSettings.fontFamily,
        fontSize: originalTextTheme.headlineMedium?.fontSize != null 
          ? (originalTextTheme.headlineMedium!.fontSize! * safeFontSize / 14.0).clamp(8.0, 100.0)
          : safeFontSize,
      ),
      headlineSmall: originalTextTheme.headlineSmall?.copyWith(
        fontFamily: _fontSettings.fontFamily,
        fontSize: originalTextTheme.headlineSmall?.fontSize != null 
          ? (originalTextTheme.headlineSmall!.fontSize! * safeFontSize / 14.0).clamp(8.0, 100.0)
          : safeFontSize,
      ),
      titleLarge: originalTextTheme.titleLarge?.copyWith(
        fontFamily: _fontSettings.fontFamily,
        fontSize: originalTextTheme.titleLarge?.fontSize != null 
          ? (originalTextTheme.titleLarge!.fontSize! * safeFontSize / 14.0).clamp(8.0, 100.0)
          : safeFontSize,
      ),
      titleMedium: originalTextTheme.titleMedium?.copyWith(
        fontFamily: _fontSettings.fontFamily,
        fontSize: originalTextTheme.titleMedium?.fontSize != null 
          ? (originalTextTheme.titleMedium!.fontSize! * safeFontSize / 14.0).clamp(8.0, 100.0)
          : safeFontSize,
      ),
      titleSmall: originalTextTheme.titleSmall?.copyWith(
        fontFamily: _fontSettings.fontFamily,
        fontSize: originalTextTheme.titleSmall?.fontSize != null 
          ? (originalTextTheme.titleSmall!.fontSize! * safeFontSize / 14.0).clamp(8.0, 100.0)
          : safeFontSize,
      ),
      bodyLarge: originalTextTheme.bodyLarge?.copyWith(
        fontFamily: _fontSettings.fontFamily,
        fontSize: safeFontSize,
      ),
      bodyMedium: originalTextTheme.bodyMedium?.copyWith(
        fontFamily: _fontSettings.fontFamily,
        fontSize: safeFontSize,
      ),
      bodySmall: originalTextTheme.bodySmall?.copyWith(
        fontFamily: _fontSettings.fontFamily,
        fontSize: (safeFontSize * 0.9).clamp(8.0, 100.0),
      ),
      labelLarge: originalTextTheme.labelLarge?.copyWith(
        fontFamily: _fontSettings.fontFamily,
        fontSize: safeFontSize,
      ),
      labelMedium: originalTextTheme.labelMedium?.copyWith(
        fontFamily: _fontSettings.fontFamily,
        fontSize: (safeFontSize * 0.85).clamp(8.0, 100.0),
      ),
      labelSmall: originalTextTheme.labelSmall?.copyWith(
        fontFamily: _fontSettings.fontFamily,
        fontSize: (safeFontSize * 0.8).clamp(8.0, 100.0),
      ),
    );
    
    return baseTheme.copyWith(textTheme: customTextTheme);
  }

  /// 获取当前的暗色主题数据
  ThemeData getDarkTheme() {
    final baseTheme = _themeSettings.getDarkTheme();
    
    // 确保字体大小有效，避免 0 或负值
    final safeFontSize = _fontSettings.fontSize > 0 ? _fontSettings.fontSize : 14.0;
    
    // 避免使用 apply 的 fontSizeFactor，直接创建 TextTheme
    final originalTextTheme = baseTheme.textTheme;
    final customTextTheme = TextTheme(
      displayLarge: originalTextTheme.displayLarge?.copyWith(
        fontFamily: _fontSettings.fontFamily,
        fontSize: originalTextTheme.displayLarge?.fontSize != null 
          ? (originalTextTheme.displayLarge!.fontSize! * safeFontSize / 14.0).clamp(8.0, 100.0)
          : safeFontSize,
      ),
      displayMedium: originalTextTheme.displayMedium?.copyWith(
        fontFamily: _fontSettings.fontFamily,
        fontSize: originalTextTheme.displayMedium?.fontSize != null 
          ? (originalTextTheme.displayMedium!.fontSize! * safeFontSize / 14.0).clamp(8.0, 100.0)
          : safeFontSize,
      ),
      displaySmall: originalTextTheme.displaySmall?.copyWith(
        fontFamily: _fontSettings.fontFamily,
        fontSize: originalTextTheme.displaySmall?.fontSize != null 
          ? (originalTextTheme.displaySmall!.fontSize! * safeFontSize / 14.0).clamp(8.0, 100.0)
          : safeFontSize,
      ),
      headlineLarge: originalTextTheme.headlineLarge?.copyWith(
        fontFamily: _fontSettings.fontFamily,
        fontSize: originalTextTheme.headlineLarge?.fontSize != null 
          ? (originalTextTheme.headlineLarge!.fontSize! * safeFontSize / 14.0).clamp(8.0, 100.0)
          : safeFontSize,
      ),
      headlineMedium: originalTextTheme.headlineMedium?.copyWith(
        fontFamily: _fontSettings.fontFamily,
        fontSize: originalTextTheme.headlineMedium?.fontSize != null 
          ? (originalTextTheme.headlineMedium!.fontSize! * safeFontSize / 14.0).clamp(8.0, 100.0)
          : safeFontSize,
      ),
      headlineSmall: originalTextTheme.headlineSmall?.copyWith(
        fontFamily: _fontSettings.fontFamily,
        fontSize: originalTextTheme.headlineSmall?.fontSize != null 
          ? (originalTextTheme.headlineSmall!.fontSize! * safeFontSize / 14.0).clamp(8.0, 100.0)
          : safeFontSize,
      ),
      titleLarge: originalTextTheme.titleLarge?.copyWith(
        fontFamily: _fontSettings.fontFamily,
        fontSize: originalTextTheme.titleLarge?.fontSize != null 
          ? (originalTextTheme.titleLarge!.fontSize! * safeFontSize / 14.0).clamp(8.0, 100.0)
          : safeFontSize,
      ),
      titleMedium: originalTextTheme.titleMedium?.copyWith(
        fontFamily: _fontSettings.fontFamily,
        fontSize: originalTextTheme.titleMedium?.fontSize != null 
          ? (originalTextTheme.titleMedium!.fontSize! * safeFontSize / 14.0).clamp(8.0, 100.0)
          : safeFontSize,
      ),
      titleSmall: originalTextTheme.titleSmall?.copyWith(
        fontFamily: _fontSettings.fontFamily,
        fontSize: originalTextTheme.titleSmall?.fontSize != null 
          ? (originalTextTheme.titleSmall!.fontSize! * safeFontSize / 14.0).clamp(8.0, 100.0)
          : safeFontSize,
      ),
      bodyLarge: originalTextTheme.bodyLarge?.copyWith(
        fontFamily: _fontSettings.fontFamily,
        fontSize: safeFontSize,
      ),
      bodyMedium: originalTextTheme.bodyMedium?.copyWith(
        fontFamily: _fontSettings.fontFamily,
        fontSize: safeFontSize,
      ),
      bodySmall: originalTextTheme.bodySmall?.copyWith(
        fontFamily: _fontSettings.fontFamily,
        fontSize: (safeFontSize * 0.9).clamp(8.0, 100.0),
      ),
      labelLarge: originalTextTheme.labelLarge?.copyWith(
        fontFamily: _fontSettings.fontFamily,
        fontSize: safeFontSize,
      ),
      labelMedium: originalTextTheme.labelMedium?.copyWith(
        fontFamily: _fontSettings.fontFamily,
        fontSize: (safeFontSize * 0.85).clamp(8.0, 100.0),
      ),
      labelSmall: originalTextTheme.labelSmall?.copyWith(
        fontFamily: _fontSettings.fontFamily,
        fontSize: (safeFontSize * 0.8).clamp(8.0, 100.0),
      ),
    );
    
    return baseTheme.copyWith(textTheme: customTextTheme);
  }

  /// 获取文本样式
  TextStyle getTextStyle({
    Color? color,
    double? customSize,
    FontWeight? customWeight,
  }) {
    return _fontSettings.getUITextStyle(
      color: color,
      customSize: customSize,
    ).copyWith(
      fontWeight: customWeight,
    );
  }

  /// 获取响应式图标大小
  double getIconSize(double baseSize) {
    final scaleFactor = _fontSettings.fontSize / 14.0;
    return (baseSize * scaleFactor).clamp(8.0, 200.0);
  }

  /// 获取侧边栏字体样式 (0.6倍缩放)
  TextStyle getSidebarTextStyle({
    Color? color,
    double? customSize,
    FontWeight? customWeight,
  }) {
    final sidebarFontSize = _fontSettings.fontSize * 0.6;
    return TextStyle(
      fontFamily: _fontSettings.fontFamily,
      fontSize: customSize != null 
          ? (customSize * sidebarFontSize / 14.0).clamp(8.0, 50.0)
          : sidebarFontSize,
      fontWeight: customWeight ?? _fontSettings.fontWeight,
      color: color,
    );
  }

  /// 获取终端文本样式
  TextStyle getTerminalTextStyle({
    Color? color,
    Color? backgroundColor,
  }) {
    return _fontSettings.getTerminalTextStyle(
      color: color,
      backgroundColor: backgroundColor,
    );
  }

  /// 获取终端主题配置
  TerminalThemeConfig getTerminalThemeConfig() {
    return _themeSettings.getTerminalThemeConfig(isDarkMode);
  }
}