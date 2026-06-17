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

## API

- Base URL：`https://api-iot.sentino.jp/api`
- 所有请求必须携带的 headers：`client_id`、`app_id`、`channel_identifier`、`data_center_code`、`os_name`、`version`、`package_name`、`encrypt_type`（见 `lib/utils/api_client.dart`）
- Token 过期错误码：`11013` → 触发强制登出
- 自定义角色创建端点：`business-app/v1/sentino-ai/agents/create`，body 必须包含 `agentType: 'sentino'` 且 `description` 不能为空字符串

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
