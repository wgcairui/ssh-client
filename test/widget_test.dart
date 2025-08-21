// SSH Client widget tests.
//
// Tests for the SSH client application functionality.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:ssh_client/main.dart';
import 'package:ssh_client/controllers/ssh_controller.dart';
import 'package:ssh_client/controllers/ssh_session_controller.dart';
import 'package:ssh_client/controllers/ssh_tab_controller.dart';
import 'package:ssh_client/controllers/file_transfer_controller.dart';
import 'package:ssh_client/controllers/app_settings_controller.dart';
import 'package:ssh_client/models/font_settings.dart';
import 'package:ssh_client/models/theme_settings.dart';

void main() {
  setUpAll(() {
    // Initialize FFI for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('SSH Client Controller Tests', () {
    test('SshTabController manages tabs correctly', () {
      final tabController = SshTabController();
      
      // Test initial state
      expect(tabController.tabs.length, 0);
      expect(tabController.activeTab, isNull);
      expect(tabController.isMaxTabsReached, false);
      
      // Test max tabs limit
      expect(SshTabController.maxTabs, 10);
    });

    test('SshSessionController manages sessions correctly', () {
      final sessionController = SshSessionController();
      
      // Test initial state
      expect(sessionController.sessions.length, 0);
      expect(sessionController.activeSessionId, isNull);
      expect(sessionController.hasActiveConnection, false);
      expect(sessionController.sessionCount, 0);
      expect(sessionController.connectedSessionCount, 0);
      expect(sessionController.errorSessionCount, 0);
    });

    test('AppSettingsController manages font and theme settings correctly', () {
      final settingsController = AppSettingsController();
      
      // Test initial state
      expect(settingsController.fontSettings.fontFamily, 'Roboto');
      expect(settingsController.fontSettings.fontSize, 14.0);
      expect(settingsController.fontSettings.terminalFontSize, 14.0);
      expect(settingsController.fontSettings.fontWeight, FontWeight.normal);
      
      expect(settingsController.themeSettings.themeMode, AppThemeMode.system);
      expect(settingsController.themeSettings.useSystemAccentColor, true);
      
      expect(settingsController.isInitialized, false);
    });

    test('FontSettings model works correctly', () {
      const fontSettings = FontSettings(
        fontFamily: 'Arial',
        fontSize: 16.0,
        terminalFontSize: 14.0,
        fontWeight: FontWeight.bold,
      );
      
      // Test properties
      expect(fontSettings.fontFamily, 'Arial');
      expect(fontSettings.fontSize, 16.0);
      expect(fontSettings.terminalFontSize, 14.0);
      expect(fontSettings.fontWeight, FontWeight.bold);
      
      // Test copyWith
      final modifiedSettings = fontSettings.copyWith(fontSize: 18.0);
      expect(modifiedSettings.fontFamily, 'Arial');
      expect(modifiedSettings.fontSize, 18.0);
      expect(modifiedSettings.terminalFontSize, 14.0);
      expect(modifiedSettings.fontWeight, FontWeight.bold);
      
      // Test copyWith validation (clamps extreme values)
      final extremeSettings = fontSettings.copyWith(fontSize: 0.0, terminalFontSize: 100.0);
      expect(extremeSettings.fontSize, 8.0); // Clamped to minimum
      expect(extremeSettings.terminalFontSize, 50.0); // Clamped to maximum
      
      // Test toMap and fromMap
      final map = fontSettings.toMap();
      final fromMapSettings = FontSettings.fromMap(map);
      expect(fromMapSettings.fontFamily, fontSettings.fontFamily);
      expect(fromMapSettings.fontSize, fontSettings.fontSize);
      expect(fromMapSettings.terminalFontSize, fontSettings.terminalFontSize);
      expect(fromMapSettings.fontWeight, fontSettings.fontWeight);
      
      // Test fromMap validation with extreme values
      final extremeMap = {'fontSize': -5.0, 'terminalFontSize': 200.0, 'fontWeight': -1};
      final validatedSettings = FontSettings.fromMap(extremeMap);
      expect(validatedSettings.fontSize, 8.0); // Clamped to minimum
      expect(validatedSettings.terminalFontSize, 50.0); // Clamped to maximum
      expect(validatedSettings.fontWeight, FontWeight.normal); // Clamped to valid range
    });

    test('ThemeSettings model works correctly', () {
      const themeSettings = ThemeSettings(
        themeMode: AppThemeMode.dark,
        useSystemAccentColor: false,
      );
      
      // Test properties
      expect(themeSettings.themeMode, AppThemeMode.dark);
      expect(themeSettings.useSystemAccentColor, false);
      
      // Test copyWith
      final modifiedSettings = themeSettings.copyWith(themeMode: AppThemeMode.light);
      expect(modifiedSettings.themeMode, AppThemeMode.light);
      expect(modifiedSettings.useSystemAccentColor, false);
      
      // Test toMap and fromMap
      final map = themeSettings.toMap();
      final fromMapSettings = ThemeSettings.fromMap(map);
      expect(fromMapSettings.themeMode, themeSettings.themeMode);
      expect(fromMapSettings.useSystemAccentColor, themeSettings.useSystemAccentColor);
    });
  });

  testWidgets('SSH Client app builds without crashing', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => SshController()),
          ChangeNotifierProvider(create: (context) => SshSessionController()),
          ChangeNotifierProvider(create: (context) => SshTabController()),
          ChangeNotifierProvider(create: (context) => FileTransferController()),
        ],
        child: const MyApp(),
      ),
    );

    // Just pump once to ensure it builds
    await tester.pump();

    // Basic verification that the app builds
    expect(tester.allWidgets.any((widget) => widget is MaterialApp), true);
  });
}
