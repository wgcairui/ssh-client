# 🚀 发布策略说明

本项目使用智能化的发布策略，确保用户可以及时获取最新构建的APK文件。

## 📦 发布类型

### 1. 开发版本 (Development Releases)
- **触发条件**: 推送到 `main` 分支
- **标签格式**: `dev-YYYYMMDD-HHMMSS-{commit-hash}`
- **标记**: `prerelease: true`
- **用途**: 日常开发测试，获取最新功能

**示例**: `dev-20241221-143022-a1b2c3d4`

### 2. 正式版本 (Official Releases)  
- **触发条件**: 推送版本标签 (以 `v` 开头)
- **标签格式**: `v1.0.0`, `v1.1.0`, `v2.0.0-beta.1` 等
- **标记**: `prerelease: false`
- **用途**: 稳定版本发布

**示例**: `v1.0.0`, `v1.1.0`, `v2.0.0-beta.1`

## 📱 APK 文件说明

每次发布都会包含以下APK文件：

| 文件名 | 描述 | 推荐设备 |
|--------|------|----------|
| `app-release.apk` | 通用版本 | **所有设备 (推荐)** |
| `app-arm64-v8a-release.apk` | ARM64 优化版 | 现代Android设备 |
| `app-armeabi-v7a-release.apk` | ARM32 兼容版 | 老旧Android设备 |
| `app-x86_64-release.apk` | x86_64 版本 | 模拟器、特殊设备 |

## 🎯 如何获取APK

### 方法1: GitHub Releases (推荐)
1. 访问 [Releases页面](https://github.com/cairui/ssh-client/releases)
2. 选择合适的版本：
   - **最新稳定版**: 查找没有 `Pre-release` 标记的版本
   - **最新开发版**: 查找标有 `Pre-release` 的最新版本
3. 下载对应的APK文件

### 方法2: Actions Artifacts (临时)
1. 访问 [Actions页面](https://github.com/cairui/ssh-client/actions)
2. 选择对应的workflow运行
3. 下载 `Artifacts` 中的APK文件
4. **注意**: Artifacts有保留期限制

## 🔄 发布流程

### 开发版本发布
```bash
# 正常开发流程，推送到main分支即可
git add .
git commit -m "feat: 添加新功能"
git push origin main
```
✅ 自动触发构建和发布

### 正式版本发布
```bash
# 创建版本标签
git tag v1.0.0
git push origin v1.0.0
```
✅ 自动触发构建和正式版本发布

## ⚡ 构建优化

- **缓存策略**: 多层缓存显著提高构建速度
- **并行构建**: 同时生成多架构APK
- **增量更新**: 小改动时构建时间大幅缩短

## 📊 版本管理建议

### 开发过程
- 日常开发推送到 `main` 分支
- 系统会自动生成开发版本供测试
- 开发版本包含最新功能但可能不稳定

### 正式发布
- 确认功能稳定后创建版本标签
- 遵循语义化版本规范 (`MAJOR.MINOR.PATCH`)
- 正式版本经过完整测试，推荐生产使用

## 🎉 优势总结

1. **📦 自动化**: 推送代码即可获得APK
2. **⚡ 快速**: 优化的构建流程，大幅缩短等待时间  
3. **🎯 灵活**: 开发版和正式版并行，满足不同需求
4. **📱 完整**: 多架构APK，兼容所有设备
5. **🔍 透明**: 完整的构建日志和发布记录

---

*这个发布策略确保开发效率和发布质量的完美平衡* ⚖️