# Sentino Flutter IoT 接入文档

## 1. 概述

Sentino 是一款基于 Flutter 构建的跨平台 IoT 智能设备管理应用，支持 Android、iOS、Windows、Web。本文档详细描述从设备配网到业务流程处理的完整接入流程。

## 2. 环境要求

- Flutter SDK >= 3.11.4
- Dart SDK >= 3.11.4
- Android Studio / Xcode（移动端开发）
- 蓝牙 4.0+ 设备（BLE 配网）

## 3. 项目配置

### 3.1 核心配置文件

所有业务配置集中在 `lib/utils/app_config.dart`：

```dart
class AppConfig {
  static const String baseUrl = 'https://api.cetus-ai.com/api';  // API 基础地址
  static const String appId = 'cnsgdnmp2xhgf8';                  // 应用 ID
  static const String clientId = 'Y2V0dXM...';                   // 客户端标识
  static const String mqttHost = 'mqtt.cetus-ai.com';             // MQTT 地址
  static const int mqttPort = 2883;                                // MQTT 端口
  static const String agentPlatform = 'sentino';                  // 智能体平台
  static const String dataCenterCode = 'cn';                      // 数据中心
}
```

### 3.2 Android 权限配置

`android/app/src/main/AndroidManifest.xml`：

```xml
<uses-permission android:name="android.permission.BLUETOOTH"/>
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN"/>
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"/>
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

### 3.3 iOS 权限配置

`ios/Runner/Info.plist`：

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>需要蓝牙权限来发现和配对 IoT 设备</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>需要位置权限来扫描附近的蓝牙和 WiFi 设备</string>
<key>NSCameraUsageDescription</key>
<string>需要相机权限来扫描二维码和条形码</string>
```

## 4. 架构分层

```
Pages / Widgets（UI 层）
    ↓
Providers（状态管理 - ChangeNotifier）
    ↓
Services（业务逻辑层）
    ↓
Repositories（数据访问抽象层）
    ├── mock/   （Mock 模拟数据）
    └── api/    （真实 API - Dio）
    ↓
Models / Theme / Utils
```

## 5. 用户认证流程

### 5.1 登录

```
POST /auth/oauth/token
Content-Type: application/x-www-form-urlencoded

username={账号}&password={密码}&areaCode=86&countryKey=CN&grant_type=password
```

响应中包含 `access_token`、`userId`、`memberId`。

代码位置：`lib/repositories/api/api_auth_repository.dart`

```dart
final resp = await _api.postForm('/auth/oauth/token', data: {
  'username': uid,
  'password': password,
  'areaCode': areaCode,
  'countryKey': countryKey,
  'grant_type': 'password',
});
```

### 5.2 Token 持久化

登录成功后，`access_token` 和 `userId` 存储在 `SharedPreferences` 中：
- `StorageUtil.saveAccessToken(token)`
- `StorageUtil.saveUserId(userId)`

API 请求通过 `ApiClient` 拦截器自动注入 Header：
- `Authorization: Bearer {token}`
- `app_id`、`client_id`、`language`、`version` 等

## 6. 设备配网流程

### 6.1 BLE 蓝牙配网（WiFi+BLE 双模）

#### 流程图

```
扫描 BLE 设备 → 选择设备 → 输入 WiFi 信息 → 连接设备 → 发送配网数据 → 轮询绑定结果
```

#### Step 1: BLE 扫描

```dart
// 过滤设备名为 "RY" 的 BLE 设备
await FlutterBluePlus.startScan(androidUsesFineLocation: true);
// 监听扫描结果
FlutterBluePlus.onScanResults.listen((results) {
  for (final r in results) {
    if (r.device.platformName != 'RY') continue;
    // 解析广播数据获取 UUID 和 PID
  }
});
```

#### Step 2: 解析广播数据

从 Manufacturer Data (0xFF) 解析 UUID：
```dart
// data[length-17..length-1] = 16字节 UUID（UTF-8 字符串）
final uuidBytes = data.sublist(data.length - 17, data.length - 1);
uuid = String.fromCharCodes(uuidBytes); // 如: "ct01CykKfw5SMybt"
```

从 Service Data (0x16) 解析 PID：
```dart
// data[3..end] = PID（UTF-8 字符串）
productId = String.fromCharCodes(data.sublist(3)); // 如: "zuNuadqzsxEh75"
```

#### Step 3: 获取设备信息

```
POST /business-app/v1/device/getSimpleDeviceInfo
Body: {"productId": "zuNuadqzsxEh75", "uuid": "ct01CykKfw5SMybt"}
```

返回设备名称 `name` 和图标 `imageUrl`。

#### Step 4: 连接设备并发送配网数据

