import 'dart:io';
import 'dart:typed_data';
import 'package:dartssh2/dartssh2.dart';
import '../models/ssh_connection.dart';

/// 文件传输状态
enum FileTransferStatus {
  idle,
  connecting,
  transferring,
  completed,
  failed,
  cancelled,
}

/// 文件传输进度信息
class FileTransferProgress {
  final int bytesTransferred;
  final int totalBytes;
  final double progress;
  final String fileName;
  final FileTransferStatus status;
  final String? error;

  const FileTransferProgress({
    required this.bytesTransferred,
    required this.totalBytes,
    required this.progress,
    required this.fileName,
    required this.status,
    this.error,
  });

  FileTransferProgress copyWith({
    int? bytesTransferred,
    int? totalBytes,
    double? progress,
    String? fileName,
    FileTransferStatus? status,
    String? error,
  }) {
    return FileTransferProgress(
      bytesTransferred: bytesTransferred ?? this.bytesTransferred,
      totalBytes: totalBytes ?? this.totalBytes,
      progress: progress ?? this.progress,
      fileName: fileName ?? this.fileName,
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }
}

/// 文件传输服务
class FileTransferService {
  SSHClient? _client;
  SftpClient? _sftp;
  bool _isConnected = false;
  
  /// 使用现有SSH客户端创建SFTP连接
  Future<bool> connectWithExistingClient(SSHClient client) async {
    try {
      _client = client;
      _sftp = await _client!.sftp();
      _isConnected = true;
      return true;
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }
  
  /// 连接到SSH服务器并初始化SFTP（备用方法）
  Future<bool> connect(SshConnection connection) async {
    try {
      final socket = await SSHSocket.connect(connection.host, connection.port, timeout: const Duration(seconds: 10));
      
      if (connection.useKeyAuth && connection.privateKey != null) {
        _client = SSHClient(
          socket,
          username: connection.username,
          identities: [...SSHKeyPair.fromPem(connection.privateKey!)],
        );
      } else {
        _client = SSHClient(
          socket,
          username: connection.username,
          onPasswordRequest: () => connection.password ?? '',
        );
      }
      
      _sftp = await _client!.sftp();
      _isConnected = true;
      return true;
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }
  
  /// 断开连接
  Future<void> disconnect() async {
    _sftp?.close();
    _client?.close();
    _sftp = null;
    _client = null;
    _isConnected = false;
  }
  
  /// 检查是否已连接
  bool get isConnected => _isConnected && _sftp != null;
  
  /// 获取远程用户主目录路径
  Future<String> getRemoteHomeDirectory() async {
    if (!isConnected) throw Exception('未连接到服务器');
    
    try {
      // 尝试获取用户主目录
      final result = await _client!.run('echo \$HOME');
      final homePath = String.fromCharCodes(result).trim();
      if (homePath.isNotEmpty && homePath != '\$HOME') {
        return homePath;
      }
      // 备用方案：使用pwd获取当前目录
      final pwdResult = await _client!.run('pwd');
      return String.fromCharCodes(pwdResult).trim();
    } catch (e) {
      // 默认返回根目录
      return '/';
    }
  }
  
  /// 获取本地Downloads目录路径
  String getLocalDownloadDirectory() {
    // 在Android上，通常是 /storage/emulated/0/Download
    // 这里返回一个通用路径，实际使用时需要权限处理
    return '/storage/emulated/0/Download';
  }
  
  /// 列出远程目录内容
  Future<List<SftpName>> listRemoteDirectory(String path) async {
    if (!isConnected) throw Exception('未连接到服务器');
    
    try {
      return await _sftp!.listdir(path);
    } catch (e) {
      throw Exception('列出目录失败: $e');
    }
  }
  
  /// 上传文件到服务器
  Stream<FileTransferProgress> uploadFile(
    String localFilePath,
    String remoteFilePath, {
    bool overwrite = false,
  }) async* {
    if (!isConnected) {
      yield FileTransferProgress(
        bytesTransferred: 0,
        totalBytes: 0,
        progress: 0.0,
        fileName: File(localFilePath).path.split('/').last,
        status: FileTransferStatus.failed,
        error: '未连接到服务器',
      );
      return;
    }
    
    final localFile = File(localFilePath);
    if (!await localFile.exists()) {
      yield FileTransferProgress(
        bytesTransferred: 0,
        totalBytes: 0,
        progress: 0.0,
        fileName: localFile.path.split('/').last,
        status: FileTransferStatus.failed,
        error: '本地文件不存在',
      );
      return;
    }
    
    try {
      final fileSize = await localFile.length();
      final fileName = localFile.path.split('/').last;
      
      yield FileTransferProgress(
        bytesTransferred: 0,
        totalBytes: fileSize,
        progress: 0.0,
        fileName: fileName,
        status: FileTransferStatus.connecting,
      );
      
      // 检查远程文件是否存在
      if (!overwrite) {
        try {
          await _sftp!.stat(remoteFilePath);
          yield FileTransferProgress(
            bytesTransferred: 0,
            totalBytes: fileSize,
            progress: 0.0,
            fileName: fileName,
            status: FileTransferStatus.failed,
            error: '远程文件已存在',
          );
          return;
        } catch (e) {
          // 文件不存在，可以继续上传
        }
      }
      
      yield FileTransferProgress(
        bytesTransferred: 0,
        totalBytes: fileSize,
        progress: 0.0,
        fileName: fileName,
        status: FileTransferStatus.transferring,
      );
      
      // 打开远程文件进行写入
      final remoteFile = await _sftp!.open(
        remoteFilePath,
        mode: SftpFileOpenMode.create | SftpFileOpenMode.write,
      );
      
      int bytesTransferred = 0;
      
      await for (final chunk in localFile.openRead()) {
        await remoteFile.write(Stream.value(Uint8List.fromList(chunk)));
        bytesTransferred += chunk.length;
        
        final progress = bytesTransferred / fileSize;
        yield FileTransferProgress(
          bytesTransferred: bytesTransferred,
          totalBytes: fileSize,
          progress: progress,
          fileName: fileName,
          status: FileTransferStatus.transferring,
        );
      }
      
      await remoteFile.close();
      
      yield FileTransferProgress(
        bytesTransferred: bytesTransferred,
        totalBytes: fileSize,
        progress: 1.0,
        fileName: fileName,
        status: FileTransferStatus.completed,
      );
      
    } catch (e) {
      yield FileTransferProgress(
        bytesTransferred: 0,
        totalBytes: 0,
        progress: 0.0,
        fileName: File(localFilePath).path.split('/').last,
        status: FileTransferStatus.failed,
        error: '上传失败: $e',
      );
    }
  }
  
  /// 从服务器下载文件
  Stream<FileTransferProgress> downloadFile(
    String remoteFilePath,
    String localFilePath, {
    bool overwrite = false,
  }) async* {
    if (!isConnected) {
      yield FileTransferProgress(
        bytesTransferred: 0,
        totalBytes: 0,
        progress: 0.0,
        fileName: remoteFilePath.split('/').last,
        status: FileTransferStatus.failed,
        error: '未连接到服务器',
      );
      return;
    }
    
    final localFile = File(localFilePath);
    final fileName = remoteFilePath.split('/').last;
    
    // 检查本地文件是否存在
    if (!overwrite && await localFile.exists()) {
      yield FileTransferProgress(
        bytesTransferred: 0,
        totalBytes: 0,
        progress: 0.0,
        fileName: fileName,
        status: FileTransferStatus.failed,
        error: '本地文件已存在',
      );
      return;
    }
    
    try {
      yield FileTransferProgress(
        bytesTransferred: 0,
        totalBytes: 0,
        progress: 0.0,
        fileName: fileName,
        status: FileTransferStatus.connecting,
      );
      
      // 获取远程文件信息
      final remoteStat = await _sftp!.stat(remoteFilePath);
      final fileSize = remoteStat.size ?? 0;
      
      if (fileSize == 0) {
        yield FileTransferProgress(
          bytesTransferred: 0,
          totalBytes: 0,
          progress: 0.0,
          fileName: fileName,
          status: FileTransferStatus.failed,
          error: '远程文件为空或无法获取文件大小',
        );
        return;
      }
      
      yield FileTransferProgress(
        bytesTransferred: 0,
        totalBytes: fileSize,
        progress: 0.0,
        fileName: fileName,
        status: FileTransferStatus.transferring,
      );
      
      // 打开远程文件进行读取
      final remoteFile = await _sftp!.open(remoteFilePath, mode: SftpFileOpenMode.read);
      
      // 确保本地目录存在
      await localFile.parent.create(recursive: true);
      final localSink = localFile.openWrite();
      
      int bytesTransferred = 0;
      const chunkSize = 32768; // 32KB chunks
      
      while (bytesTransferred < fileSize) {
        final remainingBytes = fileSize - bytesTransferred;
        final currentChunkSize = remainingBytes < chunkSize ? remainingBytes : chunkSize;
        
        final chunk = await remoteFile.readBytes(offset: bytesTransferred, length: currentChunkSize);
        localSink.add(chunk);
        bytesTransferred += chunk.length;
        
        final progress = bytesTransferred / fileSize;
        yield FileTransferProgress(
          bytesTransferred: bytesTransferred,
          totalBytes: fileSize,
          progress: progress,
          fileName: fileName,
          status: FileTransferStatus.transferring,
        );
        
        if (chunk.length < currentChunkSize) break; // End of file
      }
      
      await localSink.close();
      await remoteFile.close();
      
      yield FileTransferProgress(
        bytesTransferred: bytesTransferred,
        totalBytes: fileSize,
        progress: 1.0,
        fileName: fileName,
        status: FileTransferStatus.completed,
      );
      
    } catch (e) {
      yield FileTransferProgress(
        bytesTransferred: 0,
        totalBytes: 0,
        progress: 0.0,
        fileName: fileName,
        status: FileTransferStatus.failed,
        error: '下载失败: $e',
      );
    }
  }
  
  /// 创建远程目录
  Future<bool> createRemoteDirectory(String path) async {
    if (!isConnected) return false;
    
    try {
      await _sftp!.mkdir(path);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// 删除远程文件
  Future<bool> deleteRemoteFile(String path) async {
    if (!isConnected) return false;
    
    try {
      await _sftp!.remove(path);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// 重命名远程文件
  Future<bool> renameRemoteFile(String oldPath, String newPath) async {
    if (!isConnected) return false;
    
    try {
      await _sftp!.rename(oldPath, newPath);
      return true;
    } catch (e) {
      return false;
    }
  }
}