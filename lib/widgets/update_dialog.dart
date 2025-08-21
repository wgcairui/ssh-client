import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../controllers/update_controller.dart';
import '../models/app_version.dart';

/// 更新提示对话框
class UpdateDialog extends StatelessWidget {
  final AppVersion version;
  final bool forceUpdate;
  
  const UpdateDialog({
    super.key,
    required this.version,
    this.forceUpdate = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return Consumer<UpdateController>(
      builder: (context, controller, child) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Row(
            children: [
              Icon(
                Icons.system_update,
                color: Theme.of(context).primaryColor,
                size: 36.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                forceUpdate ? '必须更新' : '发现新版本',
                style: TextStyle(
                  fontSize: 27.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 版本信息
                _buildVersionInfo(),
                SizedBox(height: 16.h),
                
                // 更新内容
                if (version.body.isNotEmpty) ...[
                  Text(
                    '更新内容：',
                    style: TextStyle(
                      fontSize: 21.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      version.body,
                      style: TextStyle(
                        fontSize: 18.sp,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],
                
                // 下载进度
                if (controller.status == UpdateStatus.downloading) ...[
                  _buildDownloadProgress(controller),
                  SizedBox(height: 16.h),
                ],
                
                // 状态信息
                _buildStatusInfo(controller),
              ],
            ),
          ),
          actions: _buildActions(context, controller),
        );
      },
    );
  }
  
  Widget _buildVersionInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '版本：',
              style: TextStyle(
                fontSize: 21.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              version.version,
              style: TextStyle(
                fontSize: 21.sp,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            if (version.isPrerelease) ...[
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  '测试版',
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: 4.h),
        Row(
          children: [
            Text(
              '大小：',
              style: TextStyle(fontSize: 18.sp),
            ),
            Text(
              version.formattedSize,
              style: TextStyle(fontSize: 18.sp),
            ),
            SizedBox(width: 16.w),
            Text(
              '发布时间：',
              style: TextStyle(fontSize: 18.sp),
            ),
            Text(
              version.formattedPublishTime,
              style: TextStyle(fontSize: 18.sp),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildDownloadProgress(UpdateController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '下载进度',
              style: TextStyle(
                fontSize: 21.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(controller.downloadProgress * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 18.sp,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        LinearProgressIndicator(
          value: controller.downloadProgress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      ],
    );
  }
  
  Widget _buildStatusInfo(UpdateController controller) {
    String statusText = '';
    Color? statusColor;
    
    switch (controller.status) {
      case UpdateStatus.checking:
        statusText = '正在检查更新...';
        statusColor = Colors.blue;
        break;
      case UpdateStatus.downloading:
        statusText = '正在下载更新包...';
        statusColor = Colors.blue;
        break;
      case UpdateStatus.downloaded:
        statusText = '下载完成，准备安装';
        statusColor = Colors.green;
        break;
      case UpdateStatus.installing:
        statusText = '正在安装...';
        statusColor = Colors.orange;
        break;
      case UpdateStatus.failed:
        statusText = controller.errorMessage ?? '更新失败';
        statusColor = Colors.red;
        break;
      default:
        return const SizedBox.shrink();
    }
    
    return Row(
      children: [
        if (controller.status == UpdateStatus.checking || 
            controller.status == UpdateStatus.downloading ||
            controller.status == UpdateStatus.installing) ...[
          SizedBox(
            width: 16.w,
            height: 16.w,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          SizedBox(width: 8.w),
        ],
        Expanded(
          child: Text(
            statusText,
            style: TextStyle(
              fontSize: 18.sp,
              color: statusColor,
            ),
          ),
        ),
      ],
    );
  }
  
  List<Widget> _buildActions(BuildContext context, UpdateController controller) {
    final actions = <Widget>[];
    
    // 根据状态显示不同的按钮
    switch (controller.status) {
      case UpdateStatus.available:
        if (!forceUpdate) {
          actions.add(
            TextButton(
              onPressed: () {
                controller.ignoreCurrentUpdate();
                Navigator.of(context).pop();
              },
              child: Text(
                '忽略',
                style: TextStyle(fontSize: 21.sp),
              ),
            ),
          );
          
          actions.add(
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                '稍后提醒',
                style: TextStyle(fontSize: 21.sp),
              ),
            ),
          );
        }
        
        actions.add(
          FilledButton(
            onPressed: () => controller.downloadUpdate(),
            child: Text(
              '立即更新',
              style: TextStyle(fontSize: 21.sp),
            ),
          ),
        );
        break;
        
      case UpdateStatus.downloaded:
        if (!forceUpdate) {
          actions.add(
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                '稍后安装',
                style: TextStyle(fontSize: 21.sp),
              ),
            ),
          );
        }
        
        actions.add(
          FilledButton(
            onPressed: () => controller.installUpdate(),
            child: Text(
              '立即安装',
              style: TextStyle(fontSize: 21.sp),
            ),
          ),
        );
        break;
        
      case UpdateStatus.failed:
        actions.add(
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '取消',
              style: TextStyle(fontSize: 21.sp),
            ),
          ),
        );
        
        actions.add(
          FilledButton(
            onPressed: () => controller.downloadUpdate(),
            child: Text(
              '重试',
              style: TextStyle(fontSize: 21.sp),
            ),
          ),
        );
        break;
        
      case UpdateStatus.downloading:
      case UpdateStatus.installing:
        if (!forceUpdate) {
          actions.add(
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                '后台运行',
                style: TextStyle(fontSize: 21.sp),
              ),
            ),
          );
        }
        break;
        
      default:
        actions.add(
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '关闭',
              style: TextStyle(fontSize: 21.sp),
            ),
          ),
        );
    }
    
    return actions;
  }
}