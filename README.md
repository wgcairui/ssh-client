# SSH 客户端 - 专为 OPPO Pad 4 Pro 优化

一个现代化的 Flutter SSH 客户端应用，专为 13.2 英寸平板设计，提供完整的 SSH 连接和终端功能。

## 🎯 功能特性

### 核心功能
- ✅ **完整 SSH 连接**：支持密码和 SSH 密钥认证
- ✅ **终端模拟器**：集成 xterm 提供完整终端体验
- ✅ **多标签页管理**：同时打开最多 8 个 SSH 连接
- ✅ **文件传输**：完整的 SFTP 文件上传下载功能
- ✅ **连接历史**：自动保存和管理连接配置
- ✅ **实时状态**：连接状态实时显示和错误处理
- ✨ **自动更新**：GitHub 集成，自动检查和下载最新版本

### UI 特性（OPPO Pad 4 Pro 优化）
- 🎨 **响应式布局**：专为 13.2 英寸屏幕优化
- 📱 **分屏设计**：横屏时左侧连接列表+右侧多标签终端
- 🌓 **现代主题**：Material 3 设计，支持深色/浅色模式
- 🔍 **智能搜索**：连接配置快速搜索和筛选
- 📝 **连接管理**：添加、编辑、删除、复制连接
- ⚙️ **设置菜单**：更新设置、应用信息等配置选项

## 🛠 技术架构

### 技术栈
- **Flutter 3.x**：跨平台 UI 框架
- **dartssh2 2.9.0**：SSH 连接库
- **xterm 4.0.0**：终端模拟器
- **sqflite**：SQLite 本地数据库
- **provider**：状态管理
- **flutter_screenutil**：响应式布局
- **http**：网络请求和文件下载
- **package_info_plus**：应用版本信息

### 架构设计
```
lib/
├── main.dart              # 应用入口
├── models/                # 数据模型
│   ├── ssh_connection.dart
│   └── app_version.dart
├── views/                 # 视图层
│   ├── home_view_with_tabs.dart
│   ├── add_connection_view.dart
│   └── update_settings_view.dart
├── controllers/           # 控制器层
│   ├── ssh_controller.dart
│   ├── ssh_session_controller.dart
│   ├── ssh_tab_controller.dart
│   ├── file_transfer_controller.dart
│   └── update_controller.dart
├── services/             # 服务层
│   ├── database_service.dart
│   ├── ssh_service.dart
│   ├── file_transfer_service.dart
│   └── update_service.dart
└── widgets/              # UI 组件
    ├── connection_list_widget.dart
    ├── ssh_tab_bar.dart
    ├── single_terminal_manager.dart
    ├── file_transfer_widget.dart
    └── update_dialog.dart
```

## 🚀 快速开始

### 环境要求
- Flutter 3.x
- Android SDK (API 21+)
- Dart 3.0+

### 安装步骤
1. **进入项目目录**
   ```bash
   cd ssh_client
   ```

2. **安装依赖**
   ```bash
   flutter pub get
   ```

3. **运行应用**
   ```bash
   flutter run
   ```

4. **构建 APK**
   ```bash
   flutter build apk --release
   ```

## 📱 使用指南

### 添加 SSH 连接
1. 打开应用，点击右上角 "+" 按钮
2. 填写连接信息：
   - 连接名称：自定义名称
   - 主机地址：服务器 IP 或域名
   - 端口：默认 22
   - 用户名：SSH 用户名
3. 选择认证方式：
   - **密码认证**：输入登录密码
   - **密钥认证**：粘贴 SSH 私钥内容
4. 点击"保存连接"

### 连接服务器
1. 在连接列表中点击要连接的服务器
2. 应用会自动连接并显示连接状态
3. 连接成功后会打开终端界面

### 使用终端
- **输入命令**：在终端中直接输入命令
- **查看输出**：实时显示命令执行结果  
- **状态指示**：顶部显示连接状态（绿色=已连接，橙色=连接中，红色=错误）
- **重新连接**：点击刷新按钮重新连接
- **断开连接**：点击断开按钮或关闭终端

### 管理连接
- **搜索**：点击搜索图标快速查找连接
- **编辑**：长按连接项选择"编辑"
- **复制**：长按连接项选择"复制"创建副本
- **删除**：长按连接项选择"删除"

### 多标签页功能
- **新建标签**：点击标签栏右侧"+"按钮或选择连接
- **切换标签**：点击标签页标题切换不同连接
- **关闭标签**：点击标签页右侧"×"按钮
- **最大连接数**：同时支持最多 8 个活跃连接

### 文件传输功能
- **访问**：连接服务器后，点击底部"文件"标签
- **上传文件**：点击上传按钮选择本地文件
- **下载文件**：点击服务器文件右侧下载按钮
- **目录导航**：点击文件夹进入，使用返回按钮退出
- **默认路径**：服务器为用户主目录，本地为Downloads文件夹

### 自动更新功能
- **自动检查**：应用启动时自动检查更新（可配置关闭）
- **手动检查**：设置→自动更新设置→手动检查更新
- **更新设置**：配置检查间隔（6-72小时）和测试版接收
- **一键更新**：发现新版本时自动下载并提示安装
- **版本管理**：支持稳定版和测试版（预发布）选择

## 🎨 OPPO Pad 4 Pro 优化

### 屏幕适配
- **分辨率**：2160x1440 完美适配
- **分屏布局**：横屏时双面板设计
- **触控优化**：大屏触控体验优化
- **字体缩放**：支持系统字体大小设置

### 横屏体验
- **左侧面板**：480dp 宽度的连接列表，支持折叠到80dp
- **右侧面板**：多标签页终端区域，自适应宽度
- **标签栏**：顶部标签页切换，最多8个标签
- **分割线**：可视化面板分割
- **状态栏**：完整的连接状态显示

### 竖屏体验  
- **堆叠布局**：连接列表和终端切换显示
- **全屏终端**：最大化终端使用空间
- **返回按钮**：便捷的界面切换

## 🔧 开发指南

### 常用命令
```bash
# 获取依赖
flutter pub get

# 代码分析
flutter analyze

# 运行应用
flutter run

# 构建 APK
flutter build apk --release

# 清理构建缓存
flutter clean
```

### 数据库结构
```sql
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
    last_used_at INTEGER NOT NULL
);
```

## 🐛 故障排除

### 常见问题

**1. 连接失败**
- 检查网络连接
- 确认服务器地址和端口
- 验证用户名和密码/密钥

**2. 认证失败**
- 检查用户名和密码
- 确认 SSH 密钥格式正确
- 验证服务器是否允许该认证方式

**3. 终端显示异常**
- 尝试断开重连
- 检查终端编码设置
- 重启应用

**4. 构建失败**
- 运行 `flutter clean`
- 重新执行 `flutter pub get`
- 检查 Android SDK 版本

### 日志调试
启用调试模式查看详细日志：
```bash
flutter run --debug
```

## 🎉 下一步计划

- [x] ~~文件传输功能 (SCP/SFTP)~~ ✅ 已完成
- [x] ~~多标签页支持~~ ✅ 已完成  
- [x] ~~自动更新功能~~ ✅ 已完成
- [ ] 连接分组管理
- [ ] 自定义终端主题
- [ ] 命令历史记录
- [ ] 端口转发功能
- [ ] 批量连接管理
- [ ] 连接导入导出

---

**专为 OPPO Pad 4 Pro 用户打造的专业 SSH 客户端** 🚀