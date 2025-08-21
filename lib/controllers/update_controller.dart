import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_version.dart';
import '../services/update_service.dart';

/// 更新状态
enum UpdateStatus {
  idle,           // 空闲状态
  checking,       // 检查更新中
  available,      // 有新版本可用
  downloading,    // 下载中
  downloaded,     // 下载完成
  installing,     // 安装中
  failed,         // 更新失败
  noUpdate,       // 没有更新
}

/// 自动更新控制器
class UpdateController extends ChangeNotifier {
  final UpdateService _updateService = UpdateService();
  
  UpdateStatus _status = UpdateStatus.idle;
  AppVersion? _availableUpdate;
  String? _downloadedFilePath;
  double _downloadProgress = 0.0;
  String? _errorMessage;
  Timer? _autoCheckTimer;
  
  // 设置
  bool _autoCheckEnabled = true;
  bool _includePrerelease = true;
  int _checkIntervalHours = 24;
  
  // Getters
  UpdateStatus get status => _status;
  AppVersion? get availableUpdate => _availableUpdate;
  String? get downloadedFilePath => _downloadedFilePath;
  double get downloadProgress => _downloadProgress;
  String? get errorMessage => _errorMessage;
  bool get autoCheckEnabled => _autoCheckEnabled;
  bool get includePrerelease => _includePrerelease;
  int get checkIntervalHours => _checkIntervalHours;
  
  /// 初始化
  Future<void> initialize() async {
    await _loadSettings();
    if (_autoCheckEnabled) {
      _startAutoCheck();
      // 启动时检查一次更新（延迟5秒避免影响启动速度）
      Timer(const Duration(seconds: 5), () => checkForUpdate());
    }
  }
  
  /// 检查更新
  Future<void> checkForUpdate() async {
    if (_status == UpdateStatus.checking) return;
    
    _setStatus(UpdateStatus.checking);
    _clearError();
    
    try {
      final update = await _updateService.checkForUpdate(
        includePrerelease: _includePrerelease,
      );
      
      if (update != null) {
        _availableUpdate = update;
        _setStatus(UpdateStatus.available);
        await _saveLastCheckTime();
      } else {
        _setStatus(UpdateStatus.noUpdate);
      }
    } catch (e) {
      _setError('检查更新失败: $e');
      _setStatus(UpdateStatus.failed);
    }
  }
  
  /// 下载更新
  Future<void> downloadUpdate() async {
    if (_availableUpdate == null || _status == UpdateStatus.downloading) {
      return;
    }
    
    _setStatus(UpdateStatus.downloading);
    _downloadProgress = 0.0;
    _clearError();
    
    try {
      final filePath = await _updateService.downloadApk(
        _availableUpdate!,
        onProgress: (received, total) {
          if (total > 0) {
            _downloadProgress = received / total;
            notifyListeners();
          }
        },
      );
      
      if (filePath != null) {
        _downloadedFilePath = filePath;
        _setStatus(UpdateStatus.downloaded);
      } else {
        _setError('下载失败');
        _setStatus(UpdateStatus.failed);
      }
    } catch (e) {
      _setError('下载失败: $e');
      _setStatus(UpdateStatus.failed);
    }
  }
  
  /// 安装更新
  Future<void> installUpdate() async {
    if (_downloadedFilePath == null || _status == UpdateStatus.installing) {
      return;
    }
    
    _setStatus(UpdateStatus.installing);
    _clearError();
    
    try {
      final success = await _updateService.installApk(_downloadedFilePath!);
      if (!success) {
        _setError('安装失败');
        _setStatus(UpdateStatus.failed);
      }
      // 安装成功后状态由系统管理，不需要手动设置
    } catch (e) {
      _setError('安装失败: $e');
      _setStatus(UpdateStatus.failed);
    }
  }
  
  /// 忽略当前版本
  Future<void> ignoreCurrentUpdate() async {
    if (_availableUpdate != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ignored_version', _availableUpdate!.version);
      _availableUpdate = null;
      _setStatus(UpdateStatus.idle);
    }
  }
  
  /// 清理下载文件
  Future<void> cleanupDownloads() async {
    try {
      await _updateService.cleanupDownloads();
      _downloadedFilePath = null;
      if (_status == UpdateStatus.downloaded) {
        _setStatus(UpdateStatus.idle);
      }
    } catch (e) {
      debugPrint('清理下载文件失败: $e');
    }
  }
  
  /// 更新设置
  Future<void> updateSettings({
    bool? autoCheckEnabled,
    bool? includePrerelease,
    int? checkIntervalHours,
  }) async {
    if (autoCheckEnabled != null) {
      _autoCheckEnabled = autoCheckEnabled;
      if (autoCheckEnabled) {
        _startAutoCheck();
      } else {
        _stopAutoCheck();
      }
    }
    
    if (includePrerelease != null) {
      _includePrerelease = includePrerelease;
    }
    
    if (checkIntervalHours != null) {
      _checkIntervalHours = checkIntervalHours;
      if (_autoCheckEnabled) {
        _startAutoCheck(); // 重新启动定时器
      }
    }
    
    await _saveSettings();
    notifyListeners();
  }
  
  /// 重置状态
  void resetStatus() {
    _setStatus(UpdateStatus.idle);
    _availableUpdate = null;
    _downloadedFilePath = null;
    _downloadProgress = 0.0;
    _clearError();
  }
  
  @override
  void dispose() {
    _stopAutoCheck();
    super.dispose();
  }
  
  // Private methods
  
  void _setStatus(UpdateStatus status) {
    _status = status;
    notifyListeners();
  }
  
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }
  
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  void _startAutoCheck() {
    _stopAutoCheck();
    _autoCheckTimer = Timer.periodic(
      Duration(hours: _checkIntervalHours),
      (_) => checkForUpdate(),
    );
  }
  
  void _stopAutoCheck() {
    _autoCheckTimer?.cancel();
    _autoCheckTimer = null;
  }
  
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _autoCheckEnabled = prefs.getBool('auto_check_enabled') ?? true;
      _includePrerelease = prefs.getBool('include_prerelease') ?? true;
      _checkIntervalHours = prefs.getInt('check_interval_hours') ?? 24;
    } catch (e) {
      debugPrint('加载更新设置失败: $e');
    }
  }
  
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auto_check_enabled', _autoCheckEnabled);
      await prefs.setBool('include_prerelease', _includePrerelease);
      await prefs.setInt('check_interval_hours', _checkIntervalHours);
    } catch (e) {
      debugPrint('保存更新设置失败: $e');
    }
  }
  
  Future<void> _saveLastCheckTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_check_time', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('保存检查时间失败: $e');
    }
  }
  
}