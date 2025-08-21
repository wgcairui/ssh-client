import 'dart:async';
import 'dart:convert';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';
import '../models/ssh_connection.dart';

/// SSH 连接状态
enum SshConnectionStatus {
  disconnected,
  connecting,
  connected,
  authenticating,
  authenticated,
  error,
}

/// SSH 会话服务
class SshService {
  SSHClient? _client;
  SSHSession? _session;
  SshConnectionStatus _status = SshConnectionStatus.disconnected;
  String? _error;
  SshConnection? _currentConnection;
  Timer? _keepAliveTimer;
  DateTime? _lastActivity;

  // 保活配置
  static const Duration _keepAliveInterval = Duration(seconds: 30);
  static const Duration _inactivityThreshold = Duration(minutes: 5);

  // 流控制器
  final StreamController<String> _outputController = StreamController<String>.broadcast();
  final StreamController<SshConnectionStatus> _statusController = StreamController<SshConnectionStatus>.broadcast();
  final StreamController<String?> _errorController = StreamController<String?>.broadcast();

  // Getters
  SshConnectionStatus get status => _status;
  String? get error => _error;
  SshConnection? get currentConnection => _currentConnection;
  SSHClient? get client => _client;
  
  // 流
  Stream<String> get outputStream => _outputController.stream;
  Stream<SshConnectionStatus> get statusStream => _statusController.stream;
  Stream<String?> get errorStream => _errorController.stream;

  /// 连接到 SSH 服务器
  Future<bool> connect(SshConnection connection) async {
    if (_status == SshConnectionStatus.connecting || 
        _status == SshConnectionStatus.connected) {
      return false;
    }

    _currentConnection = connection;
    _setStatus(SshConnectionStatus.connecting);
    _setError(null);

    try {
      // 创建 SSH 客户端
      final socket = await SSHSocket.connect(
        connection.host,
        connection.port,
        timeout: const Duration(seconds: 10),
      );

      // 根据认证方式创建客户端
      if (connection.useKeyAuth && connection.privateKey != null) {
        // 密钥认证
        _client = SSHClient(
          socket,
          username: connection.username,
          identities: [
            ...SSHKeyPair.fromPem(connection.privateKey!),
          ],
        );
      } else if (connection.password != null) {
        // 密码认证
        _client = SSHClient(
          socket,
          username: connection.username,
          onPasswordRequest: () => connection.password!,
        );
      } else {
        throw Exception('未提供认证信息');
      }

      _setStatus(SshConnectionStatus.connected);
      _setStatus(SshConnectionStatus.authenticating);

      // 等待认证完成
      try {
        await _client!.authenticated;
        _setStatus(SshConnectionStatus.authenticated);
      } catch (e) {
        throw Exception('认证失败: $e');
      }
      
      // 创建会话
      await _createShell();
      
      // 启动保活机制
      _startKeepAlive();
      
      return true;

    } catch (e) {
      _setError('连接失败: $e');
      _setStatus(SshConnectionStatus.error);
      await disconnect();
      return false;
    }
  }

  /// 创建 Shell 会话
  Future<void> _createShell() async {
    if (_client == null) return;

    try {
      _session = await _client!.shell(
        pty: SSHPtyConfig(
          width: 80,
          height: 24,
        ),
      );

      // 监听输出
      _session!.stdout.cast<List<int>>().transform(utf8.decoder).listen(
        (data) {
          _outputController.add(data);
        },
        onError: (error) {
          _setError('输出流错误: $error');
        },
      );

      _session!.stderr.cast<List<int>>().transform(utf8.decoder).listen(
        (data) {
          _outputController.add(data);
        },
        onError: (error) {
          _setError('错误流错误: $error');
        },
      );

    } catch (e) {
      throw Exception('创建 Shell 失败: $e');
    }
  }

  /// 发送命令
  Future<void> write(String input) async {
    if (_session == null || _status != SshConnectionStatus.authenticated) {
      return;
    }

    try {
      _session!.write(utf8.encode(input));
      _updateActivity(); // 更新活动时间
    } catch (e) {
      _setError('发送命令失败: $e');
    }
  }

  /// 调整终端大小
  Future<void> resizeTerminal(int width, int height) async {
    if (_session == null) return;

    try {
      _session!.resizeTerminal(width, height);
    } catch (e) {
      if (kDebugMode) {
        print('调整终端大小失败: $e');
      }
    }
  }

  /// 断开连接
  Future<void> disconnect() async {
    // 停止保活定时器
    _stopKeepAlive();
    
    try {
      if (_session != null) {
        _session!.close();
        _session = null;
      }
      
      if (_client != null) {
        _client!.close();
        _client = null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('断开连接时出错: $e');
      }
    } finally {
      _currentConnection = null;
      _lastActivity = null;
      _setStatus(SshConnectionStatus.disconnected);
      _setError(null);
    }
  }

  /// 检查连接状态
  bool get isConnected => 
      _status == SshConnectionStatus.connected || 
      _status == SshConnectionStatus.authenticated;

  /// 设置状态
  void _setStatus(SshConnectionStatus status) {
    _status = status;
    _statusController.add(status);
  }

  /// 设置错误信息
  void _setError(String? error) {
    _error = error;
    _errorController.add(error);
  }

  /// 获取状态描述
  String getStatusDescription() {
    switch (_status) {
      case SshConnectionStatus.disconnected:
        return '未连接';
      case SshConnectionStatus.connecting:
        return '连接中...';
      case SshConnectionStatus.connected:
        return '已连接';
      case SshConnectionStatus.authenticating:
        return '认证中...';
      case SshConnectionStatus.authenticated:
        return '已认证';
      case SshConnectionStatus.error:
        return _error ?? '连接错误';
    }
  }

  /// 开始保活机制
  void _startKeepAlive() {
    _updateActivity();
    _keepAliveTimer = Timer.periodic(_keepAliveInterval, (timer) {
      _performKeepAlive();
    });
  }

  /// 停止保活机制
  void _stopKeepAlive() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
  }

  /// 更新活动时间
  void _updateActivity() {
    _lastActivity = DateTime.now();
  }

  /// 执行保活操作
  void _performKeepAlive() {
    if (_client == null || _session == null || !isConnected) {
      _stopKeepAlive();
      return;
    }

    final now = DateTime.now();
    final lastActivity = _lastActivity ?? now;
    
    // 如果超过非活跃阈值时间，发送保活包
    if (now.difference(lastActivity) > _inactivityThreshold) {
      try {
        // 发送一个空的命令来保持连接活跃
        // 使用echo命令，不会产生明显的输出影响
        write('\x00'); // 发送null字符作为保活信号
        
        if (kDebugMode) {
          print('SSH保活: 发送保活包到 ${_currentConnection?.connectionString}');
        }
      } catch (e) {
        if (kDebugMode) {
          print('SSH保活失败: $e');
        }
        // 保活失败，可能连接已断开
        _setError('连接保活失败: $e');
        _setStatus(SshConnectionStatus.error);
      }
    }
  }

  /// 获取连接信息
  SshConnection get connection => _currentConnection!;

  /// 释放资源
  void dispose() {
    disconnect();
    _outputController.close();
    _statusController.close();
    _errorController.close();
  }
}