import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:xterm/xterm.dart';
import '../controllers/ssh_controller.dart';
import '../controllers/ssh_session_controller.dart';
import '../models/ssh_tab.dart';
import '../models/ssh_connection.dart';
import '../services/ssh_service.dart';
import '../views/file_transfer_view.dart';

/// 单终端管理器 - 使用单个TerminalView管理多个终端状态
class SingleTerminalManager extends StatefulWidget {
  final List<SshTab> tabs;
  final int activeTabIndex;

  const SingleTerminalManager({
    super.key,
    required this.tabs,
    required this.activeTabIndex,
  });

  @override
  State<SingleTerminalManager> createState() => _SingleTerminalManagerState();
}

class _SingleTerminalManagerState extends State<SingleTerminalManager> {
  // 单个TerminalView实例
  Terminal? _currentTerminal;
  
  // 每个Tab的终端状态存储
  final Map<String, _TabTerminalState> _tabStates = {};
  
  // 当前活跃的Tab ID
  String? _currentActiveTabId;

  @override
  void initState() {
    super.initState();
    _initializeManager();
  }

  @override
  void didUpdateWidget(SingleTerminalManager oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 检查Tab列表变化
    _syncTabStates();
    
    // 检查活跃Tab变化
    if (oldWidget.activeTabIndex != widget.activeTabIndex) {
      _switchToActiveTab();
    }
  }

  @override
  void dispose() {
    _cleanupAllStates();
    super.dispose();
  }

  /// 初始化管理器
  void _initializeManager() {
    _syncTabStates();
    _switchToActiveTab();
  }

  /// 同步Tab状态
  void _syncTabStates() {
    // 移除不存在的Tab状态
    final currentTabIds = widget.tabs.map((tab) => tab.id).toSet();
    _tabStates.removeWhere((tabId, state) {
      if (!currentTabIds.contains(tabId)) {
        state.dispose();
        return true;
      }
      return false;
    });

    // 为新Tab创建状态
    for (final tab in widget.tabs) {
      if (!_tabStates.containsKey(tab.id)) {
        _createTabState(tab);
      }
    }
  }

  /// 创建Tab终端状态
  void _createTabState(SshTab tab) {
    final state = _TabTerminalState(
      tabId: tab.id,
      connectionId: tab.connectionId,
      connection: tab.connection,
    );

    _tabStates[tab.id] = state;
    
    // 异步初始化连接
    _initializeTabConnection(state);
  }

  /// 初始化Tab连接
  Future<void> _initializeTabConnection(_TabTerminalState state) async {
    final sessionController = context.read<SshSessionController>();
    final sshController = context.read<SshController>();
    
    try {
      state.isConnecting = true;
      
      final sessionId = await sessionController.createSession(state.connection);
      
      if (sessionId != null) {
        state.sessionId = sessionId;
        state.isConnecting = false;
        state.error = null;

        // 更新最后使用时间
        sshController.updateLastUsedTime(state.connection.id);
        
        // 订阅会话流
        _subscribeToSession(state, sessionController.sessions[sessionId]!);
        
        // 如果这是当前活跃Tab，显示连接信息
        if (state.tabId == _currentActiveTabId) {
          state.terminal.write('已连接到 ${state.connection.connectionString}\r\n');
          state.terminal.write('终端准备就绪。\r\n\r\n');
        } else {
          // 非活跃Tab，只在其Terminal中记录连接信息，不显示
          state.terminal.write('已连接到 ${state.connection.connectionString}\r\n');
          state.terminal.write('终端准备就绪。\r\n\r\n');
        }
        
      } else {
        state.error = '连接失败';
        state.isConnecting = false;
      }
    } catch (e) {
      state.error = '连接错误: $e';
      state.isConnecting = false;
    }

    // 如果是当前活跃Tab，更新显示
    if (state.tabId == _currentActiveTabId && mounted) {
      _switchToTerminal(state.terminal);
    }
  }

