# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Build
```bash
flutter build apk --release
```

### Test
```bash
flutter test
```

### Run
```bash
flutter run
```

### Lint
```bash
flutter analyze
```

### Get Dependencies
```bash
flutter pub get
```

## Architecture

### Project Structure
这是一个基于 Flutter 的 SSH 客户端应用，专为 OPPO Pad 4 Pro (13.2英寸) 平板优化。应用采用 MVC 架构模式：

```
lib/
├── main.dart              # 应用入口
├── models/                # 数据模型
│   └── ssh_connection.dart
├── views/                 # 视图层
│   ├── home_view.dart
│   └── add_connection_view.dart
├── controllers/           # 控制器层
│   └── ssh_controller.dart
├── services/             # 服务层
│   └── database_service.dart
├── widgets/              # UI 组件
│   ├── connection_list_widget.dart
│   ├── connection_item_widget.dart
│   └── terminal_widget.dart
└── utils/                # 工具类
```

### Key Components

#### 数据层
- **SshConnection Model**: SSH 连接配置的数据模型
- **DatabaseService**: SQLite 数据库操作服务，负责连接配置的持久化存储

#### 控制层
- **SshController**: 使用 Provider 进行状态管理，处理连接的增删改查操作

#### 视图层
- **HomeView**: 主界面，采用响应式布局适配平板横竖屏
  - 横屏模式：左侧连接列表 + 右侧终端面板的分屏布局
  - 竖屏模式：堆叠布局或抽屉导航
- **AddConnectionView**: 添加/编辑连接的表单页面

#### 组件层
- **ConnectionListWidget**: 连接列表组件，支持搜索和筛选
- **ConnectionItemWidget**: 单个连接项的卡片组件
- **TerminalWidget**: 终端模拟器组件（占位符，待实现）

#### 技术栈
- **Flutter 3.x**: 跨平台 UI 框架
- **dartssh2**: SSH 连接库
- **sqflite**: SQLite 本地数据库
- **provider**: 状态管理
- **flutter_screenutil**: 响应式设计适配
- **xterm**: 终端模拟器组件

### 设备优化
专为 OPPO Pad 4 Pro 优化：
- 分辨率: 2160x1440 适配
- 充分利用 13.2 英寸大屏空间
- 横屏分屏布局提升使用体验
- Material 3 设计语言