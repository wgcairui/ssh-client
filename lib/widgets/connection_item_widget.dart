import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/ssh_connection.dart';
import '../controllers/app_settings_controller.dart';

/// 连接项组件 - 针对 OPPO Pad 4 Pro 优化
class ConnectionItemWidget extends StatelessWidget {
  final SshConnection connection;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;

  const ConnectionItemWidget({
    super.key,
    required this.connection,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<AppSettingsController>(
      builder: (context, settings, child) {
        return Card(
          elevation: isSelected ? 8 : 2,
          shadowColor:
              isSelected ? colorScheme.primary.withValues(alpha: 0.3) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
            side: isSelected
                ? BorderSide(
                    color: colorScheme.primary,
                    width: 2,
                  )
                : BorderSide.none,
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12.r),
            child: Container(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // 连接图标
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primary.withValues(alpha: 0.1)
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Consumer<AppSettingsController>(
                          builder: (context, settings, child) => Icon(
                            Icons.computer,
                            size: settings.getIconSize(30),
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      // 连接信息
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              connection.name,
                              style: settings.getSidebarTextStyle(
                                customSize: 24,
                                customWeight: FontWeight.w600,
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              connection.connectionString,
                              style: settings.getSidebarTextStyle(
                                customSize: 18,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // 菜单按钮
                      PopupMenuButton<String>(
                        icon: Consumer<AppSettingsController>(
                          builder: (context, settings, child) => Icon(
                            Icons.more_vert,
                            size: settings.getIconSize(30),
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(Icons.edit, size: 18),
                                SizedBox(width: 8.w),
                                const Text('编辑'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'duplicate',
                            child: Row(
                              children: [
                                const Icon(Icons.copy, size: 18),
                                SizedBox(width: 8.w),
                                const Text('复制'),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'file_transfer',
                            child: Row(
                              children: [
                                const Icon(Icons.folder_open, size: 18),
                                SizedBox(width: 8.w),
                                const Text('文件传输'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'disconnect',
                            child: Row(
                              children: [
                                const Icon(Icons.link_off, size: 18),
                                SizedBox(width: 8.w),
                                const Text('断开连接'),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete,
                                    size: 18, color: colorScheme.error),
                                SizedBox(width: 8.w),
                                Text('删除',
                                    style: TextStyle(color: colorScheme.error)),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              onEdit();
                              break;
                            case 'duplicate':
                              onDuplicate();
                              break;
                            case 'file_transfer':
                              _showFileTransferDialog();
                              break;
                            case 'disconnect':
                              _handleDisconnect();
                              break;
                            case 'delete':
                              onDelete();
                              break;
                          }
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  // 连接详细信息
                  Row(
                    children: [
                      _buildInfoChip(
                        icon: connection.useKeyAuth ? Icons.key : Icons.lock,
                        label: connection.useKeyAuth ? '密钥认证' : '密码认证',
                        context: context,
                      ),
                      SizedBox(width: 8.w),
                      _buildInfoChip(
                        icon: Icons.access_time,
                        label: _formatLastUsed(connection.lastUsedAt),
                        context: context,
                      ),
                    ],
                  ),
                  if (connection.description?.isNotEmpty == true) ...[
                    SizedBox(height: 8.h),
                    Text(
                      connection.description!,
                      style: settings.getSidebarTextStyle(
                        color: colorScheme.onSurfaceVariant,
                        customSize: 18,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建信息标签
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required BuildContext context,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Consumer<AppSettingsController>(
            builder: (context, settings, child) => Icon(
              icon,
              size: settings.getIconSize(18),
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(width: 4.w),
          Consumer<AppSettingsController>(
            builder: (context, settings, child) => Text(
              label,
              style: settings.getSidebarTextStyle(
                color: colorScheme.onSurfaceVariant,
                customSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 格式化最后使用时间
  String _formatLastUsed(DateTime lastUsed) {
    final now = DateTime.now();
    final difference = now.difference(lastUsed);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return DateFormat('MM/dd').format(lastUsed);
    }
  }

  /// 显示文件传输对话框
  void _showFileTransferDialog() {
    // TODO: 实现文件传输功能
    // 这里可以显示一个对话框或导航到文件传输页面
    // print('打开文件传输: ${connection.name}');
  }

  /// 处理断开连接
  void _handleDisconnect() {
    // TODO: 实现断开连接功能
    // 这里需要调用SSH会话控制器来断开指定连接
    // print('断开连接: ${connection.name}');
  }
}
