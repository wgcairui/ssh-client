import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/app_settings_controller.dart';
import '../models/font_settings.dart';
import '../models/theme_settings.dart';

/// 应用设置页面
class AppSettingsView extends StatefulWidget {
  const AppSettingsView({super.key});

  @override
  State<AppSettingsView> createState() => _AppSettingsViewState();
}

class _AppSettingsViewState extends State<AppSettingsView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('应用设置'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'reset') {
                final confirmed = await _showResetDialog();
                if (confirmed && context.mounted) {
                  await context.read<AppSettingsController>().resetToDefaults();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已重置为默认设置')),
                    );
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.restore),
                    SizedBox(width: 8),
                    Text('重置设置'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<AppSettingsController>(
        builder: (context, controller, child) {
          if (!controller.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildThemeSection(context, controller),
                const SizedBox(height: 24),
                _buildFontSection(context, controller),
                const SizedBox(height: 24),
                _buildTerminalSection(context, controller),
                const SizedBox(height: 24),
                _buildPreviewSection(context, controller),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 构建主题设置部分
  Widget _buildThemeSection(BuildContext context, AppSettingsController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.palette,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '主题设置',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '主题模式',
                    style: controller.getTextStyle(),
                  ),
                ),
                DropdownButton<AppThemeMode>(
                  value: controller.themeSettings.themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      controller.updateThemeMode(value);
                    }
                  },
                  items: AppThemeMode.values.map((mode) {
                    return DropdownMenuItem(
                      value: mode,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(mode.icon, size: 16),
                          const SizedBox(width: 8),
                          Text(mode.displayName),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '当前模式',
                    style: controller.getTextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Chip(
                  avatar: Icon(
                    controller.isDarkMode ? Icons.brightness_2 : Icons.brightness_high,
                    size: 16,
                  ),
                  label: Text(controller.isDarkMode ? '深色' : '浅色'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建字体设置部分
  Widget _buildFontSection(BuildContext context, AppSettingsController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.font_download,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '字体设置',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 字体家族选择
            Row(
              children: [
                Expanded(
                  child: Text(
                    '字体家族',
                    style: controller.getTextStyle(),
                  ),
                ),
                DropdownButton<String>(
                  value: controller.fontSettings.fontFamily,
                  onChanged: (value) {
                    if (value != null) {
                      controller.updateFontFamily(value);
                    }
                  },
                  items: FontOptions.availableFonts.map((font) {
                    return DropdownMenuItem(
                      value: font,
                      child: Text(
                        font,
                        style: TextStyle(fontFamily: font == 'System Default' ? null : font),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 字体大小滑块
            Text('UI字体大小: ${controller.fontSettings.fontSize.toStringAsFixed(0)}', 
                 style: controller.getTextStyle()),
            Slider(
              value: controller.fontSettings.fontSize,
              min: FontOptions.availableFontSizes.first,
              max: FontOptions.availableFontSizes.last,
              divisions: FontOptions.availableFontSizes.length - 1,
              label: controller.fontSettings.fontSize.toStringAsFixed(0),
              onChanged: (value) {
                controller.updateFontSize(value);
              },
            ),
            const SizedBox(height: 16),
            
            // 字体权重选择
            Row(
              children: [
                Expanded(
                  child: Text(
                    '字体权重',
                    style: controller.getTextStyle(),
                  ),
                ),
                DropdownButton<FontWeight>(
                  value: controller.fontSettings.fontWeight,
                  onChanged: (value) {
                    if (value != null) {
                      controller.updateFontWeight(value);
                    }
                  },
                  items: FontOptions.availableFontWeights.map((weight) {
                    return DropdownMenuItem(
                      value: weight,
                      child: Text(
                        FontOptions.getFontWeightName(weight),
                        style: TextStyle(fontWeight: weight),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建终端设置部分
  Widget _buildTerminalSection(BuildContext context, AppSettingsController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.terminal,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '终端设置',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 终端字体大小滑块
            Text('终端字体大小: ${controller.fontSettings.terminalFontSize.toStringAsFixed(0)}',
                 style: controller.getTextStyle()),
            Slider(
              value: controller.fontSettings.terminalFontSize,
              min: FontOptions.availableFontSizes.first,
              max: FontOptions.availableFontSizes.last,
              divisions: FontOptions.availableFontSizes.length - 1,
              label: controller.fontSettings.terminalFontSize.toStringAsFixed(0),
              onChanged: (value) {
                controller.updateTerminalFontSize(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 构建预览部分
  Widget _buildPreviewSection(BuildContext context, AppSettingsController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.preview,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '预览效果',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // UI字体预览
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'UI字体预览',
                    style: controller.getTextStyle(
                      customWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '这是使用当前设置的普通文字示例。The quick brown fox jumps over the lazy dog.',
                    style: controller.getTextStyle(),
                  ),
                  Text(
                    '字体: ${controller.fontSettings.fontFamily}, 大小: ${controller.fontSettings.fontSize}px',
                    style: controller.getTextStyle(
                      customSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // 终端字体预览
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: controller.getTerminalThemeConfig().backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '终端字体预览',
                    style: controller.getTerminalTextStyle(
                      color: controller.getTerminalThemeConfig().foregroundColor,
                    ).copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'user@hostname:~\$ ls -la\ntotal 1024\ndrwxr-xr-x 10 user user 4096 Jan 01 12:00 .\ndrwxr-xr-x  3 user user 4096 Jan 01 11:00 ..\n-rw-r--r--  1 user user  220 Jan 01 12:00 example.txt',
                    style: controller.getTerminalTextStyle(
                      color: controller.getTerminalThemeConfig().foregroundColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '终端字体大小: ${controller.fontSettings.terminalFontSize}px',
                    style: controller.getTerminalTextStyle(
                      color: controller.getTerminalThemeConfig().commentColor,
                    ).copyWith(fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示重置确认对话框
  Future<bool> _showResetDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('确认重置'),
          content: const Text('确定要将所有设置重置为默认值吗？此操作不可撤销。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('重置'),
            ),
          ],
        );
      },
    ) ?? false;
  }
}