# 礼金本

婚宴/寿宴礼金记录 App，基于 Flutter 构建。

## 发布流程

**重要：每次 release 必须本地构建 APK 并上传到 GitHub Release。**

### 完整发布步骤

1. **修改代码并 commit**
   ```bash
   git add .
   git commit -m "fix: 描述本次修改"
   ```

2. **本地构建 APK（release 版本）**
   ```bash
   flutter build apk --release
   ```
   产物路径：`build/app/outputs/flutter-apk/app-release.apk`

3. **推送代码到 GitHub**
   ```bash
   git push origin main
   ```

4. **在本地为本次 commit 打 tag**
   ```bash
   git tag v{x.y.z}
   git push origin v{x.y.z}
   ```

5. **创建 GitHub Release**
   - 网页操作：https://github.com/huise513/gift_record/releases → "Draft a new release"
   - 选择对应的 tag
   - **必须上传 `build/app/outputs/flutter-apk/app-release.apk`**（拖拽上传）
   - 填写版本说明

### 版本号规则

- 主版本号.次版本号.修订号（Semantic Versioning）
- 修复小 bug → 修订号 +1
- 新功能 → 次版本号 +1
- 重大变更 → 主版本号 +1

### 注意事项

- `app-release.apk` 必须随 release 一起发布，用户下载 APK 即为最新版本
- debug APK（`app-debug.apk`）无需发布，仅开发调试用
- 每次发布前确保 `flutter build apk --release` 构建成功
- release commit 应保持干净，避免混入 `.dart_tool/flutter_build/` 等构建产物
