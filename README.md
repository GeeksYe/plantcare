# 绿植管家 GreenMate · Android App

基于「绿植养护 App」设计稿高保真还原的原生应用，治愈自然绿风。

## 技术栈

- **Flutter**（原生 Android 宿主 + Flutter UI），目标 **Android 15（targetSdk/compileSdk 35）**
- 暂不接服务器：全部为内置展示数据
- 用户操作数据（昵称 / 浇水打卡 / 提醒设置 / 点赞 / 任务完成）通过 `shared_preferences` **缓存到本地**

## 功能与页面

| 层级 | 页面 |
|---|---|
| 一级 Tab | 养护首页 / AI 识别 / 发现（含分享底部弹层，每行 3 个渠道）/ 我的 |
| 二级 | 植物详情 / 我的花园 / 养护日历 / 提醒设置 / 植物百科 / 关于我们 |
| 三级 | 修改昵称（本地持久化）/ 成长日历（首日→6 个月里程碑） |

## 在线打包（推荐：CNB 云原生构建，国内直连 + 微信登录，本机无需任何安卓环境）

1. 打开 https://cnb.cool ，用**微信扫码**登录（免费，构建每月赠送 160 核时）
2. 右上角「+」新建仓库（如 `plantcare`，**公开**仓库）
3. 头像 → 设置 → 访问令牌 → 新建令牌（勾选仓库读写），把令牌发给助手，由助手推送代码并触发构建
4. 构建自动开始：推送后流水线自动执行 `flutter build apk --release`
5. 构建完成后，打开仓库最新 commit 详情页 → **附件** → 下载 `app-release.apk`，传到手机安装（需允许「安装未知来源应用」）

### 备选：GitHub Actions

工程内含 `.github/workflows/build_apk.yml`，如可访问 GitHub 也可推送后到 Actions 页手动 Run workflow，产物在 Artifacts。

## 本地打包（可选）

需要 Flutter 3.24+ / JDK 17 / Android SDK 35：

```bash
flutter pub get
flutter build apk --release
# 产物：build/app/outputs/flutter-apk/app-release.apk
```

## 说明

- Release 包使用 debug 签名，保证可直接安装体验；正式上架前请在 `android/app/build.gradle` 替换正式 keystore
- 接入真实后端时，替换 `lib/data/mock_data.dart` 为接口数据即可，`lib/services/local_store.dart` 可平滑升级为同步缓存
