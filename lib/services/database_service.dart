import 'package:sqflite/sqflite.dart';
import '../models/ssh_connection.dart';
import 'encryption_service.dart';

/// 数据库服务类
class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'ssh_client.db';
  static const int _databaseVersion = 2;

  /// 获取数据库实例
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    String path = '${await getDatabasesPath()}/$_databaseName';
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  /// 创建数据库表
  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ssh_connections (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        host TEXT NOT NULL,
        port INTEGER NOT NULL,
        username TEXT NOT NULL,
        password TEXT,
        private_key TEXT,
        description TEXT,
        created_at INTEGER NOT NULL,
        last_used_at INTEGER NOT NULL,
        encrypted INTEGER DEFAULT 0
      )
    ''');
  }

  /// 升级数据库
  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 添加加密标记列
      await db.execute('ALTER TABLE ssh_connections ADD COLUMN encrypted INTEGER DEFAULT 0');
    }
  }

  /// 插入新的 SSH 连接配置
  Future<void> insertConnection(SshConnection connection) async {
    final db = await database;
    final connectionMap = connection.toMap();
    final encryptedMap = await EncryptionService.encryptConnectionData(connectionMap);
    
    await db.insert(
      'ssh_connections',
      encryptedMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 获取所有 SSH 连接配置
  Future<List<SshConnection>> getAllConnections() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ssh_connections',
      orderBy: 'last_used_at DESC',
    );

    final List<SshConnection> connections = [];
    for (final map in maps) {
      final decryptedMap = await EncryptionService.decryptConnectionData(map);
      connections.add(SshConnection.fromMap(decryptedMap));
    }
    return connections;
  }

  /// 根据 ID 获取连接配置
  Future<SshConnection?> getConnection(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ssh_connections',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      final decryptedMap = await EncryptionService.decryptConnectionData(maps.first);
      return SshConnection.fromMap(decryptedMap);
    }
    return null;
  }

  /// 更新连接配置
  Future<void> updateConnection(SshConnection connection) async {
    final db = await database;
    final connectionMap = connection.toMap();
    final encryptedMap = await EncryptionService.encryptConnectionData(connectionMap);
    
    await db.update(
      'ssh_connections',
      encryptedMap,
      where: 'id = ?',
      whereArgs: [connection.id],
    );
  }

  /// 删除连接配置
  Future<void> deleteConnection(String id) async {
    final db = await database;
    await db.delete(
      'ssh_connections',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 更新连接的最后使用时间
  Future<void> updateLastUsedTime(String id) async {
    final db = await database;
    await db.update(
      'ssh_connections',
      {'last_used_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 搜索连接配置
  Future<List<SshConnection>> searchConnections(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ssh_connections',
      where: 'name LIKE ? OR host LIKE ? OR username LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'last_used_at DESC',
    );

    final List<SshConnection> connections = [];
    for (final map in maps) {
      final decryptedMap = await EncryptionService.decryptConnectionData(map);
      connections.add(SshConnection.fromMap(decryptedMap));
    }
    return connections;
  }

  /// 关闭数据库
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}