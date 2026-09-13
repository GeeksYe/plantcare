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

## 在线打包（推荐，本机无需任何安卓环境）

1. 在 GitHub 新建一个仓库（如 `plantcare`）
2. 把本目录推上去：

   ```bash
   cd plantcare_app
   git init && git add . && git commit -m "init: 绿植管家 Flutter App"
   git branch -M main
   git remote add origin https://github.com/<你的用户名>/plantcare.git
   git push -u origin main
   ```

3. 打开仓库 **Actions** 页 → 选择 **Build APK** → **Run workflow**
4. 构建完成后在该次运行页面的 **Artifacts** 下载 `绿植管家-apk`，解压即得 `app-release.apk`
5. 把 APK 传到手机安装（需允许「安装未知来源应用」）

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
