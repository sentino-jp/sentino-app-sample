# Sentino

Sentino 是一款基于 Flutter 3.x 构建的跨平台 IoT 智能设备管理应用，支持 Android、iOS、Windows、Web 多平台。

[English](README-EN.md)

## 功能特性

- **用户认证** — 登录、注册（邮箱验证码验证）、忘记密码（三步流程：邮箱→验证码→新密码）、修改密码（修改成功自动登出），邮箱格式校验，令牌持久化自动登录
- **设备管理** — 设备列表（含设备数量统计）、设备详情、设备面板、解绑设备
- **配网** — 蓝牙配网（雷达扫描 + 设备列表）、蓝牙直连、4G 绑定码配网、条码配网、扫码配网，统一通过右上角 + 入口
- **智能体管理** — 浏览推荐/Sentino 智能体、创建/编辑/删除自定义智能体（绑定 Sentino 平台凭证）、绑定智能体到设备、设备面板切换智能体、音色试听
- **MQTT** — 实时设备消息推送，支持网络信号检测结果接收
- **网络检测** — 设备信号强度检测（通过 MQTT 接收结果）
- **OTA 升级** — 检查固件更新、下载与烧录进度跟踪
- **用户中心** — 修改头像、修改昵称、清理缓存、退出登录
- **对话历史** — 查看设备/智能体对话记录，支持清空
- **主题** — 明亮/暗黑/跟随系统模式，深红色品牌色
- **国际化** — 简体中文、日语、英语，切换时 API header 实时同步

## 架构

```
Pages / Widgets（UI 层）
    ↓
Providers（状态管理 - provider）
    ↓
Services（业务逻辑层）
    ↓
Repositories（数据访问抽象层）
    ├── mock/   （Mock 模拟数据）
    └── api/    （真实 API - Dio）
    ↓
Models / Theme / Utils
```

## 技术栈

| 依赖包 | 用途 |
|--------|------|
| `provider` | 状态管理 |
| `go_router` | 声明式路由，登录状态守卫 |
| `dio` | HTTP 网络请求 |
| `shared_preferences` | 本地键值存储 |
| `flutter_blue_plus` | BLE 蓝牙通信 |
| `mqtt_client` | MQTT 实时消息推送 |
| `json_annotation` + `json_serializable` | JSON 序列化 |
| `flutter_localizations` + `intl` | 国际化 |
| `flutter_launcher_icons` | 多平台 App 图标生成 |
| `permission_handler` | 运行时权限管理 |
| `wifi_scan` | WiFi 扫描（配网） |
| `audioplayers` | 音频播放（音色试听） |
| `image_picker` | 头像图片选取 |

## 项目结构

```
lib/
├── main.dart / app.dart          # 应用入口，MultiProvider 配置
├── models/                       # 数据模型（含 JSON 序列化）
├── repositories/
│   ├── mock/                     # Mock 模拟实现
│   └── api/                      # 真实 API 实现（Dio）
├── services/                     # 业务逻辑层
├── providers/                    # 状态管理（ChangeNotifier）
├── pages/                        # UI 页面（启动页、认证、设备、智能体、OTA、设置、我的）
├── widgets/                      # 可复用 UI 组件
├── routes/                       # go_router 路由配置
├── theme/                        # 颜色与主题配置
├── l10n/                         # ARB 国际化文件与生成代码
├── utils/                        # 常量、验证器、存储工具、API 客户端
└── skills/                       # 智能体 Skills SDK 初始化配置
```

## 快速开始

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## 打包

### Android APK

```bash
# debug
flutter build apk --debug

# release（需要 JDK 21）
JAVA_HOME=/Library/Java/JavaVirtualMachines/corretto-21.0.6/Contents/Home \
  flutter build apk --release
```

> 完整打包环境配置见 [doc/build-guide.md](doc/build-guide.md)

### iOS（TestFlight / App Store）

```bash
# 1. 构建（不签名）
flutter build ios --release --no-codesign

# 2. Archive（自动签名，需要 Xcode 登录 App Store Connect 账号）
xcodebuild archive \
  -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -archivePath /tmp/sentino.xcarchive \
  DEVELOPMENT_TEAM=GT26T8WZV3 \
  CODE_SIGN_STYLE=Automatic \
  -allowProvisioningUpdates

# 3. 导出并上传到 TestFlight
xcodebuild -exportArchive \
  -archivePath /tmp/sentino.xcarchive \
  -exportOptionsPlist ios/ExportOptions.plist \
  -exportPath /tmp/sentino-export \
  -allowProvisioningUpdates
```

Build number 递增：`flutter build ios --release --no-codesign --build-number=N`

### Windows

```bash
flutter build windows --release
```

## Mock 模式

`lib/utils/app_config.dart` 中将 `useMock` 改为 `true` 可切换到 Mock 数据，无需后端即可开发调试。

## 添加新语言

1. 创建 `lib/l10n/app_xx.arb` 翻译文件
2. 运行 `flutter gen-l10n`

## 权限说明

### Android
- 蓝牙扫描/连接（BLUETOOTH_SCAN、BLUETOOTH_CONNECT）
- 位置（ACCESS_FINE_LOCATION — BLE/WiFi 扫描需要）
- 网络（INTERNET）

### iOS
- 蓝牙（NSBluetoothAlwaysUsageDescription）
- 位置（NSLocationWhenInUseUsageDescription、NSLocationAlwaysAndWhenInUseUsageDescription）
- 相机（NSCameraUsageDescription — 扫码）
- 相册（NSPhotoLibraryUsageDescription — 头像）
