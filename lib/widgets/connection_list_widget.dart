import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../controllers/ssh_controller.dart';
import '../controllers/app_settings_controller.dart';
import '../models/ssh_connection.dart';
import '../views/add_connection_view.dart';
import 'connection_item_widget.dart';

/// 连接列表组件 - 针对 OPPO Pad 4 Pro 优化
class ConnectionListWidget extends StatefulWidget {
  final Function(String) onConnectionSelected;
  final String? selectedConnectionId;
  final TextEditingController searchController;

  const ConnectionListWidget({
    super.key,
    required this.onConnectionSelected,
    this.selectedConnectionId,
    required this.searchController,
  });

  @override
  State<ConnectionListWidget> createState() => _ConnectionListWidgetState();
}

class _ConnectionListWidgetState extends State<ConnectionListWidget> {
  List<SshConnection> _filteredConnections = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    widget.searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_onSearchChanged);
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _isSearching = widget.searchController.text.isNotEmpty;
    });
    if (_isSearching) {
      _performSearch();
    }
  }

  Future<void> _performSearch() async {
    final controller = context.read<SshController>();
    final results = await controller.searchConnections(widget.searchController.text);
    if (mounted) {
      setState(() {
        _filteredConnections = results;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SshController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (controller.error != null) {
          return _buildErrorWidget(controller.error!);
        }

        final connections = _isSearching ? _filteredConnections : controller.connections;

        if (connections.isEmpty) {
          return _buildEmptyWidget();
        }

        return _buildConnectionsList(connections);
      },
    );
  }

  /// 构建连接列表
  Widget _buildConnectionsList(List<SshConnection> connections) {
    return ListView.separated(
      padding: EdgeInsets.all(8.w),
      itemCount: connections.length,
      separatorBuilder: (context, index) => SizedBox(height: 4.h),
      itemBuilder: (context, index) {
        final connection = connections[index];
        return ConnectionItemWidget(
          connection: connection,
          isSelected: connection.id == widget.selectedConnectionId,
          onTap: () => widget.onConnectionSelected(connection.id),
          onEdit: () => _editConnection(connection),
          onDelete: () => _deleteConnection(connection),
          onDuplicate: () => _duplicateConnection(connection),
        );
      },
    );
  }

  /// 构建空列表提示
  Widget _buildEmptyWidget() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Consumer<AppSettingsController>(
              builder: (context, settings, child) => Icon(
                _isSearching ? Icons.search_off : Icons.cloud_off,
                size: settings.getIconSize(72),
                color: Theme.of(context).disabledColor,
              ),
            ),
            SizedBox(height: 16.h),
            Consumer<AppSettingsController>(
              builder: (context, settings, child) => Text(
                _isSearching ? '未找到匹配的连接' : '暂无 SSH 连接',
                style: settings.getSidebarTextStyle(
                  color: Theme.of(context).disabledColor,
                  customSize: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建错误提示
  Widget _buildErrorWidget(String error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Consumer<AppSettingsController>(
              builder: (context, settings, child) => Icon(
                Icons.error_outline,
                size: settings.getIconSize(72),
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            SizedBox(height: 16.h),
            Consumer<AppSettingsController>(
              builder: (context, settings, child) => Text(
                error,
                style: settings.getSidebarTextStyle(
                  color: Theme.of(context).colorScheme.error,
                  customSize: 21,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () {
                context.read<SshController>().loadConnections();
              },
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  /// 编辑连接
  void _editConnection(SshConnection connection) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddConnectionView(connection: connection),
      ),
    );
  }

  /// 删除连接
  void _deleteConnection(SshConnection connection) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除连接'),
        content: Text('确定要删除连接 "${connection.name}" 吗？\n此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              final controller = context.read<SshController>();
              
              navigator.pop();
              final success = await controller.deleteConnection(connection.id);
              if (mounted && success) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('连接已删除')),
                );
                // 如果删除的是当前选中的连接，清空选择
                if (connection.id == widget.selectedConnectionId) {
                  widget.onConnectionSelected('');
                }
              }
            },
            child: Text(
              '删除',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  /// 复制连接
  void _duplicateConnection(SshConnection connection) async {
    final success = await context.read<SshController>().duplicateConnection(connection);
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('连接已复制')),
      );
    }
  }
}