  /// 订阅会话流
  void _subscribeToSession(_TabTerminalState state, SshService service) {
    // 监听输出
    state.outputSubscription = service.outputStream.listen(
      (data) {
        state.terminal.write(data);
        // 如果是当前活跃Tab，同步到显示终端
        if (state.tabId == _currentActiveTabId && _currentTerminal != null) {
          // 输出已经写入state.terminal，当前终端会自动同步
        }
      },
      onError: (error) {
        state.terminal.write('\r\n[错误] $error\r\n');
      },
    );

    // 监听状态变化
    state.statusSubscription = service.statusStream.listen((status) {
      if (status == SshConnectionStatus.error) {
        state.terminal.write('\r\n[连接已断开]\r\n');
      }
    });
  }

  /// 切换到活跃Tab
  void _switchToActiveTab() {
    if (widget.activeTabIndex >= 0 && widget.activeTabIndex < widget.tabs.length) {
      final activeTab = widget.tabs[widget.activeTabIndex];
      final tabState = _tabStates[activeTab.id];
      
      if (tabState != null) {
        _currentActiveTabId = activeTab.id;
        _switchToTerminal(tabState.terminal);
      }
    } else {
      _currentActiveTabId = null;
      _currentTerminal = null;
    }
  }

  /// 切换到指定终端
  void _switchToTerminal(Terminal terminal) {
    if (_currentTerminal != terminal) {
      // 设置新终端的输入处理
      terminal.onOutput = (data) {
        final sessionController = context.read<SshSessionController>();
        if (_currentActiveTabId != null) {
          final state = _tabStates[_currentActiveTabId];
          if (state?.sessionId != null) {
            sessionController.writeToSession(state!.sessionId!, data);
          }
        }
      };
      
      setState(() {
        _currentTerminal = terminal;
      });
    }
  }

  /// 清理所有状态
  void _cleanupAllStates() {
    for (final state in _tabStates.values) {
      state.dispose();
    }
    _tabStates.clear();
  }

  /// 重新连接当前Tab
  Future<void> _reconnectCurrentTab() async {
    if (_currentActiveTabId != null) {
      final state = _tabStates[_currentActiveTabId];
      if (state != null) {
        await _reconnectTab(state);
      }
    }
  }

  /// 重新连接指定Tab
  Future<void> _reconnectTab(_TabTerminalState state) async {
    final sessionController = context.read<SshSessionController>();
    
    // 清理现有连接
    state.cleanupSubscriptions();
    if (state.sessionId != null) {
      await sessionController.closeSession(state.sessionId!);
    }
    
    // 清空终端
    state.terminal.buffer.clear();
    
    // 重新连接
    await _initializeTabConnection(state);
  }

  /// 断开当前Tab连接
  Future<void> _disconnectCurrentTab() async {
    if (_currentActiveTabId != null) {
      final state = _tabStates[_currentActiveTabId];
      if (state != null) {
        await _disconnectTab(state);
      }
    }
  }

  /// 断开指定Tab连接
  Future<void> _disconnectTab(_TabTerminalState state) async {
    final sessionController = context.read<SshSessionController>();
    
    if (state.sessionId != null) {
      await sessionController.closeSession(state.sessionId!);
      state.cleanupSubscriptions();
      state.sessionId = null;
      state.terminal.write('\r\n[已断开连接]\r\n');
    }
  }