```dart
// 连接 BLE 设备
await device.connect(timeout: Duration(seconds: 10));

// 发现服务，查找写特征 (Service: 1910, Characteristic: 2b11)
final services = await device.discoverServices();

// 构造配网数据
final payload = {
  'type': 'thing.network.set',
  'msgId': '${DateTime.now().millisecondsSinceEpoch}001',
  'ts': DateTime.now().millisecondsSinceEpoch,
  'data': {
    'sid': 'WiFi名称',
    'pw': 'WiFi密码',
    'mq': 'mqtt.cetus-ai.com',
    'port': 2883,
    'bid': '资产ID',
    'userId': '用户ID',
    'country': 'CN',
    'tz': 'Asia/Shanghai',
    'force_bind': true,
  },
};

// 使用 BleProtocol 分包发送
final packets = BleProtocol.encode(utf8.encode(jsonEncode(payload)));
for (final packet in packets) {
  await characteristic.write(packet, withoutResponse: false);
  await Future.delayed(Duration(milliseconds: 130));
}
```

#### Step 5: 轮询绑定结果

```
POST /business-app/v1/device/bind/checkBindResult/{uuid}
```

返回 `data: 0` 表示绑定成功。每 10 秒轮询一次，最多 120 秒。

### 6.2 BLE 通信协议（BleProtocol）

帧格式：`FF + type(1B) + seq(2B) + totalPackets(2B) + totalLength(2B) + dataLength(1B) + data(nB) + checksum(1B)`

```dart
// 编码
List<List<int>> packets = BleProtocol.encode(data, type: 1);

// 解码
BlePacket? packet = BleProtocol.decode(bytes);
```

代码位置：`lib/utils/generic_ble_packet_protocol.dart`

### 6.3 4G 绑定码配网

```
POST /business-app/v1/device/bind/bindDeviceBy4gCode
Body: {"assetId": "资产ID", "bindCode": "5位绑定码"}
```

### 6.4 条形码配网

```
POST /business-app/v1/device/bind/bindDeviceFromBarcode
Body: {"assetId": "资产ID", "barcode": "条形码"}
```

## 7. 智能体管理

### 7.1 获取推荐智能体

```
POST /business-app/v1/sentino-agents/recommend/agents-list
```

### 7.2 创建自定义智能体

```
POST /business-app/v1/agents/customize/create
Body: {"name": "", "description": "", "avatarUrl": "", "langId": "", "llmModelId": "", "ttsVoiceId": ""}
```

### 7.3 绑定智能体到设备

```
POST /business-app/v1/agents/device/bind-agent
Body: {"agentId": "", "agentType": "sentino|customize|official", "deviceId": ""}
```

`agentType` 取值：
- `sentino`：从 sentino-agents 接口获取的智能体
- `customize`：用户自定义智能体
- `official`：平台官方智能体

## 8. MQTT 实时消息

### 8.1 连接认证

```dart
userName = "$userId|signMethod=hmacSha256,ts=$timestamp";
password = HMAC-SHA256(key=appId, data="uuid=$userId,ts=$timestamp");
clientId = "app_$userId|$randomUuid";
```

### 8.2 Topic 订阅

- 设备通知：`app/v2/{assetId}/notify`
- 用户通知：`app/v2/{userId}/userNotify`

### 8.3 消息类型

| code | 说明 |
|------|------|
| `device_property_update` | 设备属性变化（含信号检测结果） |
| `status` | 设备在线状态变化 |
| `ota_progress` | OTA 升级进度 |
| `bind_result` | 绑定结果通知 |

## 9. 设备管理

### 9.1 获取设备列表

```
POST /business-app/v1/device/getHomeDeviceAndGroupList
Body: {"assetIds": ["资产ID"]}
```

### 9.2 解绑设备

```
POST /business-app/v1/device/unbindFromAsset
Body: {"deviceId": "设备ID", "isCleanData": 0}  // 0=仅解绑, 1=解绑并清除数据
```

### 9.3 网络检测

```
POST /business-app/v1/device/command/checkSignal
Body: {"deviceId": "设备ID"}
```

结果通过 MQTT `device_property_update` 消息推送，包含 `signal`（1好/2中/3差）和 `signalValue`（0-100%）。

## 10. 国际化

支持三种语言：简体中文（zh_CN）、英语（en_US）、日语（ja_JP）。

ARB 文件位置：`lib/l10n/app_zh.arb`、`lib/l10n/app_en.arb`、`lib/l10n/app_ja.arb`

添加新文本：
1. 在三个 ARB 文件中添加 key-value
2. 运行 `flutter gen-l10n`
3. 代码中使用 `AppLocalizations.of(context)!.keyName`
