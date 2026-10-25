# ZCode Web

扫码打开网页的 Android 壳应用：全屏相机扫码 → 识别网址二维码 → 内置 WebView 全屏打开，站内跳转不弹外部浏览器。

## 功能

- **扫码打开**：Camera2 实时预览 + ZXing 解码，仅识别取景框内区域，扫到网址自动打开
- **相册识别**：从相册选图解码二维码
- **状态恢复**：Cookie / DOM Storage 持久化，再次打开自动回到上次页面；返回键可回扫码页重新扫
- **缓存兜底**：HTTP 缓存 + 断网自动切 `LOAD_CACHE_ELSE_NETWORK`
- **返回确认**：网页首层返回 → 确认回扫码页；扫码页返回 → 确认退出
- **R8 混淆收缩**，APK ~160 KB

## 构建

无 gradle，纯 `aapt2 + javac + R8 + zipalign + apksigner` 管线：

```bash
bash build.sh   # 需要 ANDROID_HOME（build-tools + platforms），本地放 release.keystore 则签名稳定
```

产物：`ZCodeWeb.apk`；混淆映射：`build/dex/mapping.txt`（崩溃堆栈还原用）。

## 发布

推 tag 自动构建并发布 Release：

```bash
git tag v1.0.0 && git push origin v1.0.0
```

CI：`.github/workflows/release.yml`（ubuntu runner + build-tools 34 + R8，产物自动挂 Release）。

## 结构

```
AndroidManifest.xml          清单（INTERNET/CAMERA 权限）
src/ai/zcode/web/
  MainActivity.java          扫码 + WebView + 状态恢复
  ScannerOverlay.java        取景框遮罩/角标/扫描线动画
res/mipmap-*                 应用图标（Pillow 生成，设计稿 art/ic_launcher.svg）
r8-rules.pro                 R8 keep/dontwarn 规则
build.sh                     一键构建（本地/CI 通用）
```
