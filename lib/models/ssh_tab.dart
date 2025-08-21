import '../models/ssh_connection.dart';

/// SSH 标签页模型
class SshTab {
  final String id;
  final String connectionId;
  final SshConnection connection;
  final DateTime createdAt;
  bool isActive;

  SshTab({
    required this.id,
    required this.connectionId,
    required this.connection,
    required this.createdAt,
    this.isActive = false,
  });

  /// 获取标签页显示标题
  String get title {
    if (connection.name.length > 12) {
      return '${connection.name.substring(0, 12)}...';
    }
    return connection.name;
  }

  /// 获取完整标题（工具提示用）
  String get fullTitle => connection.name;

  /// 获取连接信息
  String get connectionInfo => '${connection.username}@${connection.host}:${connection.port}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SshTab &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}