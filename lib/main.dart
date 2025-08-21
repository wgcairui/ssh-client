import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'controllers/ssh_controller.dart';
import 'controllers/ssh_session_controller.dart';
import 'controllers/ssh_tab_controller.dart';
import 'controllers/file_transfer_controller.dart';
import 'controllers/update_controller.dart';
import 'controllers/app_settings_controller.dart';
import 'models/theme_settings.dart' as app_theme;
import 'views/home_view_with_tabs.dart';

void main() async {
  // 确保Flutter绑定初始化
  WidgetsFlutterBinding.ensureInitialized();
  
  // 强制横屏模式 - 针对平板优化
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppSettingsController _settingsController;

  @override
  void initState() {
    super.initState();
    _settingsController = AppSettingsController();
    _settingsController.initialize();
  }

  @override
  void dispose() {
    _settingsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _settingsController,
      child: Consumer<AppSettingsController>(
        builder: (context, settingsController, child) {
          // Show loading screen until settings are initialized
          if (!settingsController.isInitialized) {
            return const MaterialApp(
              home: Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            );
          }
          
          return ScreenUtilInit(
            designSize: const Size(3392, 2400), // OPPO Pad 4 Pro 分辨率优化 (7:5)
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (context, child) {
              return MultiProvider(
                providers: [
                  ChangeNotifierProvider(create: (context) => SshController()),
                  ChangeNotifierProvider(create: (context) => SshSessionController()),
                  ChangeNotifierProvider(create: (context) => SshTabController()),
                  ChangeNotifierProvider(create: (context) => FileTransferController()),
                  ChangeNotifierProvider(create: (context) => UpdateController()),
                ],
                child: MaterialApp(
                  title: 'SSH 客户端',
                  debugShowCheckedModeBanner: false,
                  theme: settingsController.getLightTheme(),
                  darkTheme: settingsController.getDarkTheme(),
                  themeMode: settingsController.themeSettings.themeMode == app_theme.AppThemeMode.system 
                      ? ThemeMode.system
                      : settingsController.themeSettings.themeMode == app_theme.AppThemeMode.light
                          ? ThemeMode.light
                          : ThemeMode.dark,
                  home: const HomeViewWithTabs(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}