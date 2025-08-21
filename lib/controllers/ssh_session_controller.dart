import 'package:flutter/foundation.dart';
import '../models/ssh_connection.dart';
import '../services/ssh_service.dart';

/// SSH 会话控制器
class SshSessionController extends ChangeNotifier {
  final Map<String, SshService> _sessions = {};
  String? _activeSessionId;

  // Getters
  Map<String, SshService> get sessions => _sessions;
  String? get activeSessionId => _activeSessionId;
  SshService? get activeSession => _activeSessionId != null ? _sessions[_activeSessionId] : null;

  /// 创建新的 SSH 会话
  Future<String?> createSession(SshConnection connection) async {
    final sessionId = '${connection.id}_${DateTime.now().millisecondsSinceEpoch}';
    
    final service = SshService();
    _sessions[sessionId] = service;
    
    // 监听连接状态变化
    service.statusStream.listen((status) {
      notifyListeners();
    });

    // 监听错误信息
    service.errorStream.listen((error) {
      notifyListeners();
    });

    // 尝试连接
    final success = await service.connect(connection);
    
    if (success) {
      _activeSessionId = sessionId;
      notifyListeners();
      return sessionId;
    } else {
      // 连接失败，移除会话
      _sessions.remove(sessionId);
      service.dispose();
      notifyListeners();
      return null;
    }
  }

  /// 切换活动会话
  void switchSession(String sessionId) {
    if (_sessions.containsKey(sessionId)) {
      _activeSessionId = sessionId;
      notifyListeners();
    }
  }

  /// 关闭会话
  Future<void> closeSession(String sessionId) async {
    final service = _sessions[sessionId];
    if (service != null) {
      await service.disconnect();
      service.dispose();
      _sessions.remove(sessionId);
      
      // 如果关闭的是活动会话，切换到其他会话或清空
      if (_activeSessionId == sessionId) {
        if (_sessions.isNotEmpty) {
          _activeSessionId = _sessions.keys.first;
        } else {
          _activeSessionId = null;
        }
      }
      
      notifyListeners();
    }
  }

  /// 关闭所有会话
  Future<void> closeAllSessions() async {
    final sessionIds = _sessions.keys.toList();
    for (final sessionId in sessionIds) {
      await closeSession(sessionId);
    }
  }

  /// 发送命令到活动会话
  Future<void> writeToActiveSession(String input) async {
    if (activeSession != null) {
      await activeSession!.write(input);
    }
  }

  /// 发送命令到指定会话
  Future<void> writeToSession(String sessionId, String input) async {
    final session = _sessions[sessionId];
    if (session != null) {
      await session.write(input);
    }
  }

  /// 调整活动会话终端大小
  Future<void> resizeActiveSession(int width, int height) async {
    if (activeSession != null) {
      await activeSession!.resizeTerminal(width, height);
    }
  }

  /// 获取会话显示名称
  String getSessionDisplayName(String sessionId) {
    final service = _sessions[sessionId];
    if (service?.currentConnection != null) {
      final connection = service!.currentConnection!;
      return '${connection.name} (${connection.host})';
    }
    return '未知会话';
  }

  /// 获取会话连接信息
  SshConnection? getSessionConnection(String sessionId) {
    return _sessions[sessionId]?.currentConnection;
  }

  /// 检查是否有活动连接
  bool get hasActiveConnection => 
      activeSession != null && activeSession!.isConnected;

  /// 获取会话数量
  int get sessionCount => _sessions.length;

  /// 获取连接中的会话数量
  int get connectingSessionCount {
    return _sessions.values.where((service) => 
        service.status == SshConnectionStatus.connecting ||
        service.status == SshConnectionStatus.authenticating
    ).length;
  }

  /// 获取已连接的会话数量
  int get connectedSessionCount {
    return _sessions.values.where((service) => 
        service.status == SshConnectionStatus.authenticated
    ).length;
  }

  /// 获取错误会话数量
  int get errorSessionCount {
    return _sessions.values.where((service) => 
        service.status == SshConnectionStatus.error
    ).length;
  }

  @override
  void dispose() {
    closeAllSessions();
    super.dispose();
  }
}