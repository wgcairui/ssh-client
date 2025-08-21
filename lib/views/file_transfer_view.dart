import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dartssh2/dartssh2.dart';
import 'dart:io';
import '../controllers/file_transfer_controller.dart';
import '../models/ssh_connection.dart';
import '../services/file_transfer_service.dart';

/// 文件传输页面
class FileTransferView extends StatefulWidget {
  final SshConnection connection;
  
  const FileTransferView({
    super.key,
    required this.connection,
  });

  @override
  State<FileTransferView> createState() => _FileTransferViewState();
}

class _FileTransferViewState extends State<FileTransferView> {
  late FileTransferController _controller;
  String _currentRemotePath = '/';
  List<SftpName> _remoteFiles = [];
  bool _isLoading = false;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _controller = context.read<FileTransferController>();
    _connectAndLoadFiles();
  }
  
  Future<void> _connectAndLoadFiles() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final success = await _controller.connect(widget.connection);
      if (success) {
        await _loadRemoteFiles();
      } else {
        setState(() {
          _error = '连接失败';
        });
      }
    } catch (e) {
      setState(() {
        _error = '连接错误: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadRemoteFiles() async {
    try {
      final files = await _controller.listRemoteDirectory(_currentRemotePath);
      setState(() {
        _remoteFiles = files;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = '加载目录失败: $e';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('文件传输 - ${widget.connection.name}'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadRemoteFiles,
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
          ),
          IconButton(
            onPressed: _showUploadDialog,
            icon: const Icon(Icons.upload),
            tooltip: '上传文件',
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildTransferTasks(),
    );
  }
  
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64.sp,
              color: Theme.of(context).colorScheme.error,
            ),
            SizedBox(height: 16.h),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 16.sp,
                color: Theme.of(context).colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: _connectAndLoadFiles,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        _buildPathBar(),
        Expanded(
          child: _buildFileList(),
        ),
      ],
    );
  }
  
  Widget _buildPathBar() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.folder_outlined,
            size: 20.sp,
            color: Theme.of(context).colorScheme.primary,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              '远程路径: $_currentRemotePath',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (_currentRemotePath != '/')
            IconButton(
              onPressed: _navigateUp,
              icon: const Icon(Icons.arrow_upward),
              tooltip: '上级目录',
            ),
        ],
      ),
    );
  }
  
  Widget _buildFileList() {
    if (_remoteFiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 64.sp,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 16.h),
            Text(
              '目录为空',
              style: TextStyle(
                fontSize: 16.sp,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: EdgeInsets.all(8.w),
      itemCount: _remoteFiles.length,
      itemBuilder: (context, index) {
        final file = _remoteFiles[index];
        return _buildFileItem(file);
      },
    );
  }
  
  Widget _buildFileItem(SftpName file) {
    final isDirectory = file.attr.isDirectory;
    final fileName = file.filename;
    final fileSize = file.attr.size ?? 0;
    
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4.h),
      child: ListTile(
        leading: Icon(
          isDirectory ? Icons.folder : Icons.insert_drive_file,
          color: isDirectory 
            ? Theme.of(context).colorScheme.primary 
            : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        title: Text(
          fileName,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: isDirectory ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
        subtitle: isDirectory 
          ? const Text('文件夹')
          : Text(_formatFileSize(fileSize)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isDirectory) ...[
              IconButton(
                onPressed: () => _downloadFile(file),
                icon: const Icon(Icons.download),
                tooltip: '下载',
              ),
            ],
            PopupMenuButton<String>(
              onSelected: (action) => _handleFileAction(action, file),
              itemBuilder: (context) => [
                if (isDirectory)
                  const PopupMenuItem(
                    value: 'open',
                    child: ListTile(
                      leading: Icon(Icons.folder_open),
                      title: Text('打开'),
                      dense: true,
                    ),
                  ),
                if (!isDirectory)
                  const PopupMenuItem(
                    value: 'download',
                    child: ListTile(
                      leading: Icon(Icons.download),
                      title: Text('下载'),
                      dense: true,
                    ),
                  ),
                const PopupMenuItem(
                  value: 'rename',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('重命名'),
                    dense: true,
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete),
                    title: Text('删除'),
                    dense: true,
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: isDirectory ? () => _openDirectory(fileName) : null,
      ),
    );
  }
  
  Widget _buildTransferTasks() {
    return Consumer<FileTransferController>(
      builder: (context, controller, child) {
        final tasks = controller.tasks;
        
        if (tasks.isEmpty) return const SizedBox.shrink();
        
        return Container(
          height: 200.h,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Row(
                  children: [
                    Icon(
                      Icons.transfer_within_a_station,
                      size: 16.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '传输任务 (${tasks.length})',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: controller.clearCompletedTasks,
                      child: const Text('清除已完成'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    return _buildTransferTaskItem(tasks[index]);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildTransferTaskItem(FileTransferTask task) {
    final progress = task.progress;
    final statusColor = _getStatusColor(progress.status);
    
    return Card(
      margin: EdgeInsets.symmetric(vertical: 2.h),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  task.isUpload ? Icons.upload : Icons.download,
                  size: 16.sp,
                  color: statusColor,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    progress.fileName,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  _getStatusText(progress.status),
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: statusColor,
                  ),
                ),
                if (progress.status == FileTransferStatus.transferring)
                  IconButton(
                    onPressed: () => _controller.cancelTask(task.id),
                    icon: const Icon(Icons.close),
                    iconSize: 16.sp,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: 24.w,
                      minHeight: 24.h,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 8.h),
            if (progress.status == FileTransferStatus.transferring) ...[
              LinearProgressIndicator(
                value: progress.progress,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              SizedBox(height: 4.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_formatFileSize(progress.bytesTransferred)} / ${_formatFileSize(progress.totalBytes)}',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '${(progress.progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
            if (progress.error != null) ...[
              SizedBox(height: 4.h),
              Text(
                progress.error!,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: Theme.of(context).colorScheme.error,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  void _navigateUp() {
    if (_currentRemotePath != '/') {
      final parts = _currentRemotePath.split('/');
      parts.removeLast();
      _currentRemotePath = parts.join('/');
      if (_currentRemotePath.isEmpty) _currentRemotePath = '/';
      _loadRemoteFiles();
    }
  }
  
  void _openDirectory(String dirName) {
    if (_currentRemotePath.endsWith('/')) {
      _currentRemotePath += dirName;
    } else {
      _currentRemotePath += '/$dirName';
    }
    _loadRemoteFiles();
  }
  
  void _handleFileAction(String action, SftpName file) {
    switch (action) {
      case 'open':
        _openDirectory(file.filename);
        break;
      case 'download':
        _downloadFile(file);
        break;
      case 'rename':
        _showRenameDialog(file);
        break;
      case 'delete':
        _showDeleteDialog(file);
        break;
    }
  }
  
  Future<void> _downloadFile(SftpName file) async {
    try {
      final result = await FilePicker.platform.getDirectoryPath();
      if (result != null) {
        final remotePath = _currentRemotePath.endsWith('/') 
          ? '$_currentRemotePath${file.filename}'
          : '$_currentRemotePath/${file.filename}';
        final localPath = '$result/${file.filename}';
        
        await _controller.startDownload(remotePath, localPath);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('开始下载: ${file.filename}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('下载失败: $e')),
        );
      }
    }
  }
  
  Future<void> _showUploadDialog() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
      );
      
      if (result != null) {
        for (final file in result.files) {
          if (file.path != null) {
            final remotePath = _currentRemotePath.endsWith('/') 
              ? '$_currentRemotePath${file.name}'
              : '$_currentRemotePath/${file.name}';
            
            await _controller.startUpload(file.path!, remotePath);
          }
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('开始上传 ${result.files.length} 个文件')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('上传失败: $e')),
        );
      }
    }
  }
  
  void _showRenameDialog(SftpName file) {
    final controller = TextEditingController(text: file.filename);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重命名'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '新名称',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != file.filename) {
                final oldPath = _currentRemotePath.endsWith('/') 
                  ? '$_currentRemotePath${file.filename}'
                  : '$_currentRemotePath/${file.filename}';
                final newPath = _currentRemotePath.endsWith('/') 
                  ? '$_currentRemotePath$newName'
                  : '$_currentRemotePath/$newName';
                
                final success = await _controller.renameRemoteFile(oldPath, newPath);
                
                if (mounted) {
                  Navigator.pop(context);
                  if (success) {
                    _loadRemoteFiles();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('重命名成功')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('重命名失败')),
                    );
                  }
                }
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteDialog(SftpName file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 "${file.filename}" 吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final filePath = _currentRemotePath.endsWith('/') 
                ? '$_currentRemotePath${file.filename}'
                : '$_currentRemotePath/${file.filename}';
              
              final success = await _controller.deleteRemoteFile(filePath);
              
              if (mounted) {
                Navigator.pop(context);
                if (success) {
                  _loadRemoteFiles();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('删除成功')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('删除失败')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
  
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
  
  Color _getStatusColor(FileTransferStatus status) {
    switch (status) {
      case FileTransferStatus.completed:
        return Colors.green;
      case FileTransferStatus.failed:
        return Colors.red;
      case FileTransferStatus.cancelled:
        return Colors.orange;
      case FileTransferStatus.transferring:
        return Colors.blue;
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }
  
  String _getStatusText(FileTransferStatus status) {
    switch (status) {
      case FileTransferStatus.idle:
        return '待开始';
      case FileTransferStatus.connecting:
        return '连接中';
      case FileTransferStatus.transferring:
        return '传输中';
      case FileTransferStatus.completed:
        return '完成';
      case FileTransferStatus.failed:
        return '失败';
      case FileTransferStatus.cancelled:
        return '已取消';
    }
  }
}