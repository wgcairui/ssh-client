import 'package:flutter/material.dart';

/// 应用主题模式枚举
enum AppThemeMode {
  system,
  light,
  dark,
}

/// 主题设置数据模型
class ThemeSettings {
  final AppThemeMode themeMode;
  final ColorScheme? customLightColorScheme;
  final ColorScheme? customDarkColorScheme;
  final bool useSystemAccentColor;

  const ThemeSettings({
    this.themeMode = AppThemeMode.system,
    this.customLightColorScheme,
    this.customDarkColorScheme,
    this.useSystemAccentColor = true,
  });

  /// 从Map创建主题设置
  factory ThemeSettings.fromMap(Map<String, dynamic> map) {
    return ThemeSettings(
      themeMode: AppThemeMode.values[map['themeMode'] ?? 0],
      useSystemAccentColor: map['useSystemAccentColor'] ?? true,
      // 暂时不支持自定义颜色方案的序列化
    );
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'themeMode': themeMode.index,
      'useSystemAccentColor': useSystemAccentColor,
    };
  }

  /// 复制并修改主题设置
  ThemeSettings copyWith({
    AppThemeMode? themeMode,
    ColorScheme? customLightColorScheme,
    ColorScheme? customDarkColorScheme,
    bool? useSystemAccentColor,
  }) {
    return ThemeSettings(
      themeMode: themeMode ?? this.themeMode,
      customLightColorScheme: customLightColorScheme ?? this.customLightColorScheme,
      customDarkColorScheme: customDarkColorScheme ?? this.customDarkColorScheme,
      useSystemAccentColor: useSystemAccentColor ?? this.useSystemAccentColor,
    );
  }

  /// 获取亮色主题
  ThemeData getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: customLightColorScheme ?? ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 2,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  /// 获取暗色主题
  ThemeData getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: customDarkColorScheme ?? ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 2,
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  /// 获取终端主题配置
  TerminalThemeConfig getTerminalThemeConfig(bool isDarkMode) {
    if (isDarkMode) {
      return const TerminalThemeConfig(
        backgroundColor: Color(0xFF1A1A1A),
        foregroundColor: Color(0xFFE0E0E0),
        cursorColor: Color(0xFF00FF00),
        selectionColor: Color(0xFF404040),
        commentColor: Color(0xFF888888),
        keywordColor: Color(0xFF569CD6),
        stringColor: Color(0xFFCE9178),
        numberColor: Color(0xFFB5CEA8),
      );
    } else {
      return const TerminalThemeConfig(
        backgroundColor: Color(0xFFF8F8F8),
        foregroundColor: Color(0xFF333333),
        cursorColor: Color(0xFF007ACC),
        selectionColor: Color(0xFFB3D4FC),
        commentColor: Color(0xFF6A9955),
        keywordColor: Color(0xFF0000FF),
        stringColor: Color(0xFFCE9178),
        numberColor: Color(0xFF098658),
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemeSettings &&
          runtimeType == other.runtimeType &&
          themeMode == other.themeMode &&
          useSystemAccentColor == other.useSystemAccentColor;

  @override
  int get hashCode =>
      themeMode.hashCode ^ useSystemAccentColor.hashCode;

  @override
  String toString() {
    return 'ThemeSettings{themeMode: $themeMode, useSystemAccentColor: $useSystemAccentColor}';
  }
}

/// 终端主题配置
class TerminalThemeConfig {
  final Color backgroundColor;
  final Color foregroundColor;
  final Color cursorColor;
  final Color selectionColor;
  final Color commentColor;
  final Color keywordColor;
  final Color stringColor;
  final Color numberColor;

  const TerminalThemeConfig({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.cursorColor,
    required this.selectionColor,
    required this.commentColor,
    required this.keywordColor,
    required this.stringColor,
    required this.numberColor,
  });
}

/// 应用主题模式扩展
extension AppThemeModeExtension on AppThemeMode {
  String get displayName {
    switch (this) {
      case AppThemeMode.system:
        return '跟随系统';
      case AppThemeMode.light:
        return '浅色模式';
      case AppThemeMode.dark:
        return '深色模式';
    }
  }

  IconData get icon {
    switch (this) {
      case AppThemeMode.system:
        return Icons.brightness_auto;
      case AppThemeMode.light:
        return Icons.brightness_high;
      case AppThemeMode.dark:
        return Icons.brightness_2;
    }
  }
}