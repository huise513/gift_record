# 礼金本

婚宴/寿宴礼金记录 App，基于 Flutter 构建。

## 发布流程

**重要：每次 release 必须构建 APK 并上传到 GitHub Release，全程本地命令完成。**

### 完整发布步骤

1. **修改代码并 commit**
   ```bash
   git add .
   git commit -m "fix: 描述本次修改"
   ```

2. **推送代码到 GitHub**
   ```bash
   git push origin main
   ```

3. **创建 tag 并推送**
   ```bash
   git tag v{x.y.z}
   git push origin v{x.y.z}
   ```

4. **构建 release APK**
   ```bash
   flutter build apk --release
   ```
   产物路径：`build/app/outputs/flutter-apk/app-release.apk`

5. **创建 GitHub Release 并上传 APK**
   ```bash
   gh release create v{x.y.z} --title "v{x.y.z}" --notes "版本说明"
   gh release upload v{x.y.z} build/app/outputs/flutter-apk/app-release.apk
   ```

### 版本号规则

- 主版本号.次版本号.修订号（Semantic Versioning）
- 修复小 bug → 修订号 +1
- 新功能 → 次版本号 +1
- 重大变更 → 主版本号 +1

### 注意事项

- `app-release.apk` 必须随 release 一起发布，用户下载 APK 即为最新版本
- debug APK（`app-debug.apk`）无需发布，仅开发调试用
- `.gitignore` 已包含 `build/`、`.dart_tool/flutter_build/`，确保 commit 不混入构建产物
