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
