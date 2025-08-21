import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../controllers/ssh_controller.dart';
import '../controllers/ssh_tab_controller.dart';
import '../widgets/connection_list_widget.dart';
import '../widgets/ssh_tab_bar.dart';
import '../widgets/single_terminal_manager.dart';
import 'add_connection_view.dart';
import 'update_settings_view.dart';

/// 支持多标签页的主界面
class HomeViewWithTabs extends StatefulWidget {
  const HomeViewWithTabs({super.key});

  @override
  State<HomeViewWithTabs> createState() => _HomeViewWithTabsState();
}

class _HomeViewWithTabsState extends State<HomeViewWithTabs> {
  bool _isSearching = false;
  bool _isLeftPanelCollapsed = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SshController>().initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _buildResponsiveLayout(),
      ),
    );
  }

  /// 构建响应式布局
  Widget _buildResponsiveLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 平板横屏模式：使用分屏布局
        if (constraints.maxWidth > 600) {
          return _buildTabletLayout();
        }
        // 手机或平板竖屏模式：使用堆叠布局
        else {
          return _buildMobileLayout();
        }
      },
    );
  }

  /// 平板分屏布局
  Widget _buildTabletLayout() {
    return Row(
      children: [
        // 左侧连接列表面板
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: _isLeftPanelCollapsed ? 80.w : 480.w,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              _buildCollapsibleHeader(),
              if (!_isLeftPanelCollapsed)
                Expanded(
                  child: ConnectionListWidget(
                    onConnectionSelected: _handleConnectionSelected,
                    selectedConnectionId: null, // 不再需要单选状态
                    searchController: _searchController,
                  ),
                ),
            ],
          ),
        ),
        // 右侧标签页和终端面板
        Expanded(
          child: _buildTerminalArea(),
        ),
      ],
    );
  }

  /// 手机布局（堆叠模式）
  Widget _buildMobileLayout() {
    final tabController = context.watch<SshTabController>();
    
    if (tabController.activeTab != null) {
      return _buildTerminalArea();
    }

    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: ConnectionListWidget(
            onConnectionSelected: _handleConnectionSelected,
            selectedConnectionId: null,
            searchController: _searchController,
          ),
        ),
      ],
    );
  }

  /// 构建终端区域
  Widget _buildTerminalArea() {
    return Consumer<SshTabController>(
      builder: (context, tabController, child) {
        return Column(
          children: [
            // 标签页栏
            SshTabBar(
              onAddTab: _showAddConnectionDialog,
            ),
            // 终端内容
            Expanded(
              child: tabController.tabs.isNotEmpty
                  ? _buildSingleTerminalManager(tabController)
                  : _buildWelcomePanel(),
            ),
          ],
        );
      },
    );
  }

  /// 构建单终端管理器
  Widget _buildSingleTerminalManager(SshTabController tabController) {
    return SingleTerminalManager(
      tabs: tabController.tabs,
      activeTabIndex: tabController.activeTabIndex,
    );
  }

  /// 处理连接选择
  void _handleConnectionSelected(String connectionId) async {
    final sshController = context.read<SshController>();
    final tabController = context.read<SshTabController>();
    
    // 获取连接信息
    final connection = await sshController.getConnection(connectionId);
    if (connection == null) return;

    // 检查是否已达到最大标签页数量
    if (tabController.isMaxTabsReached && !tabController.isConnectionOpen(connectionId)) {
      _showMaxTabsDialog();
      return;
    }

    // 添加或切换到标签页
    final tabId = tabController.addTab(connection);
    if (tabId == null) {
      _showMaxTabsDialog();
    }
  }

  /// 显示最大标签页数量提示
  void _showMaxTabsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('达到最大连接数'),
        content: Text('最多只能同时打开 ${SshTabController.maxTabs} 个连接。请关闭一些连接后再试。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示添加连接对话框
  void _showAddConnectionDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddConnectionView(),
      ),
    );
  }

  /// 构建可折叠的顶部标题栏
  Widget _buildCollapsibleHeader() {
    if (_isLeftPanelCollapsed) {
      // 折叠状态：仅显示菜单按钮和简化信息
      return Container(
        padding: EdgeInsets.all(8.w),
        child: Column(
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  _isLeftPanelCollapsed = false;
                });
              },
              icon: Icon(
                Icons.menu,
                size: 36.sp,
              ),
              tooltip: '展开面板',
            ),
            SizedBox(height: 8.h),
            IconButton(
              onPressed: _showAddConnectionDialog,
              icon: const Icon(Icons.add),
              tooltip: '添加连接',
              iconSize: 24.sp,
            ),
            SizedBox(height: 8.h),
            Consumer<SshController>(
              builder: (context, controller, child) {
                return Text(
                  '${controller.connections.length}',
                  style: TextStyle(
                    fontSize: 21.sp,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                );
              },
            ),
          ],
        ),
      );
    }

    // 展开状态：显示完整标题栏
    return Container(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          if (!_isSearching) ...[ 
            Row(
              children: [
                Expanded(
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        _isLeftPanelCollapsed = true;
                        if (_isSearching) {
                          _isSearching = false;
                          _searchController.clear();
                        }
                      });
                    },
                    icon: Icon(
                      Icons.menu_open,
                      size: 30.sp,
                    ),
                    iconSize: 20.sp,
                    tooltip: '折叠面板',
                  ),
                ),
                if (MediaQuery.of(context).size.width > 200) ...[
                  Icon(
                    Icons.terminal,
                    size: 30.sp,
                    color: Theme.of(context).primaryColor,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'SSH',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                Expanded(
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        _isSearching = true;
                      });
                    },
                    icon: Icon(Icons.search, size: 30.sp),
                    iconSize: 20.sp,
                    tooltip: '搜索连接',
                  ),
                ),
                Expanded(
                  child: IconButton(
                    onPressed: _showAddConnectionDialog,
                    icon: Icon(Icons.add, size: 30.sp),
                    iconSize: 20.sp,
                    tooltip: '添加连接',
                  ),
                ),
                Expanded(
                  child: IconButton(
                    onPressed: _showSettingsMenu,
                    icon: Icon(Icons.more_vert, size: 30.sp),
                    iconSize: 20.sp,
                    tooltip: '设置',
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isLeftPanelCollapsed = true;
                      _isSearching = false;
                      _searchController.clear();
                    });
                  },
                  icon: Icon(
                    Icons.menu_open,
                    size: 30.sp,
                  ),
                  tooltip: '折叠面板',
                ),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: '搜索连接...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isSearching = false;
                      _searchController.clear();
                    });
                  },
                  icon: const Icon(Icons.close),
                  tooltip: '取消搜索',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 构建顶部标题栏（手机布局用）
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          Row(
            children: [
              if (!_isSearching) ...[
                Icon(
                  Icons.terminal,
                  size: 36.sp,
                  color: Theme.of(context).primaryColor,
                ),
                SizedBox(width: 12.w),
                Text(
                  'SSH 客户端',
                  style: TextStyle(
                    fontSize: 30.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isSearching = true;
                    });
                  },
                  icon: const Icon(Icons.search),
                ),
                IconButton(
                  onPressed: _showAddConnectionDialog,
                  icon: const Icon(Icons.add),
                ),
              ] else ...[
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: '搜索连接...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isSearching = false;
                      _searchController.clear();
                    });
                  },
                  icon: const Icon(Icons.close),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// 构建欢迎面板
  Widget _buildWelcomePanel() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.terminal,
            size: 120.sp,
            color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
          ),
          SizedBox(height: 24.h),
          Text(
            '选择一个连接开始使用',
            style: TextStyle(
              fontSize: 27.sp,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '最多支持 ${SshTabController.maxTabs} 个同时连接',
            style: TextStyle(
              fontSize: 21.sp,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
            ),
          ),
          SizedBox(height: 16.h),
          ElevatedButton.icon(
            onPressed: _showAddConnectionDialog,
            icon: const Icon(Icons.add),
            label: const Text('添加新连接'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            ),
          ),
        ],
      ),
    );
  }

  /// 显示设置菜单
  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.system_update),
                title: const Text('自动更新设置'),
                subtitle: const Text('检查更新和下载设置'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const UpdateSettingsView(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('关于应用'),
                subtitle: const Text('版本信息和帮助'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showAboutDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// 显示关于对话框
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.terminal,
              color: Theme.of(context).primaryColor,
              size: 36.sp,
            ),
            SizedBox(width: 8.w),
            const Text('SSH 客户端'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '一个现代化的 SSH 客户端应用',
              style: TextStyle(fontSize: 21.sp),
            ),
            SizedBox(height: 8.h),
            Text(
              '专为平板优化，支持多标签页连接',
              style: TextStyle(fontSize: 18.sp),
            ),
            SizedBox(height: 16.h),
            Text(
              '版本：1.0.3',
              style: TextStyle(
                fontSize: 18.sp,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}