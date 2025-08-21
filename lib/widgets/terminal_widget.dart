import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:xterm/xterm.dart';
import '../controllers/ssh_controller.dart';
import '../controllers/ssh_session_controller.dart';
import '../models/ssh_connection.dart';
import '../services/ssh_service.dart';

/// 终端组件 - 完整实现
class TerminalWidget extends StatefulWidget {
  final String connectionId;
  final VoidCallback? onClose;

  const TerminalWidget({
    super.key,
    required this.connectionId,
    this.onClose,
  });

  @override
  State<TerminalWidget> createState() => _TerminalWidgetState();
}

class _TerminalWidgetState extends State<TerminalWidget> {
  Terminal? _terminal;
  String? _sessionId;
  SshConnection? _connection;
  StreamSubscription? _outputSubscription;
  StreamSubscription? _statusSubscription;
  bool _isConnecting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeTerminal();
  }

  @override
  void dispose() {
    _cleanupSubscriptions();
    super.dispose();
  }

  /// 初始化终端
  void _initializeTerminal() {
    _terminal = Terminal(
      maxLines: 10000,
    );

    // 监听终端输入
    _terminal!.onOutput = (data) {
      context.read<SshSessionController>().writeToActiveSession(data);
    };

    // 获取连接信息并连接
    _loadConnectionAndConnect();
  }

  /// 加载连接信息并连接
  Future<void> _loadConnectionAndConnect() async {
    final sshController = context.read<SshController>();
    final connection = await sshController.getConnection(widget.connectionId);
    
    if (connection != null) {
      setState(() {
        _connection = connection;
        _isConnecting = true;
        _error = null;
      });

      await _connectToSsh(connection);
    } else {
      setState(() {
        _error = '找不到连接配置';
      });
    }
  }

  /// 连接到 SSH
  Future<void> _connectToSsh(SshConnection connection) async {
    final sessionController = context.read<SshSessionController>();
    
    try {
      final sessionId = await sessionController.createSession(connection);
      
      if (sessionId != null) {
        setState(() {
          _sessionId = sessionId;
          _isConnecting = false;
        });

        // 更新最后使用时间
        context.read<SshController>().updateLastUsedTime(connection.id);
        
        // 订阅输出和状态
        _subscribeToSession(sessionController.sessions[sessionId]!);
        
        // 显示欢迎信息
        _terminal!.write('已连接到 ${connection.connectionString}\r\n');
        _terminal!.write('终端准备就绪。\r\n\r\n');
        
      } else {
        setState(() {
          _error = '连接失败';
          _isConnecting = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = '连接错误: $e';
        _isConnecting = false;
      });
    }
  }

  /// 订阅会话流
  void _subscribeToSession(SshService service) {
    // 监听输出
    _outputSubscription = service.outputStream.listen(
      (data) {
        if (mounted) {
          _terminal!.write(data);
        }
      },
      onError: (error) {
        if (mounted) {
          _terminal!.write('\r\n[错误] $error\r\n');
        }
      },
    );

    // 监听状态变化
    _statusSubscription = service.statusStream.listen((status) {
      if (mounted) {
        setState(() {});
        
        if (status == SshConnectionStatus.error) {
          _terminal!.write('\r\n[连接已断开]\r\n');
        }
      }
    });
  }

  /// 清理订阅
  void _cleanupSubscriptions() {
    _outputSubscription?.cancel();
    _statusSubscription?.cancel();
  }

  /// 重新连接
  Future<void> _reconnect() async {
    if (_connection != null) {
      _cleanupSubscriptions();
      if (_sessionId != null) {
        await context.read<SshSessionController>().closeSession(_sessionId!);
      }
      _terminal!.buffer.clear();
      await _connectToSsh(_connection!);
    }
  }

  /// 断开连接
  Future<void> _disconnect() async {
    if (_sessionId != null) {
      await context.read<SshSessionController>().closeSession(_sessionId!);
      _cleanupSubscriptions();
      setState(() {
        _sessionId = null;
      });
      _terminal!.write('\r\n[已断开连接]\r\n');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: widget.onClose != null
            ? null
            : Border(
                left: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  /// 构建标题栏
  Widget _buildHeader() {
    final sessionController = context.watch<SshSessionController>();
    final service = _sessionId != null ? sessionController.sessions[_sessionId] : null;
    
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
          _buildStatusIcon(service?.status),
          SizedBox(width: 8.w),
          // 连接信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _connection?.name ?? '未知连接',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_connection != null)
                  Text(
                    _connection!.connectionString,
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
            IconButton(
              onPressed: service.isConnected ? _disconnect : _reconnect,
              icon: Icon(
                service.isConnected ? Icons.link_off : Icons.refresh,
                size: 18.sp,
              ),
              tooltip: service.isConnected ? '断开连接' : '重新连接',
            ),
          ],
          if (widget.onClose != null)
            IconButton(
              onPressed: () async {
                await _disconnect();
                widget.onClose!();
              },
              icon: const Icon(Icons.close),
              iconSize: 20.sp,
              tooltip: '关闭',
            ),
        ],
      ),
    );
  }

  /// 构建状态图标
  Widget _buildStatusIcon(SshConnectionStatus? status) {
    IconData icon;
    Color color;
    
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

    return Icon(
      icon,
      size: 16.sp,
      color: color,
    );
  }

  /// 构建内容区域
  Widget _buildContent() {
    if (_isConnecting) {
      return _buildLoadingState();
    }
    
    if (_error != null) {
      return _buildErrorState();
    }
    
    if (_terminal == null) {
      return _buildLoadingState();
    }

    return _buildTerminal();
  }

  /// 构建加载状态
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32.w,
            height: 32.w,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          SizedBox(height: 16.h),
          Text(
            '正在连接...',
            style: TextStyle(
              fontSize: 14.sp,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (_connection != null) ...[
            SizedBox(height: 8.h),
            Text(
              _connection!.connectionString,
              style: TextStyle(
                fontSize: 12.sp,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建错误状态
  Widget _buildErrorState() {
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
            _error!,
            style: TextStyle(
              fontSize: 14.sp,
              color: Theme.of(context).colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          ElevatedButton.icon(
            onPressed: _reconnect,
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }

  /// 构建终端
  Widget _buildTerminal() {
    return Container(
      color: Colors.black,
      child: TerminalView(
        _terminal!,
      ),
    );
  }
}