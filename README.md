# Sentino

Sentino 是一款基于 Flutter 3.x 构建的跨平台 IoT 智能设备管理应用，支持 Android、iOS、Windows、Web 多平台。

[English](README-EN.md)

## 功能特性

- **用户认证** — 登录、注册、忘记密码、修改密码（修改成功自动登出），支持令牌持久化自动登录
- **设备管理** — 设备列表（含设备数量统计）、设备详情、设备面板、解绑设备
- **配网** — 蓝牙配网、4G 绑定码配网、条码配网、扫码配网，统一通过右上角 + 入口
- **智能体管理** — 浏览推荐/Sentino 智能体、创建/编辑/删除自定义智能体、绑定智能体到设备、设备面板切换智能体
- **OTA 升级** — 检查固件更新、下载与烧录进度跟踪
- **用户中心** — 修改头像、修改昵称、退出登录
- **主题** — 明亮/暗黑/跟随系统模式，深红色品牌色（红色向黑色渐变）
- **国际化** — 支持简体中文（zh_CN）、日语（ja_JP）、英语（en_US），切换语言时 API header 实时同步
- **App 图标** — 使用 flutter_launcher_icons 自动生成多平台图标

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
| `go_router` | 声明式路由，支持登录状态守卫 |
| `dio` | HTTP 网络请求 |
| `shared_preferences` | 本地键值存储 |
| `flutter_blue_plus` | BLE 蓝牙通信 |
| `json_annotation` + `json_serializable` | JSON 序列化 |
| `flutter_localizations` + `intl` | 国际化 |
| `flutter_launcher_icons` | 多平台 App 图标生成 |

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
└── utils/                        # 常量、验证器、存储工具、API 客户端
```

## 快速开始

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

### 打包 Windows

```bash
flutter build windows --release
```

### 生成 App 图标

```bash
dart run flutter_launcher_icons
```

## 添加新语言

1. 创建 `lib/l10n/app_xx.arb` 翻译文件
2. 运行 `flutter gen-l10n`
