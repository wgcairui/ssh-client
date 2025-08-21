# GitHub Actions 缓存策略

本文档描述了为 SSH 客户端项目配置的 GitHub Actions 缓存策略，旨在大幅提高构建速度。

## 🚀 缓存优化概览

### 缓存层级
我们实现了多层缓存策略来最大化构建效率：

1. **Flutter SDK 缓存** (已内置在 flutter-action 中)
2. **Pub 依赖缓存**
3. **Gradle Wrapper 缓存**  
4. **Gradle 依赖缓存**
5. **Android 构建输出缓存**

### 预期性能提升

| 构建类型 | 无缓存时间 | 有缓存时间 | 提升幅度 |
|---------|-----------|-----------|---------|
| 冷启动构建 | 8-12 分钟 | 8-12 分钟 | 0% |
| 依赖未变更 | 8-12 分钟 | 3-5 分钟 | 50-60% |
| 小代码变更 | 8-12 分钟 | 2-4 分钟 | 60-75% |

## 📦 缓存配置详情

### 1. Pub 依赖缓存
```yaml
- name: Cache Pub dependencies
  uses: actions/cache@v4
  with:
    path: |
      ~/.pub-cache
      **/.dart_tool
      **/.packages
    key: ${{ runner.os }}-pub-${{ hashFiles('**/pubspec.lock') }}
    restore-keys: |
      ${{ runner.os }}-pub-
```

**缓存内容**: Flutter/Dart 包依赖
**更新条件**: `pubspec.lock` 文件变更时
**命中率**: 高（依赖变更不频繁）

### 2. Gradle Wrapper 缓存
```yaml
- name: Cache Gradle Wrapper
  uses: actions/cache@v4
  with:
    path: ~/.gradle/wrapper
    key: ${{ runner.os }}-gradle-wrapper-${{ hashFiles('**/gradle/wrapper/gradle-wrapper.properties') }}
    restore-keys: |
      ${{ runner.os }}-gradle-wrapper-
```

**缓存内容**: Gradle 可执行文件
**更新条件**: Gradle 版本升级时
**命中率**: 极高（Gradle 版本变更很少）

### 3. Gradle 依赖缓存
```yaml
- name: Cache Gradle Dependencies
  uses: actions/cache@v4
  with:
    path: |
      ~/.gradle/caches
      ~/.gradle/buildOutputCleanup
    key: ${{ runner.os }}-gradle-caches-${{ hashFiles('**/*.gradle', '**/gradle.properties', '**/gradle/wrapper/gradle-wrapper.properties') }}
    restore-keys: |
      ${{ runner.os }}-gradle-caches-
```

**缓存内容**: Android 依赖包和构建缓存
**更新条件**: Gradle 配置文件变更时
**命中率**: 高（Android 依赖变更不频繁）

### 4. Android 构建缓存
```yaml
- name: Cache Android Build
  uses: actions/cache@v4
  with:
    path: |
      android/app/build
      android/build
      android/.gradle
    key: ${{ runner.os }}-android-build-${{ hashFiles('android/**/*.gradle', 'android/**/gradle.properties', 'pubspec.lock') }}
    restore-keys: |
      ${{ runner.os }}-android-build-
```

**缓存内容**: 编译的中间文件和构建输出
**更新条件**: Android 配置或依赖变更时
**命中率**: 中等（代码变更会影响部分缓存）

## 🔧 构建优化

### Release 构建优化
```bash
flutter build apk --release \
  --dart-define=FLUTTER_WEB_AUTO_DETECT=true \
  --split-per-abi \
  --obfuscate \
  --split-debug-info=build/app/outputs/symbols
```

**优化特性**:
- ✅ **代码混淆**: 增强安全性和减小体积
- ✅ **架构分离**: 生成针对不同CPU架构的单独APK
- ✅ **调试符号分离**: 便于崩溃分析，同时减小APK体积
- ✅ **Web自动检测**: 优化Web相关代码

### Debug 构建优化
```bash
flutter build apk --debug \
  --dart-define=FLUTTER_WEB_AUTO_DETECT=true \
  --no-tree-shake-icons
```

**优化特性**:
- ✅ **保留图标**: 确保调试版本图标完整
- ✅ **快速构建**: 跳过不必要的优化步骤

## 🗂️ 产物管理

### APK 文件结构
```
build/app/outputs/flutter-apk/
├── app-debug.apk                    # Debug 版本
├── app-release.apk                  # Release 通用版本
├── app-arm64-v8a-release.apk       # ARM64 版本
├── app-armeabi-v7a-release.apk     # ARM32 版本
└── app-x86_64-release.apk          # x86_64 版本
```

### 上传策略
- **Debug APK**: 保留30天
- **Release APK**: 保留90天
- **调试符号**: 保留90天，用于崩溃分析

## 🎯 最佳实践

### 缓存键设计
1. **精确性**: 使用文件哈希确保缓存精确性
2. **回退策略**: 使用 `restore-keys` 提供回退选项
3. **命名空间**: 使用 `runner.os` 区分不同操作系统

### 缓存失效策略
1. **主动失效**: 关键配置文件变更时自动失效
2. **时间失效**: GitHub 默认7天未使用的缓存会被清理
3. **空间限制**: 仓库缓存总量限制为10GB

## 📊 监控指标

### 关键指标
- **构建时间**: 从开始到APK生成的总时间
- **缓存命中率**: 各层缓存的命中百分比
- **依赖下载时间**: Pub和Gradle依赖下载耗时
- **编译时间**: 纯编译过程耗时

### 监控方法
1. 在GitHub Actions日志中查看缓存命中/未命中
2. 比较带缓存和无缓存的构建时间
3. 观察依赖下载步骤的耗时变化

## 🔄 维护建议

### 定期检查
- **月度**: 检查缓存使用情况和构建时间趋势
- **版本更新时**: 验证新版本Flutter/Gradle的缓存兼容性
- **依赖大更新时**: 清理无效缓存，重新建立缓存基线

### 故障排查
当构建时间异常增长时：
1. 检查缓存是否命中
2. 验证缓存键是否正确
3. 查看依赖是否有大幅变更
4. 考虑手动清理GitHub仓库缓存

---

*此缓存策略将随着项目发展和GitHub Actions功能更新而持续优化*