# 更新日志

此文件记录了此项目的所有重要更改。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，
并且此项目遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [未发布]

### 新增
- **多标签页支持**: 实现同时管理最多10个SSH连接的标签页功能
- **智能焦点管理**: 全新的单终端实例多状态管理方案，彻底解决标签页切换时的键盘输入问题
- **会话保持机制**: SSH连接在后台保持活跃状态，避免服务器超时断开
- **标签页管理器**: 新增 `SshTabController` 统一管理所有标签页状态
- **单终端管理器**: 新增 `SingleTerminalManager` 优化多终端显示和输入处理

### 改进
- **用户界面**: 标签页栏支持动态宽度计算，避免多标签时互相重叠
- **连接复用**: 选择已打开的连接时直接切换到对应标签页，而非重新创建连接
- **性能优化**: 使用单个 `TerminalView` 实例减少内存消耗和渲染开销
- **状态管理**: 每个标签页独立维护SSH会话和终端状态

### 修复
- **焦点管理**: 解决标签页切换时键盘输入路由到错误终端的问题
- **连接状态**: 修复标签页切换时重新创建连接的问题
- **内存泄漏**: 优化终端实例和SSH会话的生命周期管理

### 技术细节
- 新增文件: `lib/models/ssh_tab.dart` - SSH标签页数据模型
- 新增文件: `lib/controllers/ssh_tab_controller.dart` - 标签页状态管理
- 新增文件: `lib/widgets/ssh_tab_bar.dart` - 标签页栏UI组件
- 新增文件: `lib/widgets/single_terminal_manager.dart` - 单终端管理器
- 修改文件: `lib/views/home_view_with_tabs.dart` - 主界面支持标签页
- 修改文件: `lib/controllers/ssh_session_controller.dart` - 增加向指定会话发送输入的方法
- 修改文件: `lib/services/ssh_service.dart` - 添加保活机制

### 架构变更
- **从多终端实例到单终端实例**: 彻底重构终端显示架构，解决Flutter中多个TerminalView组件的焦点冲突问题
- **状态分离**: 将终端显示与SSH会话状态完全分离，每个标签页独立管理状态
- **动态绑定**: 标签页切换时动态绑定对应的终端状态到显示组件

## [1.0.0] - 2024-XX-XX

### 新增
- SSH连接管理功能
- 终端模拟器支持
- SFTP文件传输功能
- 多种SSH认证方式支持
- 平板优化的响应式界面
- 连接历史记录
- 安全的本地数据存储

### 技术栈
- Flutter 3.27.1+
- Dart 3.6.0+
- dartssh2 2.9.0 - SSH连接
- xterm 4.0.0 - 终端模拟器
- provider 6.1.2 - 状态管理
- sqflite 2.3.3+ - 本地数据库
- flutter_screenutil 5.9.3 - 响应式UI

---

**注**: 版本号遵循语义化版本规范 (Major.Minor.Patch)
- **Major**: 不兼容的API修改
- **Minor**: 向后兼容的功能性新增
- **Patch**: 向后兼容的问题修正