  /// 打开文件传输
  void _openFileTransfer() {
    if (_currentActiveTabId != null) {
      final state = _tabStates[_currentActiveTabId];
      if (state != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => FileTransferView(
              connection: state.connection, 
              sessionId: state.sessionId,
            ),
          ),
        );
      }
    }
  }

  /// 获取当前活跃Tab状态
  _TabTerminalState? get _currentTabState {
    return _currentActiveTabId != null ? _tabStates[_currentActiveTabId] : null;
  }

  @override
  Widget build(BuildContext context) {
    if (_currentTerminal == null) {
      return _buildWelcomeState();
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildTerminalView()),
        ],
      ),
    );
  }

  /// 构建欢迎状态
  Widget _buildWelcomeState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.terminal,
            size: 80.sp,
            color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
          ),
          SizedBox(height: 24.h),
          Text(
            '正在初始化终端...',
            style: TextStyle(
              fontSize: 18.sp,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建标题栏
  Widget _buildHeader() {
    final currentState = _currentTabState;
    if (currentState == null) return const SizedBox.shrink();

    final sessionController = context.watch<SshSessionController>();
    final service = currentState.sessionId != null 
        ? sessionController.sessions[currentState.sessionId] 
        : null;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 状态图标
          _buildStatusIcon(service?.status, currentState),
          SizedBox(width: 8.w),
          // 连接信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentState.connection.name,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  currentState.connection.connectionString,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // 操作按钮
          if (service != null) ...[ 
            if (service.isConnected)
              IconButton(
                onPressed: _openFileTransfer,
                icon: Icon(
                  Icons.folder_open,
                  size: 18.sp,
                ),
                tooltip: '文件传输',
              ),
            IconButton(
              onPressed: service.isConnected ? _disconnectCurrentTab : _reconnectCurrentTab,
              icon: Icon(
                service.isConnected ? Icons.link_off : Icons.refresh,
                size: 18.sp,
              ),
              tooltip: service.isConnected ? '断开连接' : '重新连接',
            ),
          ],
        ],
      ),
    );
  }

  /// 构建状态图标
  Widget _buildStatusIcon(SshConnectionStatus? status, _TabTerminalState state) {
    IconData icon;
    Color color;
    
    if (state.isConnecting) {
      icon = Icons.hourglass_empty;
      color = Colors.orange;
    } else if (state.error != null) {
      icon = Icons.error;
      color = Colors.red;
    } else {
      switch (status) {
        case SshConnectionStatus.connected:
        case SshConnectionStatus.authenticated:
          icon = Icons.check_circle;
          color = Colors.green;
          break;
        case SshConnectionStatus.connecting:
        case SshConnectionStatus.authenticating:
          icon = Icons.hourglass_empty;
          color = Colors.orange;
          break;
        case SshConnectionStatus.error:
          icon = Icons.error;
          color = Colors.red;
          break;
        case SshConnectionStatus.disconnected:
        default:
          icon = Icons.circle_outlined;
          color = Theme.of(context).colorScheme.onSurfaceVariant;
          break;
      }
    }

    return Icon(
      icon,
      size: 16.sp,
      color: color,
    );
  }

  /// 构建终端视图
  Widget _buildTerminalView() {
    final currentState = _currentTabState;
    
    if (currentState?.isConnecting == true) {
      return _buildLoadingState(currentState!);
    }
    
    if (currentState?.error != null) {
      return _buildErrorState(currentState!);
    }

    if (_currentTerminal == null) {
      return _buildWelcomeState();
    }

    return Container(
      color: Colors.black,
      child: TerminalView(
        _currentTerminal!,
        autofocus: true,
      ),
    );
  }

  /// 构建加载状态
  Widget _buildLoadingState(_TabTerminalState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32.w,
            height: 32.w,
            child: const CircularProgressIndicator(strokeWidth: 3),
          ),
          SizedBox(height: 16.h),
          Text(
            '正在连接...',
            style: TextStyle(
              fontSize: 14.sp,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            state.connection.connectionString,
            style: TextStyle(
              fontSize: 12.sp,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建错误状态
  Widget _buildErrorState(_TabTerminalState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48.sp,
            color: Theme.of(context).colorScheme.error,
          ),
          SizedBox(height: 16.h),
          Text(
            state.error!,
            style: TextStyle(
              fontSize: 14.sp,
              color: Theme.of(context).colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          ElevatedButton.icon(
            onPressed: _reconnectCurrentTab,
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }
}

/// Tab终端状态类
class _TabTerminalState {
  final String tabId;
  final String connectionId;
  final SshConnection connection;
  late final Terminal terminal;
  
  String? sessionId;
  bool isConnecting = false;
  String? error;
  
  StreamSubscription? outputSubscription;
  StreamSubscription? statusSubscription;

  _TabTerminalState({
    required this.tabId,
    required this.connectionId,
    required this.connection,
  }) {
    terminal = Terminal(maxLines: 10000);
  }

  /// 清理订阅
  void cleanupSubscriptions() {
    outputSubscription?.cancel();
    statusSubscription?.cancel();
    outputSubscription = null;
    statusSubscription = null;
  }

  /// 释放资源
  void dispose() {
    cleanupSubscriptions();
  }
}