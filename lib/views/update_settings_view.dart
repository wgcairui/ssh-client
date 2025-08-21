import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../controllers/update_controller.dart';
import '../services/update_service.dart';
import '../widgets/update_dialog.dart';

/// 更新设置页面
class UpdateSettingsView extends StatefulWidget {
  const UpdateSettingsView({super.key});

  @override
  State<UpdateSettingsView> createState() => _UpdateSettingsViewState();
}

class _UpdateSettingsViewState extends State<UpdateSettingsView> {
  String _currentVersion = '获取中...';
  
  @override
  void initState() {
    super.initState();
    _loadCurrentVersion();
  }
  
  Future<void> _loadCurrentVersion() async {
    final updateService = UpdateService();
    final version = await updateService.getCurrentVersion();
    setState(() {
      _currentVersion = version;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('自动更新设置'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<UpdateController>(
        builder: (context, controller, child) {
          return ListView(
            padding: EdgeInsets.all(16.r),
            children: [
              // 当前版本信息
              _buildCurrentVersionCard(),
              SizedBox(height: 16.h),
              
              // 检查更新按钮
              _buildCheckUpdateCard(controller),
              SizedBox(height: 16.h),
              
              // 自动更新设置
              _buildAutoUpdateSettings(controller),
              SizedBox(height: 16.h),
              
              // 更新通道设置
              _buildUpdateChannelSettings(controller),
              SizedBox(height: 16.h),
              
              // 其他设置
              _buildOtherSettings(controller),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildCurrentVersionCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).primaryColor,
                  size: 30.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  '版本信息',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '当前版本：',
                  style: TextStyle(fontSize: 21.sp),
                ),
                Text(
                  _currentVersion,
                  style: TextStyle(
                    fontSize: 21.sp,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCheckUpdateCard(UpdateController controller) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.refresh,
                  color: Theme.of(context).primaryColor,
                  size: 30.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  '检查更新',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            
            // 状态显示
            if (controller.status != UpdateStatus.idle) ...[
              _buildUpdateStatus(controller),
              SizedBox(height: 12.h),
            ],
            
            // 检查更新按钮
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: controller.status == UpdateStatus.checking
                    ? null
                    : () => _checkForUpdate(controller),
                icon: controller.status == UpdateStatus.checking
                    ? SizedBox(
                        width: 16.w,
                        height: 16.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.search),
                label: Text(
                  controller.status == UpdateStatus.checking
                      ? '检查中...'
                      : '手动检查更新',
                  style: TextStyle(fontSize: 21.sp),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildUpdateStatus(UpdateController controller) {
    String statusText = '';
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.info;
    
    switch (controller.status) {
      case UpdateStatus.checking:
        statusText = '正在检查更新...';
        statusColor = Colors.blue;
        statusIcon = Icons.refresh;
        break;
      case UpdateStatus.available:
        statusText = '发现新版本：${controller.availableUpdate?.version ?? ''}';
        statusColor = Colors.green;
        statusIcon = Icons.new_releases;
        break;
      case UpdateStatus.noUpdate:
        statusText = '已是最新版本';
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case UpdateStatus.downloading:
        statusText = '正在下载更新包... ${(controller.downloadProgress * 100).toStringAsFixed(1)}%';
        statusColor = Colors.blue;
        statusIcon = Icons.download;
        break;
      case UpdateStatus.downloaded:
        statusText = '下载完成，点击安装';
        statusColor = Colors.orange;
        statusIcon = Icons.install_desktop;
        break;
      case UpdateStatus.installing:
        statusText = '正在安装...';
        statusColor = Colors.orange;
        statusIcon = Icons.settings;
        break;
      case UpdateStatus.failed:
        statusText = controller.errorMessage ?? '更新失败';
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      default:
        return const SizedBox.shrink();
    }
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            statusIcon,
            color: statusColor,
            size: 24.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 18.sp,
                color: statusColor,
              ),
            ),
          ),
          if (controller.status == UpdateStatus.available ||
              controller.status == UpdateStatus.downloaded) ...[
            TextButton(
              onPressed: () => _showUpdateDialog(controller),
              child: Text(
                controller.status == UpdateStatus.available ? '立即更新' : '立即安装',
                style: TextStyle(fontSize: 18.sp),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildAutoUpdateSettings(UpdateController controller) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_mode,
                  color: Theme.of(context).primaryColor,
                  size: 30.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  '自动更新',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            
            // 自动检查开关
            SwitchListTile(
              title: Text(
                '自动检查更新',
                style: TextStyle(fontSize: 21.sp),
              ),
              subtitle: Text(
                '应用启动时自动检查是否有新版本',
                style: TextStyle(fontSize: 18.sp),
              ),
              value: controller.autoCheckEnabled,
              onChanged: (value) {
                controller.updateSettings(autoCheckEnabled: value);
              },
            ),
            
            // 检查间隔设置
            if (controller.autoCheckEnabled) ...[
              Divider(height: 1.h),
              ListTile(
                title: Text(
                  '检查间隔',
                  style: TextStyle(fontSize: 21.sp),
                ),
                subtitle: Text(
                  '每${controller.checkIntervalHours}小时检查一次',
                  style: TextStyle(fontSize: 18.sp),
                ),
                trailing: DropdownButton<int>(
                  value: controller.checkIntervalHours,
                  items: [6, 12, 24, 48, 72].map((hours) {
                    return DropdownMenuItem(
                      value: hours,
                      child: Text('$hours小时'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      controller.updateSettings(checkIntervalHours: value);
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildUpdateChannelSettings(UpdateController controller) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.stream,
                  color: Theme.of(context).primaryColor,
                  size: 30.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  '更新通道',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            
            // 测试版开关
            SwitchListTile(
              title: Text(
                '接收测试版更新',
                style: TextStyle(fontSize: 21.sp),
              ),
              subtitle: Text(
                '包含预发布版本，可能不稳定但包含最新功能',
                style: TextStyle(fontSize: 18.sp),
              ),
              value: controller.includePrerelease,
              onChanged: (value) {
                controller.updateSettings(includePrerelease: value);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOtherSettings(UpdateController controller) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings,
                  color: Theme.of(context).primaryColor,
                  size: 30.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  '其他设置',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            
            // 清理下载文件
            ListTile(
              title: Text(
                '清理下载文件',
                style: TextStyle(fontSize: 21.sp),
              ),
              subtitle: Text(
                '删除已下载的APK文件以释放存储空间',
                style: TextStyle(fontSize: 18.sp),
              ),
              trailing: TextButton(
                onPressed: () => _cleanupDownloads(controller),
                child: Text(
                  '清理',
                  style: TextStyle(fontSize: 18.sp),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _checkForUpdate(UpdateController controller) async {
    await controller.checkForUpdate();
    
    if (controller.status == UpdateStatus.available && 
        controller.availableUpdate != null) {
      _showUpdateDialog(controller);
    } else if (controller.status == UpdateStatus.noUpdate) {
      _showSnackBar('已是最新版本', Colors.green);
    } else if (controller.status == UpdateStatus.failed) {
      _showSnackBar(controller.errorMessage ?? '检查更新失败', Colors.red);
    }
  }
  
  void _showUpdateDialog(UpdateController controller) {
    if (controller.availableUpdate != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => UpdateDialog(
          version: controller.availableUpdate!,
        ),
      );
    }
  }
  
  Future<void> _cleanupDownloads(UpdateController controller) async {
    await controller.cleanupDownloads();
    _showSnackBar('清理完成', Colors.green);
  }
  
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}