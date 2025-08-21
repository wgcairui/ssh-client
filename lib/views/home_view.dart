import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../controllers/ssh_controller.dart';
import '../widgets/connection_list_widget.dart';
import '../widgets/terminal_widget.dart';
import 'add_connection_view.dart';

/// 主界面 - 专为平板优化的分屏布局
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  String? _selectedConnectionId;
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
          width: _isLeftPanelCollapsed ? 60.w : 380.w,
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
                    onConnectionSelected: (connectionId) {
                      setState(() {
                        _selectedConnectionId = connectionId;
                      });
                    },
                    selectedConnectionId: _selectedConnectionId,
                    searchController: _searchController,
                  ),
                ),
            ],
          ),
        ),
        // 右侧终端面板
        Expanded(
          child: _selectedConnectionId != null
              ? TerminalWidget(connectionId: _selectedConnectionId!)
              : _buildWelcomePanel(),
        ),
      ],
    );
  }

  /// 手机布局（堆叠模式）
  Widget _buildMobileLayout() {
    if (_selectedConnectionId != null) {
      return TerminalWidget(
        connectionId: _selectedConnectionId!,
        onClose: () {
          setState(() {
            _selectedConnectionId = null;
          });
        },
      );
    }

    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: ConnectionListWidget(
            onConnectionSelected: (connectionId) {
              setState(() {
                _selectedConnectionId = connectionId;
              });
            },
            selectedConnectionId: _selectedConnectionId,
            searchController: _searchController,
          ),
        ),
      ],
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
                size: 30.sp,
              ),
              tooltip: '展开面板',
            ),
            SizedBox(height: 8.h),
            IconButton(
              onPressed: _addNewConnection,
              icon: const Icon(Icons.add),
              tooltip: '添加连接',
              iconSize: 18.sp,
            ),
            SizedBox(height: 8.h),
            Consumer<SshController>(
              builder: (context, controller, child) {
                return Text(
                  '${controller.connections.length}',
                  style: TextStyle(
                    fontSize: 15.sp,
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
                IconButton(
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
                  tooltip: '折叠面板',
                ),
                Icon(
                  Icons.terminal,
                  size: 36.sp,
                  color: Theme.of(context).primaryColor,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'SSH 客户端',
                    style: TextStyle(
                      fontSize: 30.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isSearching = true;
                    });
                  },
                  icon: const Icon(Icons.search),
                  tooltip: '搜索连接',
                ),
                IconButton(
                  onPressed: _addNewConnection,
                  icon: const Icon(Icons.add),
                  tooltip: '添加连接',
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
                  onPressed: _addNewConnection,
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
          SizedBox(height: 16.h),
          ElevatedButton.icon(
            onPressed: _addNewConnection,
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

  /// 添加新连接
  void _addNewConnection() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddConnectionView(),
      ),
    );
  }
}