# Sentino Flutter 快速入门指南

本指南帮助初学者在 30 分钟内完成项目搭建、运行和基本功能接入。

## 1. 环境准备

```bash
# 确认 Flutter 版本
flutter --version  # 需要 >= 3.11.4

# 克隆项目
git clone https://github.com/sentino-jp/sentino-app-sample.git
cd sentino-app-sample
```

## 2. 安装依赖

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
```

## 3. 运行项目

```bash
# Android
flutter run

# Windows
flutter run -d windows

# 打包 APK
flutter build apk --release

# 打包 Windows exe
flutter build windows --release
```

## 4. 项目结构速览

```
lib/
├── main.dart              # 入口，Provider 注册
├── utils/
│   ├── app_config.dart    # ★ 核心配置（API地址、MQTT、AppID）
│   ├── api_client.dart    # HTTP 客户端（自动注入 Header）
│   └── storage.dart       # 本地存储（Token、UserId）
├── models/                # 数据模型
├── repositories/api/      # API 接口实现
├── services/              # 业务逻辑
├── providers/             # 状态管理
├── pages/                 # UI 页面
└── l10n/                  # 国际化
```

## 5. 修改配置接入自己的服务

编辑 `lib/utils/app_config.dart`：

```dart
// 改为你的 API 地址
static const String baseUrl = 'https://your-api.com/api';

// 改为你的 AppID
static const String appId = 'your_app_id';

// 改为你的 MQTT 地址
static const String mqttHost = 'your-mqtt.com';
static const int mqttPort = 1883;
```

## 6. 核心业务流程

### 6.1 用户登录

```
用户输入邮箱密码 → 调用 /auth/oauth/token → 保存 Token 和 UserId → 跳转首页
```

### 6.1.1 用户注册

```
输入邮箱+密码+确认密码 → 发送验证码(sendRegisterCode) → 输入验证码 → 注册(registryByUserName) → 跳回登录页
```

### 6.1.2 忘记密码

```
输入邮箱 → 发送验证码(sendFindPasswordCode) → 输入验证码 → 设置新密码+确认密码 → 重置(resetPassword) → 跳回登录页
```

关键文件：
- `lib/pages/auth/login_page.dart` — 登录 UI
- `lib/providers/auth_provider.dart` — 登录状态管理
- `lib/services/auth_service.dart` — 登录业务逻辑

### 6.2 设备配网（BLE）

```
扫描蓝牙 → 选择设备 → 输入WiFi → 连接设备 → 发送配网数据 → 等待绑定 → 完成
```

关键文件：
- `lib/pages/device/ble_pairing_page.dart` — 配网 UI 和流程
- `lib/services/ble_service.dart` — BLE 扫描/连接/发送
- `lib/utils/generic_ble_packet_protocol.dart` — BLE 分包协议

### 6.3 设备管理

```
首页设备列表 → 点击设备 → 设备面板（智能体/音量/对话） → 设备详情（信息/升级/解绑）
```

关键文件：
- `lib/pages/home/device_tab.dart` — 设备列表
- `lib/pages/device/device_panel_page.dart` — 设备面板
- `lib/pages/device/device_detail_page.dart` — 设备详情

### 6.4 智能体管理

```
智能体列表（推荐/自定义） → 创建/编辑/删除 → 绑定到设备
```

关键文件：
- `lib/pages/home/agent_tab.dart` — 智能体列表
- `lib/pages/agent/agent_create_page.dart` — 创建/编辑
- `lib/pages/agent/agent_detail_page.dart` — 详情

## 7. 添加新接口

按照分层架构，添加一个新接口需要 4 步：

### Step 1: Repository 抽象层

`lib/repositories/device_repository.dart`：
```dart
abstract class DeviceRepository {
  Future<void> myNewMethod(String param);
}
```

### Step 2: API 实现

`lib/repositories/api/api_device_repository.dart`：
```dart
@override
Future<void> myNewMethod(String param) async {
  await _api.post('business-app/v1/device/myEndpoint', data: {'param': param});
}
```

### Step 3: Service 层

`lib/services/device_service.dart`：
```dart
Future<void> myNewMethod(String param) => _repository.myNewMethod(param);
```

### Step 4: Provider 层

`lib/providers/device_provider.dart`：
```dart
Future<void> myNewMethod(String param) async {
  _isLoading = true;
  notifyListeners();
  try {
    await _deviceService.myNewMethod(param);
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
```

## 8. 添加新页面

### Step 1: 创建页面文件

`lib/pages/my_feature/my_page.dart`：
```dart
class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text('My Page')),
      body: Center(child: Text('Hello')),
    );
  }
}
```

### Step 2: 注册路由

`lib/routes/app_router.dart`：
```dart
GoRoute(
  path: '/my-page',
  builder: (context, state) => const MyPage(),
),
```

### Step 3: 添加国际化文本

在 `lib/l10n/app_zh.arb`、`app_en.arb`、`app_ja.arb` 中添加：
```json
"myPageTitle": "我的页面"
```

运行 `flutter gen-l10n`。

## 9. BLE 配网数据格式

### 发送给设备的 JSON

```json
{
  "type": "thing.network.set",
  "msgId": "1234567890001",
  "ts": 1234567890,
  "data": {
    "sid": "WiFi名称",
    "pw": "WiFi密码",
    "mq": "mqtt.sentino.jp",
    "port": 2883,
    "bid": "资产ID",
    "userId": "用户ID",
    "country": "CN",
    "tz": "Asia/Shanghai",
    "force_bind": true
  }
}
```

### BLE 分包协议

```
帧格式: FF + type(1B) + seq(2B) + totalPackets(2B) + totalLength(2B) + dataLength(1B) + data(nB) + checksum(1B)
```

- MTU 默认 128 字节
- 每包间隔 130ms
- checksum = 所有字段字节之和 & 0xFF

## 10. 常见问题

### Q: 蓝牙扫描不到设备？
- 确认 Android 权限已授予（蓝牙 + 位置）
- 确认设备处于配网模式（广播名为 "RY"）
- 确认 `AndroidManifest.xml` 中 `BLUETOOTH_SCAN` 没有 `neverForLocation`

### Q: API 返回 401？
- Token 过期，需要重新登录
- 检查 `app_id` 和 `client_id` 是否正确

### Q: MQTT 连接失败 notAuthorized？
- 确认 `userId` 是登录返回的数字 ID，不是用户名
- 确认 `appId` 用于 HMAC-SHA256 签名的 key 正确

### Q: 配网成功但设备列表不显示？
- 检查 `checkBindResult` 接口返回值是否为 `0`
- 确认配网数据中 `bid`（资产ID）正确
- 确认 `userId` 正确

### Q: 如何切换 Mock/真实 API？
修改 `lib/utils/app_config.dart`：
```dart
static bool get useMock => true;  // true=Mock, false=真实API
```

## 11. 打包发布

```bash
# Android APK
flutter build apk --release
# 输出: build/app/outputs/flutter-apk/app-release.apk

# Windows exe
flutter build windows --release
# 输出: build/windows/x64/runner/Release/

# 生成 App 图标
dart run flutter_launcher_icons
```
