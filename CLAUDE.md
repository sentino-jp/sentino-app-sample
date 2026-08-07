# CLAUDE.md — Sentino Flutter App

## 构建命令

```bash
# Android debug（需要 JAVA_HOME）
JAVA_HOME=/Users/momo/Library/Java/JavaVirtualMachines/corretto-21.0.6/Contents/Home \
  flutter build apk --debug

# Android release
JAVA_HOME=/Users/momo/Library/Java/JavaVirtualMachines/corretto-21.0.6/Contents/Home \
  flutter build apk --release

# iOS（不签名，交给 xcodebuild 统一处理）
flutter build ios --release --no-codesign [--build-number=N]

# iOS Archive & 上传 TestFlight
xcodebuild archive \
  -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release \
  -archivePath /tmp/sentino.xcarchive \
  DEVELOPMENT_TEAM=GT26T8WZV3 CODE_SIGN_STYLE=Automatic -allowProvisioningUpdates

xcodebuild -exportArchive \
  -archivePath /tmp/sentino.xcarchive \
  -exportOptionsPlist ios/ExportOptions.plist \
  -exportPath /tmp/sentino-export -allowProvisioningUpdates

# 代码生成（修改 model 后运行）
dart run build_runner build --delete-conflicting-outputs

# 国际化（修改 .arb 后运行）
flutter gen-l10n
```

## Git Remote

| Remote | URL | 用途 |
|--------|-----|------|
| `origin` | `git@github.com:sentino-jp/sentino-app-sample.git` | 默认，GitHub 公共仓库 |
| `gitea` | `ssh://git@175.178.168.108:222/git_admin_dev/sentino-flutter-app.git` | 内网 Gitea |

主分支：`sentino-flutter-sdk`

## iOS 发布配置

- Bundle ID：`jp.sentino.general`
- Team ID：`GT26T8WZV3`（SENTINO K.K.，daniel.chen@sentino.jp）
- ExportOptions：`ios/ExportOptions.plist`（method: app-store-connect，signingStyle: automatic）
- Build number 每次上传必须递增（App Store Connect 当前最新见 TestFlight 页面）
- **本地没有 Distribution 证书是正常的**：签名走 cloud signing（证书托管在 Apple 侧），
  `security find-identity` 查到 0 张 ≠ 不能发版

### `exportArchive` 报 "Failed to Use Accounts" 时（2026-08-07 实测）

症状：archive 成功，export 失败，日志里是
`Failed to load credentials for <某个旧 Apple ID>, missing Xcode-Token`
或 `Failed to find an account with App Store Connect access for team`。

根因：`xcodebuild` 读 `com.apple.dt.Xcode` 的 `DVTDeveloperAccountManagerAppleIDLists`。
Xcode 26 已改用 `IDE.Identifiers.Prod`+UUID 的新格式并**不再维护**旧的
`IDE.Prod`+明文 username；旧格式里若残留着已失效的账号，`xcodebuild` 加载时
遇到它就整个中止，**不会跳过去用有效账号**。Xcode 界面上看不到这条残留，
退出 Xcode 也不会清掉。

修复（Xcode 必须先 ⌘Q 完全退出，否则会被内存值覆写）：

```sh
defaults export com.apple.dt.Xcode /tmp/xcode-prefs-backup.plist   # 先备份
defaults delete com.apple.dt.Xcode DVTDeveloperAccountManagerAppleIDLists
defaults delete com.apple.dt.Xcode IDEProvisioningTeams
# 再启动 Xcode → Settings → Apple Accounts 点一下账号 → ⌘Q 退出（触发以新格式重建）
# 回滚：defaults import com.apple.dt.Xcode /tmp/xcode-prefs-backup.plist
```

⚠️ 别被中途的假象带偏：
- API key（`-authenticationKeyPath/-ID/-IssuerID`）能绕过账号加载，但若 key 角色
  不是 App Manager/Admin，会改报 `Cloud signing permission error` —— 换汤不换药。
- `EXPORT FAILED` 不等于没上传：先看日志里有没有 `Progress …%: Uploading`。
  真失败时连 ipa 都不会生成（`-exportPath` 目录是空的），据此判断最准。
- 应急通道：archive 拷到 `~/Library/Developer/Xcode/Archives/<日期>/` 后，
  用 Xcode → Organizer → Distribute App 上传，走 GUI 的完整账号会话，不受此问题影响。

## API

- Base URL：`https://api-iot.sentino.jp/api`
- 所有请求必须携带的 headers：`client_id`、`app_id`、`channel_identifier`、`data_center_code`、`os_name`、`version`、`package_name`、`encrypt_type`（见 `lib/utils/api_client.dart`）
- Token 过期错误码：`11013` → 触发强制登出
- 自定义角色创建端点：`business-app/v1/sentino-ai/agents/create`，body 必须包含 `agentType: 'sentino'` 且 `description` 不能为空字符串

## Google 登录

走原生 SDK 直出 id_token → `POST /api/coucou/auth/oauth2/native/google`（coucou 登录态）。
**外部配置（GCP client id、后端 `GOOGLE_NATIVE_AUDIENCES`、`ios/Flutter/Local.xcconfig`）不做就跑不起来**，
见 `doc/google-signin-setup.md`。Android/iOS 包名统一为 `jp.sentino.general`，但 **debug 构建带 `.dev` 后缀**
（`jp.sentino.general.dev`），Android OAuth client 按实际 applicationId 逐条登记。

## Mock 模式

`lib/utils/app_config.dart` → `static bool get useMock => false;` 改为 `true` 切换 Mock。

## Android 真机调试（ZTE W202DS）

- ADB Serial：`1008002699865285070096830`
- 分辨率：1200×1920，density=260，Android 13（API 33）
- 常亮：`adb -s 1008002699865285070096830 shell svc power stayon true`
- 安装：`adb -s 1008002699865285070096830 install -r build/app/outputs/flutter-apk/app-debug.apk`
  - 安装时设备可能弹"允许安装"确认框，需要手动点击或用 uiautomator 自动点击

## 测试账号

见 `doc/test-account.local.md`（不入库）。
