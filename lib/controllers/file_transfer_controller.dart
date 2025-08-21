import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dartssh2/dartssh2.dart';
import '../models/ssh_connection.dart';
import '../services/file_transfer_service.dart';

/// 文件传输任务
class FileTransferTask {
  final String id;
  final String localPath;
  final String remotePath;
  final bool isUpload; // true: 上传, false: 下载
  final FileTransferProgress progress;
  StreamSubscription? _subscription;
  
  FileTransferTask({
    required this.id,
    required this.localPath,
    required this.remotePath,
    required this.isUpload,
    required this.progress,
  });
  
  FileTransferTask copyWith({
    FileTransferProgress? progress,
  }) {
    return FileTransferTask(
      id: id,
      localPath: localPath,
      remotePath: remotePath,
      isUpload: isUpload,
      progress: progress ?? this.progress,
    );
  }
}

/// 文件传输控制器
class FileTransferController extends ChangeNotifier {
  final FileTransferService _service = FileTransferService();
  final Map<String, FileTransferTask> _tasks = {};
  SshConnection? _currentConnection;
  
  /// 获取所有传输任务
  List<FileTransferTask> get tasks => _tasks.values.toList();
  
  /// 获取当前连接
  SshConnection? get currentConnection => _currentConnection;
  
  /// 是否已连接
  bool get isConnected => _service.isConnected;
  
  /// 连接到SSH服务器
  Future<bool> connect(SshConnection connection) async {
    try {
      final success = await _service.connect(connection);
      if (success) {
        _currentConnection = connection;
        notifyListeners();
      }
      return success;
    } catch (e) {
      return false;
    }
  }
  
  /// 断开连接
  Future<void> disconnect() async {
    // 取消所有正在进行的任务
    for (final task in _tasks.values) {
      if (task.progress.status == FileTransferStatus.transferring) {
        await task._subscription?.cancel();
      }
    }
    
    await _service.disconnect();
    _currentConnection = null;
    _tasks.clear();
    notifyListeners();
  }
  
  /// 列出远程目录
  Future<List<SftpName>> listRemoteDirectory(String path) async {
    return await _service.listRemoteDirectory(path);
  }
  
  /// 开始上传文件
  Future<String> startUpload(String localFilePath, String remoteFilePath, {bool overwrite = false}) async {
    final taskId = DateTime.now().millisecondsSinceEpoch.toString();
    
    final task = FileTransferTask(
      id: taskId,
      localPath: localFilePath,
      remotePath: remoteFilePath,
      isUpload: true,
      progress: FileTransferProgress(
        bytesTransferred: 0,
        totalBytes: 0,
        progress: 0.0,
        fileName: localFilePath.split('/').last,
        status: FileTransferStatus.idle,
      ),
    );
    
    _tasks[taskId] = task;
    notifyListeners();
    
    // 开始传输
    task._subscription = _service.uploadFile(localFilePath, remoteFilePath, overwrite: overwrite).listen(
      (progress) {
        _tasks[taskId] = task.copyWith(progress: progress);
        notifyListeners();
      },
      onError: (error) {
        _tasks[taskId] = task.copyWith(
          progress: task.progress.copyWith(
            status: FileTransferStatus.failed,
            error: error.toString(),
          ),
        );
        notifyListeners();
      },
      onDone: () {
        task._subscription?.cancel();
      },
    );
    
    return taskId;
  }
  
  /// 开始下载文件
  Future<String> startDownload(String remoteFilePath, String localFilePath, {bool overwrite = false}) async {
    final taskId = DateTime.now().millisecondsSinceEpoch.toString();
    
    final task = FileTransferTask(
      id: taskId,
      localPath: localFilePath,
      remotePath: remoteFilePath,
      isUpload: false,
      progress: FileTransferProgress(
        bytesTransferred: 0,
        totalBytes: 0,
        progress: 0.0,
        fileName: remoteFilePath.split('/').last,
        status: FileTransferStatus.idle,
      ),
    );
    
    _tasks[taskId] = task;
    notifyListeners();
    
    // 开始传输
    task._subscription = _service.downloadFile(remoteFilePath, localFilePath, overwrite: overwrite).listen(
      (progress) {
        _tasks[taskId] = task.copyWith(progress: progress);
        notifyListeners();
      },
      onError: (error) {
        _tasks[taskId] = task.copyWith(
          progress: task.progress.copyWith(
            status: FileTransferStatus.failed,
            error: error.toString(),
          ),
        );
        notifyListeners();
      },
      onDone: () {
        task._subscription?.cancel();
      },
    );
    
    return taskId;
  }
  
  /// 取消传输任务
  Future<void> cancelTask(String taskId) async {
    final task = _tasks[taskId];
    if (task != null) {
      await task._subscription?.cancel();
      _tasks[taskId] = task.copyWith(
        progress: task.progress.copyWith(status: FileTransferStatus.cancelled),
      );
      notifyListeners();
    }
  }
  
  /// 删除任务记录
  void removeTask(String taskId) {
    _tasks.remove(taskId);
    notifyListeners();
  }
  
  /// 清除已完成的任务
  void clearCompletedTasks() {
    _tasks.removeWhere((_, task) => 
      task.progress.status == FileTransferStatus.completed ||
      task.progress.status == FileTransferStatus.failed ||
      task.progress.status == FileTransferStatus.cancelled
    );
    notifyListeners();
  }
  
  /// 创建远程目录
  Future<bool> createRemoteDirectory(String path) async {
    return await _service.createRemoteDirectory(path);
  }
  
  /// 删除远程文件
  Future<bool> deleteRemoteFile(String path) async {
    return await _service.deleteRemoteFile(path);
  }
  
  /// 重命名远程文件
  Future<bool> renameRemoteFile(String oldPath, String newPath) async {
    return await _service.renameRemoteFile(oldPath, newPath);
  }
  
  @override
  void dispose() {
    // 取消所有订阅
    for (final task in _tasks.values) {
      task._subscription?.cancel();
    }
    disconnect();
    super.dispose();
  }
}