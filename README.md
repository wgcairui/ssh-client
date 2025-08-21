# SSH Client for Android

一个现代化的SSH客户端应用，专为Android平板设备优化，特别针对OPPO Pad 4 Pro (13.2英寸) 进行了深度优化。

![Build Status](https://github.com/cairui/ssh-client/workflows/Build%20Android%20APK/badge.svg)

## ✨ 功能特性

### 🔐 安全认证
- **密码认证**: 支持传统用户名/密码登录
- **密钥认证**: 支持SSH私钥文件认证
- **多格式支持**: PEM, OpenSSH, RSA, DSA, EC, PKCS#8, PuTTY等格式
- **文件选择**: 可直接从设备选择密钥文件或手动输入

### 📁 文件传输
- **SFTP支持**: 完整的文件传输功能
- **双向传输**: 支持上传和下载文件
- **进度监控**: 实时显示传输进度
- **批量操作**: 支持同时传输多个文件
- **文件管理**: 远程文件浏览、重命名、删除等操作

### 📱 用户界面
- **平板优化**: 专为13.2英寸大屏设计的分屏布局
- **强制横屏**: 锁定横屏模式以获得最佳终端体验
- **可折叠面板**: 左侧连接列表可折叠以提供更大工作空间
- **响应式设计**: 自适应不同屏幕尺寸
- **Material 3**: 现代化的Material Design 3界面

### 🛠 终端功能
- **完整终端**: 基于xterm的全功能终端模拟器
- **连接管理**: 保存和重用SSH连接配置
- **会话管理**: 支持多个并发SSH会话
- **连接历史**: 自动记录最近使用的连接

## 📱 系统要求

- Android 5.0 (API 21) 或更高版本
- 推荐在平板设备上使用以获得最佳体验
- 支持的屏幕方向：横屏（强制锁定）

## 🚀 快速开始

### 下载APK
1. 前往 [Releases页面](https://github.com/cairui/ssh-client/releases) 下载最新版本
2. 下载 `app-release.apk` 文件
3. 在Android设备上安装APK文件

### 从源码构建
```bash
# 克隆仓库
git clone https://github.com/cairui/ssh-client.git
cd ssh-client

# 安装依赖
flutter pub get

# 构建APK
flutter build apk --release
```

## 🔧 开发环境

### 环境要求
- Flutter 3.27.1 或更高版本
- Dart 3.6.0 或更高版本
- Android SDK (API 21+)
- Java 17

### 主要依赖
- `dartssh2`: SSH连接和SFTP文件传输
- `xterm`: 终端模拟器
- `flutter_screenutil`: 响应式UI适配
- `sqflite`: 本地数据库存储
- `provider`: 状态管理
- `file_picker`: 文件选择

### 开发命令
```bash
# 获取依赖
flutter pub get

# 代码分析
flutter analyze

# 运行测试
flutter test

# 调试运行
flutter run

# 构建APK
flutter build apk --debug    # 调试版本
flutter build apk --release  # 正式版本
```

## 🏗️ CI/CD

项目使用GitHub Actions进行自动化构建：

### 构建触发条件
- **推送到主分支**: 自动构建并生成APK文件
- **Pull Request**: 运行测试和代码分析
- **标签发布**: 自动创建GitHub Release
- **夜间构建**: 每日凌晨2点自动构建

### 构建产物
- **调试版APK**: 用于开发测试
- **正式版APK**: 用于发布分发
- **构建报告**: 包含测试结果和代码分析

## 📖 使用指南

### 添加SSH连接
1. 点击主界面的"添加连接"按钮
2. 填写服务器信息（名称、地址、端口、用户名）
3. 选择认证方式：
   - **密码认证**: 输入登录密码
   - **密钥认证**: 选择私钥文件或粘贴私钥内容
4. 保存连接配置

### 建立SSH连接
1. 在连接列表中选择要连接的服务器
2. 右侧会显示终端界面并自动连接
3. 连接成功后可以执行各种SSH命令

### 文件传输
1. 建立SSH连接后，点击终端标题栏的文件夹图标
2. 浏览远程服务器文件系统
3. 上传文件：点击上传按钮选择本地文件
4. 下载文件：点击文件的下载按钮选择保存位置
5. 在底部面板查看传输进度

### 面板折叠
- 点击左侧面板的菜单按钮可以折叠/展开连接列表
- 折叠后可以为终端提供更大的显示空间

## 🤝 贡献指南

欢迎提交Issue和Pull Request来改进此项目！

### 开发流程
1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启Pull Request

### 代码规范
- 使用Dart官方代码风格
- 添加必要的注释和文档
- 确保所有测试通过
- 遵循现有的项目结构

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🙏 致谢

- [dartssh2](https://pub.dev/packages/dartssh2) - SSH连接库
- [xterm](https://pub.dev/packages/xterm) - 终端模拟器
- [Flutter](https://flutter.dev/) - UI框架
- [Material Design 3](https://m3.material.io/) - 设计系统

## 📞 支持

如果您遇到问题或有功能建议，请：
1. 查看 [Issues](https://github.com/cairui/ssh-client/issues) 页面
2. 创建新的Issue描述问题
3. 提供详细的复现步骤和设备信息

---

*专为平板设备打造的现代SSH客户端* 🚀
