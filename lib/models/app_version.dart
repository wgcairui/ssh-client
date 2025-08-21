/// 应用版本信息模型
class AppVersion {
  final String version;
  final String tagName;
  final String name;
  final String body;
  final String downloadUrl;
  final int downloadSize;
  final String publishedAt;
  final bool isPrerelease;
  
  const AppVersion({
    required this.version,
    required this.tagName,
    required this.name,
    required this.body,
    required this.downloadUrl,
    required this.downloadSize,
    required this.publishedAt,
    this.isPrerelease = false,
  });
  
  factory AppVersion.fromJson(Map<String, dynamic> json) {
    // 查找APK文件（优先universal版本）
    final assets = json['assets'] as List<dynamic>? ?? [];
    String downloadUrl = '';
    int downloadSize = 0;
    
    // 优先查找universal APK
    var universalAsset = assets.firstWhere(
      (asset) => asset['name'].toString().contains('app-release.apk'),
      orElse: () => null,
    );
    
    if (universalAsset != null) {
      downloadUrl = universalAsset['browser_download_url'] ?? '';
      downloadSize = universalAsset['size'] ?? 0;
    } else {
      // 如果没有universal版本，查找arm64版本
      var arm64Asset = assets.firstWhere(
        (asset) => asset['name'].toString().contains('arm64-v8a-release.apk'),
        orElse: () => null,
      );
      
      if (arm64Asset != null) {
        downloadUrl = arm64Asset['browser_download_url'] ?? '';
        downloadSize = arm64Asset['size'] ?? 0;
      }
    }
    
    return AppVersion(
      version: json['tag_name'] ?? '',
      tagName: json['tag_name'] ?? '',
      name: json['name'] ?? '',
      body: json['body'] ?? '',
      downloadUrl: downloadUrl,
      downloadSize: downloadSize,
      publishedAt: json['published_at'] ?? '',
      isPrerelease: json['prerelease'] ?? false,
    );
  }
  
  /// 比较版本号大小
  bool isNewerThan(String currentVersion) {
    return _compareVersions(version, currentVersion) > 0;
  }
  
  /// 版本号比较
  static int _compareVersions(String version1, String version2) {
    // 处理dev版本和正式版本
    final v1 = _normalizeVersion(version1);
    final v2 = _normalizeVersion(version2);
    
    final parts1 = v1.split('.').map(int.tryParse).where((e) => e != null).cast<int>().toList();
    final parts2 = v2.split('.').map(int.tryParse).where((e) => e != null).cast<int>().toList();
    
    final maxLength = [parts1.length, parts2.length].reduce((a, b) => a > b ? a : b);
    
    for (int i = 0; i < maxLength; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      
      if (p1 > p2) return 1;
      if (p1 < p2) return -1;
    }
    
    return 0;
  }
  
  /// 规范化版本号
  static String _normalizeVersion(String version) {
    // 移除v前缀
    String normalized = version.replaceFirst(RegExp(r'^v'), '');
    
    // 处理dev版本，提取时间戳作为版本号
    if (normalized.startsWith('dev-')) {
      final parts = normalized.split('-');
      if (parts.length >= 3) {
        // dev-20250821-051839 -> 20250821.051839
        return '${parts[1]}.${parts[2]}';
      }
    }
    
    return normalized;
  }
  
  /// 格式化文件大小
  String get formattedSize {
    if (downloadSize == 0) return '未知';
    
    if (downloadSize < 1024) {
      return '${downloadSize}B';
    } else if (downloadSize < 1024 * 1024) {
      return '${(downloadSize / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(downloadSize / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }
  
  /// 格式化发布时间
  String get formattedPublishTime {
    try {
      final publishTime = DateTime.parse(publishedAt);
      final now = DateTime.now();
      final difference = now.difference(publishTime);
      
      if (difference.inDays > 0) {
        return '${difference.inDays}天前';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}小时前';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}分钟前';
      } else {
        return '刚刚';
      }
    } catch (e) {
      return publishedAt;
    }
  }
}