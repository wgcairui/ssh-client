import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../controllers/ssh_tab_controller.dart';
import '../controllers/ssh_session_controller.dart';
import '../models/ssh_tab.dart';
import '../services/ssh_service.dart';

/// SSH 标签页栏组件
class SshTabBar extends StatefulWidget {
  final VoidCallback? onAddTab;
  
  const SshTabBar({
    super.key,
    this.onAddTab,
  });

  @override
  State<SshTabBar> createState() => _SshTabBarState();
}

class _SshTabBarState extends State<SshTabBar> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SshTabController>(
      builder: (context, tabController, child) {
        if (tabController.tabs.isEmpty) {
          return _buildEmptyTabBar();
        }

        return Container(
          height: 48.h,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // 标签页列表
              Expanded(
                child: _buildTabList(tabController),
              ),
              // 添加按钮
              _buildAddButton(tabController),
            ],
          ),
        );
      },
    );
  }

  /// 构建空标签页栏
  Widget _buildEmptyTabBar() {
    return Container(
      height: 48.h,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Text(
              '暂无连接',
              style: TextStyle(
                fontSize: 21.sp,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const Spacer(),
          _buildAddButton(context.read<SshTabController>()),
        ],
      ),
    );
  }

  /// 构建标签页列表
  Widget _buildTabList(SshTabController tabController) {
    return Scrollbar(
      controller: _scrollController,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: tabController.tabs.length,
        itemBuilder: (context, index) {
          final tab = tabController.tabs[index];
          return _buildTabItem(tab, index, tabController);
        },
      ),
    );
  }

  /// 构建单个标签页
  Widget _buildTabItem(SshTab tab, int index, SshTabController tabController) {
    final isActive = tab.isActive;
    final sessionController = context.watch<SshSessionController>();
    
    // 获取连接状态
    SshConnectionStatus? status;
    final sessions = sessionController.sessions;
    for (var sessionId in sessions.keys) {
      final session = sessions[sessionId];
      if (session != null && session.connection.id == tab.connectionId) {
        status = session.status;
        break;
      }
    }

    // 计算标签页宽度 - 根据标签页数量动态调整
    double tabWidth = _calculateTabWidth(tabController.tabs.length);

    return GestureDetector(
      onTap: () => tabController.switchToTab(index),
      child: Container(
        width: tabWidth,
        height: 48.h,
        decoration: BoxDecoration(
          color: isActive 
              ? Theme.of(context).colorScheme.surfaceContainerHighest
              : Theme.of(context).colorScheme.surface,
          border: Border(
            right: BorderSide(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
            bottom: isActive 
                ? BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  )
                : BorderSide.none,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Row(
            children: [
              // 连接状态指示器
              _buildStatusIndicator(status),
              SizedBox(width: 8.w),
              // 标签页标题
              Expanded(
                child: Tooltip(
                  message: '${tab.fullTitle}\n${tab.connectionInfo}',
                  child: Text(
                    tab.title,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
                      color: isActive 
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              // 关闭按钮
              GestureDetector(
                onTap: () => _closeTab(tab.id, tabController),
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  child: Icon(
                    Icons.close,
                    size: 21.sp,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 计算标签页宽度
  double _calculateTabWidth(int tabCount) {
    // 可用宽度 = 屏幕宽度 - 添加按钮宽度 - 边距
    final availableWidth = ScreenUtil().screenWidth - 60.w - 32.w;
    
    // 最小宽度和最大宽度
    const minWidth = 120.0;
    const maxWidth = 200.0;
    
    if (tabCount == 0) return maxWidth;
    
    // 根据标签页数量计算宽度
    double calculatedWidth = availableWidth / tabCount;
    
    // 限制在最小和最大宽度之间
    return calculatedWidth.clamp(minWidth, maxWidth);
  }

  /// 构建连接状态指示器
  Widget _buildStatusIndicator(SshConnectionStatus? status) {
    Color color;
    IconData icon;
    
    switch (status) {
      case SshConnectionStatus.connected:
      case SshConnectionStatus.authenticated:
        color = Colors.green;
        icon = Icons.circle;
        break;
      case SshConnectionStatus.connecting:
      case SshConnectionStatus.authenticating:
        color = Colors.orange;
        icon = Icons.circle;
        break;
      case SshConnectionStatus.error:
        color = Colors.red;
        icon = Icons.circle;
        break;
      case SshConnectionStatus.disconnected:
      default:
        color = Colors.grey;
        icon = Icons.circle_outlined;
        break;
    }
    
    return Icon(
      icon,
      size: 12.sp,
      color: color,
    );
  }

  /// 构建添加按钮
  Widget _buildAddButton(SshTabController tabController) {
    final canAddTab = !tabController.isMaxTabsReached;
    
    return Container(
      width: 48.w,
      height: 48.h,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: IconButton(
        onPressed: canAddTab ? widget.onAddTab : null,
        icon: Icon(
          Icons.add,
          size: 30.sp,
          color: canAddTab 
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
        tooltip: canAddTab ? '添加连接' : '已达到最大连接数 (${SshTabController.maxTabs})',
      ),
    );
  }

  /// 关闭标签页
  void _closeTab(String tabId, SshTabController tabController) async {
    // 获取连接ID
    final connectionId = tabController.getConnectionId(tabId);
    
    // 关闭SSH会话
    if (connectionId != null) {
      final sessionController = context.read<SshSessionController>();
      final sessions = sessionController.sessions;
      
      // 查找并关闭对应的会话
      String? sessionIdToClose;
      for (var sessionId in sessions.keys) {
        final session = sessions[sessionId];
        if (session != null && session.connection.id == connectionId) {
          sessionIdToClose = sessionId;
          break;
        }
      }
      
      if (sessionIdToClose != null) {
        await sessionController.closeSession(sessionIdToClose);
      }
    }
    
    // 关闭标签页
    tabController.closeTab(tabId);
  }
}