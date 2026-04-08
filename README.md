# AG Play

AG Play 是一款基于 Flutter 3.x 构建的跨平台 IoT 智能设备管理应用，支持 Android 和 iOS 双平台。

[English](README-EN.md)

## 功能特性

- **用户认证** — 登录、注册、忘记密码、修改密码，支持令牌持久化自动登录
- **设备管理** — 设备列表、设备详情（固件版本、MAC 地址、信号强度）、解绑设备
- **蓝牙配网** — 扫描附近 BLE 设备、配置 WiFi、绑定到账户
- **4G 配网** — 通过 5 位绑定码绑定设备
- **智能体管理** — 浏览推荐智能体、创建/删除自定义智能体、绑定智能体到设备
- **OTA 升级** — 检查固件更新、下载与烧录进度跟踪
- **主题** — 明亮/暗黑/跟随系统模式，深红色品牌色（红色向黑色渐变）
- **国际化** — 支持简体中文（zh_CN）、日语（ja_JP）、英语（en_US），基于 ARB 文件的可扩展架构
- **语言跟随系统** — API 请求自动携带 `language` 参数（如 `zh_CN`、`en_US`、`ja_JP`），跟随设备系统语言

## 架构

```
Pages / Widgets（UI 层）
    ↓
Providers（状态管理 - provider）
    ↓
Services（业务逻辑层）
    ↓
Repositories（数据访问抽象层）
    ├── mock/   （Mock 模拟数据，用于开发）
    └── api/    （真实 API 实现，基于 Dio）
    ↓
Models / Theme / Utils（模型 / 主题 / 工具）
```

## 技术栈

| 依赖包 | 用途 |
|--------|------|
| `provider` | 状态管理 |
| `go_router` | 声明式路由，支持登录状态守卫 |
| `dio` | HTTP 网络请求 |
| `shared_preferences` | 本地键值存储 |
| `flutter_blue_plus` | BLE 蓝牙通信 |
| `json_annotation` + `json_serializable` | JSON 序列化 |
| `flutter_localizations` + `intl` | 国际化 |

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
├── pages/                        # UI 页面（启动页、认证、首页、设备、智能体、OTA、设置）
├── widgets/                      # 可复用 UI 组件
├── routes/                       # go_router 路由配置
├── theme/                        # 颜色与主题配置
├── l10n/                         # ARB 国际化文件与生成代码
└── utils/                        # 常量、验证器、存储工具、API 客户端
```

## 配置

编辑 `lib/utils/app_config.dart` 切换 Mock 或真实 API：

```dart
class AppConfig {
  static const bool useMock = true;           // true=Mock 模拟数据, false=真实 API
  static const String baseUrl = 'https://api.example.com/';
}
```

## 快速开始

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## 添加新语言

1. 创建 `lib/l10n/app_xx.arb` 翻译文件
2. 运行 `flutter gen-l10n`
3. 在 `lib/providers/locale_provider.dart` 的 `SupportedLocales.all` 中添加新的 `Locale`
