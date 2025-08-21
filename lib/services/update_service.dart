import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/app_version.dart';

/// 更新检查服务
class UpdateService {
  static const String _repoOwner = 'wgcairui';
  static const String _repoName = 'ssh-client';
  static const String _githubApiBase = 'https://api.github.com';
  
  /// 获取最新版本信息
  Future<AppVersion?> getLatestVersion({bool includePrerelease = true}) async {
    try {
      final url = '$_githubApiBase/repos/$_repoOwner/$_repoName/releases';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'SSH-Client-Flutter-App',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final List<dynamic> releases = json.decode(response.body);
        
        if (releases.isEmpty) return null;
        
        // 查找最新的可用版本
        for (final release in releases) {
          final version = AppVersion.fromJson(release);
          
          // 如果不包含预发布版本，跳过预发布版本
          if (!includePrerelease && version.isPrerelease) {
            continue;
          }
          
          // 确保有可下载的APK文件
          if (version.downloadUrl.isNotEmpty) {
            return version;
          }
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('检查更新失败: $e');
      return null;
    }
  }
  
  /// 获取当前应用版本
  Future<String> getCurrentVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      debugPrint('获取当前版本失败: $e');
      return '1.0.0';
    }
  }
  
  /// 检查是否有新版本
  Future<AppVersion?> checkForUpdate({bool includePrerelease = true}) async {
    try {
      final currentVersion = await getCurrentVersion();
      final latestVersion = await getLatestVersion(includePrerelease: includePrerelease);
      
      if (latestVersion != null && latestVersion.isNewerThan(currentVersion)) {
        return latestVersion;
      }
      
      return null;
    } catch (e) {
      debugPrint('检查更新出错: $e');
      return null;
    }
  }
  
  /// 下载APK文件
  Future<String?> downloadApk(AppVersion version, {
    Function(int received, int total)? onProgress,
  }) async {
    try {
      // 请求存储权限
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          throw Exception('需要存储权限才能下载更新');
        }
      }
      
      // 获取下载目录
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        throw Exception('无法访问外部存储');
      }
      
      final downloadDir = Directory('${directory.path}/Download');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }
      
      final fileName = 'ssh_client_${version.version}.apk';
      final filePath = '${downloadDir.path}/$fileName';
      final file = File(filePath);
      
      // 如果文件已存在，先删除
      if (await file.exists()) {
        await file.delete();
      }
      
      // 开始下载
      final request = http.Request('GET', Uri.parse(version.downloadUrl));
      final response = await request.send();
      
      if (response.statusCode == 200) {
        final contentLength = response.contentLength ?? 0;
        int received = 0;
        
        final sink = file.openWrite();
        
        await response.stream.listen(
          (chunk) {
            sink.add(chunk);
            received += chunk.length;
            onProgress?.call(received, contentLength);
          },
          onDone: () {
            sink.close();
          },
          onError: (error) {
            sink.close();
            throw error;
          },
        ).asFuture();
        
        return filePath;
      } else {
        throw Exception('下载失败: HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('下载APK失败: $e');
      rethrow;
    }
  }
  
  /// 安装APK（仅Android）
  Future<bool> installApk(String filePath) async {
    try {
      if (!Platform.isAndroid) {
        return false;
      }
      
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('APK文件不存在');
      }
      
      // 请求安装权限
      if (Platform.isAndroid) {
        final status = await Permission.requestInstallPackages.request();
        if (!status.isGranted) {
          throw Exception('需要安装权限才能安装更新');
        }
      }
      
      // 使用平台通道安装APK
      // 这里需要实现原生Android代码来处理安装
      // 暂时返回true，表示安装请求已发送
      debugPrint('安装APK: $filePath');
      return true;
      
    } catch (e) {
      debugPrint('安装APK失败: $e');
      return false;
    }
  }
  
  /// 清理下载的文件
  Future<void> cleanupDownloads() async {
    try {
      final directory = await getExternalStorageDirectory();
      if (directory == null) return;
      
      final downloadDir = Directory('${directory.path}/Download');
      if (await downloadDir.exists()) {
        final files = await downloadDir.list().toList();
        for (final file in files) {
          if (file is File && file.path.endsWith('.apk') && file.path.contains('ssh_client_')) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('清理下载文件失败: $e');
    }
  }
}