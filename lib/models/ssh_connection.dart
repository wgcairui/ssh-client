/// SSH 连接配置模型
class SshConnection {
  final String id;
  final String name;
  final String host;
  final int port;
  final String username;
  final String? password;
  final String? privateKey;
  final String? description;
  final DateTime createdAt;
  final DateTime lastUsedAt;

  const SshConnection({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.username,
    this.password,
    this.privateKey,
    this.description,
    required this.createdAt,
    required this.lastUsedAt,
  });

  /// 从数据库 Map 创建对象
  factory SshConnection.fromMap(Map<String, dynamic> map) {
    return SshConnection(
      id: map['id'],
      name: map['name'],
      host: map['host'],
      port: map['port'],
      username: map['username'],
      password: map['password'],
      privateKey: map['private_key'],
      description: map['description'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      lastUsedAt: DateTime.fromMillisecondsSinceEpoch(map['last_used_at']),
    );
  }

  /// 转换为数据库 Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'host': host,
      'port': port,
      'username': username,
      'password': password,
      'private_key': privateKey,
      'description': description,
      'created_at': createdAt.millisecondsSinceEpoch,
      'last_used_at': lastUsedAt.millisecondsSinceEpoch,
    };
  }

  /// 复制并修改部分属性
  SshConnection copyWith({
    String? name,
    String? host,
    int? port,
    String? username,
    String? password,
    String? privateKey,
    String? description,
    DateTime? lastUsedAt,
  }) {
    return SshConnection(
      id: id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      privateKey: privateKey ?? this.privateKey,
      description: description ?? this.description,
      createdAt: createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  /// 获取连接地址字符串
  String get connectionString => '$username@$host:$port';

  /// 是否使用密钥认证
  bool get useKeyAuth => privateKey != null && privateKey!.isNotEmpty;
}