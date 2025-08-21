import 'package:flutter/material.dart';

/// 字体设置数据模型
class FontSettings {
  final String fontFamily;
  final double fontSize;
  final double terminalFontSize;
  final FontWeight fontWeight;

  const FontSettings({
    this.fontFamily = 'Roboto',
    this.fontSize = 14.0,
    this.terminalFontSize = 14.0,
    this.fontWeight = FontWeight.normal,
  }) : assert(fontSize > 0, 'Font size must be greater than 0'),
       assert(terminalFontSize > 0, 'Terminal font size must be greater than 0');

  /// 从Map创建字体设置
  factory FontSettings.fromMap(Map<String, dynamic> map) {
    final fontSize = ((map['fontSize'] ?? 14.0).toDouble()).clamp(8.0, 50.0);
    final terminalFontSize = ((map['terminalFontSize'] ?? 14.0).toDouble()).clamp(8.0, 50.0);
    
    // Handle invalid font weight index
    int fontWeightIndex = map['fontWeight'] ?? FontWeight.normal.index;
    if (fontWeightIndex < 0 || fontWeightIndex >= FontWeight.values.length) {
      fontWeightIndex = FontWeight.normal.index;
    }
    
    return FontSettings(
      fontFamily: map['fontFamily'] ?? 'Roboto',
      fontSize: fontSize,
      terminalFontSize: terminalFontSize,
      fontWeight: FontWeight.values[fontWeightIndex],
    );
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'fontFamily': fontFamily,
      'fontSize': fontSize,
      'terminalFontSize': terminalFontSize,
      'fontWeight': fontWeight.index,
    };
  }

  /// 复制并修改字体设置
  FontSettings copyWith({
    String? fontFamily,
    double? fontSize,
    double? terminalFontSize,
    FontWeight? fontWeight,
  }) {
    return FontSettings(
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize?.clamp(8.0, 50.0) ?? this.fontSize,
      terminalFontSize: terminalFontSize?.clamp(8.0, 50.0) ?? this.terminalFontSize,
      fontWeight: fontWeight ?? this.fontWeight,
    );
  }

  /// 获取UI文本样式
  TextStyle getUITextStyle({
    Color? color,
    double? customSize,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: customSize ?? fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  /// 获取终端文本样式
  TextStyle getTerminalTextStyle({
    Color? color,
    Color? backgroundColor,
  }) {
    return TextStyle(
      fontFamily: 'Courier New', // 终端使用等宽字体
      fontSize: terminalFontSize,
      fontWeight: FontWeight.normal,
      color: color,
      backgroundColor: backgroundColor,
      letterSpacing: 0.5,
      height: 1.2,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FontSettings &&
          runtimeType == other.runtimeType &&
          fontFamily == other.fontFamily &&
          fontSize == other.fontSize &&
          terminalFontSize == other.terminalFontSize &&
          fontWeight == other.fontWeight;

  @override
  int get hashCode =>
      fontFamily.hashCode ^
      fontSize.hashCode ^
      terminalFontSize.hashCode ^
      fontWeight.hashCode;

  @override
  String toString() {
    return 'FontSettings{fontFamily: $fontFamily, fontSize: $fontSize, terminalFontSize: $terminalFontSize, fontWeight: $fontWeight}';
  }
}

/// 可用的字体选项
class FontOptions {
  static const List<String> availableFonts = [
    'Roboto',
    'Arial',
    'Helvetica',
    'Source Sans Pro',
    'Open Sans',
    'Noto Sans',
    'System Default',
  ];

  static const List<double> availableFontSizes = [
    8.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 20.0, 22.0, 24.0, 26.0, 28.0, 30.0, 32.0, 36.0, 40.0, 48.0
  ];

  static const List<FontWeight> availableFontWeights = [
    FontWeight.w300,
    FontWeight.w400,
    FontWeight.w500,
    FontWeight.w600,
    FontWeight.w700,
  ];

  static String getFontWeightName(FontWeight weight) {
    switch (weight) {
      case FontWeight.w300:
        return '细体';
      case FontWeight.w400:
        return '正常';
      case FontWeight.w500:
        return '中等';
      case FontWeight.w600:
        return '半粗体';
      case FontWeight.w700:
        return '粗体';
      default:
        return '正常';
    }
  }
}