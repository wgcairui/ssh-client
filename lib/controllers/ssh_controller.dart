import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/ssh_connection.dart';
import '../services/database_service.dart';

/// SSH 连接管理控制器
class SshController extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final Uuid _uuid = const Uuid();
  
  List<SshConnection> _connections = [];
  bool _isLoading = false;
  String? _error;
  bool _mounted = true;

  // Getters
  List<SshConnection> get connections => _connections;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get mounted => _mounted;

  /// 初始化，加载所有连接
  Future<void> initialize() async {
    await loadConnections();
  }

  /// 加载所有连接配置
  Future<void> loadConnections() async {
    if (!mounted) return; // Guard against disposed controller
    
    _setLoading(true);
    try {
      _connections = await _databaseService.getAllConnections();
      if (!mounted) return; // Check again after async operation
      _error = null;
    } catch (e) {
      if (!mounted) return; // Check again after async operation
      _error = '加载连接配置失败: $e';
      if (kDebugMode) {
        print('Error loading connections: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// 添加新的连接配置
  Future<bool> addConnection({
    required String name,
    required String host,
    required int port,
    required String username,
    String? password,
    String? privateKey,
    String? description,
  }) async {
    _setLoading(true);
    try {
      final connection = SshConnection(
        id: _uuid.v4(),
        name: name,
        host: host,
        port: port,
        username: username,
        password: password,
        privateKey: privateKey,
        description: description,
        createdAt: DateTime.now(),
        lastUsedAt: DateTime.now(),
      );

      await _databaseService.insertConnection(connection);
      await loadConnections();
      _error = null;
      return true;
    } catch (e) {
      _error = '添加连接失败: $e';
      if (kDebugMode) {
        print('Error adding connection: $e');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 更新连接配置
  Future<bool> updateConnection(SshConnection connection) async {
    _setLoading(true);
    try {
      await _databaseService.updateConnection(connection);
      await loadConnections();
      _error = null;
      return true;
    } catch (e) {
      _error = '更新连接失败: $e';
      if (kDebugMode) {
        print('Error updating connection: $e');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 删除连接配置
  Future<bool> deleteConnection(String id) async {
    _setLoading(true);
    try {
      await _databaseService.deleteConnection(id);
      await loadConnections();
      _error = null;
      return true;
    } catch (e) {
      _error = '删除连接失败: $e';
      if (kDebugMode) {
        print('Error deleting connection: $e');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 更新连接的最后使用时间
  Future<void> updateLastUsedTime(String id) async {
    try {
      await _databaseService.updateLastUsedTime(id);
      await loadConnections();
    } catch (e) {
      if (kDebugMode) {
        print('Error updating last used time: $e');
      }
    }
  }

  /// 获取单个连接配置
  Future<SshConnection?> getConnection(String id) async {
    try {
      return await _databaseService.getConnection(id);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting connection: $e');
      }
      return null;
    }
  }

  /// 搜索连接配置
  Future<List<SshConnection>> searchConnections(String query) async {
    if (query.isEmpty) return _connections;
    
    try {
      return await _databaseService.searchConnections(query);
    } catch (e) {
      if (kDebugMode) {
        print('Error searching connections: $e');
      }
      return [];
    }
  }

  /// 复制连接配置
  Future<bool> duplicateConnection(SshConnection connection) async {
    return await addConnection(
      name: '${connection.name} (副本)',
      host: connection.host,
      port: connection.port,
      username: connection.username,
      password: connection.password,
      privateKey: connection.privateKey,
      description: connection.description,
    );
  }

  /// 设置加载状态
  void _setLoading(bool loading) {
    if (!mounted) return; // Guard against disposed controller
    _isLoading = loading;
    notifyListeners();
  }

  /// 清除错误信息
  void clearError() {
    if (!mounted) return; // Guard against disposed controller
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _mounted = false;
    _databaseService.close();
    super.dispose();
  }
}