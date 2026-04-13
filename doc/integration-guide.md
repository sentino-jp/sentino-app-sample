# Sentino IoT App 接入文档

## 1. 概述

Sentino 是一款基于 Flutter 构建的跨平台 IoT 智能设备管理应用，支持 Android、iOS、Windows、Web。本文档详细描述应用中所有业务接口、设备配网流程及 MQTT 实时通信协议。

**Base URL**: `https://api.senitno.jp/api/`

---

## 2. 公共请求头

所有 API 请求通过 `ApiClient` 拦截器自动注入以下 Header：

| Header | 值 | 说明 |
|--------|------|------|
| `Authorization` | `Bearer {access_token}` | 登录后获取的令牌 |
| `client_id` | `Y2V0dXMtaW90LWFwcDpv...` | Base64 编码的客户端标识 |
| `app_id` | `cnsgdnmp2xhgf8` | 应用 ID |
| `channel_identifier` | `sgdnmp2x` | 渠道标识 |
| `data_center_code` | `cn` | 数据中心编码 |
| `language` | `zh_CN` / `en_US` / `ja_JP` | 当前语言 |
| `os_name` | `android` / `ios` / `windows` | 系统类型 |
| `version` | `1.0.0-2604131058` | 应用版本号 |
| `devid` | 设备唯一标识 | androidId / identifierForVendor |
| `ua` | Base64 编码 | 格式: `brand\|model\|os\|resolution\|deviceName` |
| `package_name` | `jp.sentino.smart` | 包名 |
| `request_id` | UUID v4 | 每次请求唯一 ID |
| `timezone` | `Asia/Shanghai` | IANA 时区 |
| `encrypt_type` | `AES/ECB/PKCS5Padding` | 加密方式 |

**统一响应格式**：

```json
{
  "reqId": "xxx",
  "time": 1234567890,
  "code": 200,
  "message": "成功",
  "data": ...
}
```

- `code == 200` 表示成功
- `code == 11013` 表示 Token 失效，客户端自动清除缓存并跳转登录页

---

## 3. 用户认证接口

### 3.1 登录

```
POST /auth/oauth/token
Content-Type: application/x-www-form-urlencoded
```

**额外 Header**：
- `scope`: `all`
- `Authorization`: `Basic {client_id}`（覆盖 Bearer）

**请求参数**（form-urlencoded）：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `username` | String | 是 | 邮箱地址 |
| `password` | String | 是 | 密码 |
| `areaCode` | String | 是 | 国际区号，默认 `86` |
| `countryKey` | String | 是 | 国家代码，默认 `CN` |
| `grant_type` | String | 是 | 固定 `password` |

**响应 data**：

| 字段 | 类型 | 说明 |
|------|------|------|
| `access_token` | String | 访问令牌 |
| `userId` | String | 用户数字 ID（用于 MQTT 认证） |
| `memberId` | String | 成员 ID |

```json
{
  "code": 200,
  "message": "成功",
  "data": {
    "access_token": "eyJhbGciOiJSUzI1NiIs...",
    "userId": "1780000000000001",
    "memberId": "1780000000000001",
    "refresh_token": "abc123...",
    "token_type": "bearer"
  }
}
```


### 3.2 发送注册验证码

```
POST business-app/v2/user/register/sendRegisterCode
```

**请求参数**（Query Parameters）：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `countryCode` | String | 是 | 国家码，如 `86` |
| `input` | String | 是 | 邮箱地址或手机号（自动识别） |

**响应 data**（VerifyCodeResultVO）：

| 字段 | 类型 | 说明 |
|------|------|------|
| `sendTo` | String | 验证码发送目标 |
| `verifyCodeLength` | int | 验证码长度（用于动态生成输入框） |
| `intervalSeconds` | int | 验证码发送间隔（秒） |
| `expireSeconds` | int | 验证码过期时间（秒） |

```json
{
  "code": 200,
  "message": "成功",
  "data": {
    "sendTo": "user@example.com",
    "verifyCodeLength": 6,
    "intervalSeconds": 60,
    "expireSeconds": 300
  }
}
```

### 3.3 获取验证码发送间隔剩余时间

```
POST business-app/v2/common/getSendVerifyCodeTimeLeft
```

**请求参数**（Query Parameters）：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `account` | String | 是 | 邮箱地址或手机号 |

**响应 data**（VerifyCodeResultVO）：

| 字段 | 类型 | 说明 |
|------|------|------|
| `sendTo` | String | 验证码发送目标 |
| `verifyCodeLength` | int | 验证码长度 |
| `intervalSeconds` | int | 剩余间隔时间（秒），0 表示可重新发送 |
| `expireSeconds` | int | 验证码过期时间（秒） |

```json
{
  "code": 200,
  "message": "成功",
  "data": {
    "sendTo": "user@example.com",
    "verifyCodeLength": 6,
    "intervalSeconds": 45,
    "expireSeconds": 300
  }
}
```

### 3.4 注册

```
POST business-app/v1/user/register/registryByUserName
Content-Type: application/json
```

**请求参数**（JSON Body）：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `input` | String | 是 | 邮箱地址 |
| `password` | String | 是 | 密码（≥6位） |
| `verifyCode` | String | 是 | 验证码（从 3.2 接口获取） |
| `countryCode` | String | 是 | 国际区号，默认 `86` |
| `countryKey` | String | 是 | 国家代码，默认 `CN` |

**注册流程**：
1. 用户输入邮箱 + 密码 + 确认密码
2. 点击"下一步"调用 3.2 发送验证码
3. 根据返回的 `verifyCodeLength` 动态生成验证码输入框
4. 用户输入验证码后调用本接口完成注册
5. 重发验证码前调用 3.3 查询剩余间隔

**响应 data**：`true`（bool，注册成功）

```json
{
  "code": 200,
  "message": "成功",
  "data": true
}
```

### 3.5 检查验证码

```
POST business-app/v1/verifyCode/checkVerifyCode
Content-Type: application/json
```

**请求参数**（JSON Body）：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `account` | String | 是 | 邮箱地址或手机号 |
| `verifyCode` | String | 是 | 验证码 |

**说明**：注册和忘记密码流程中，验证码输入满后自动调用此接口校验。`code == 200` 表示验证码有效，非 200 表示无效。

**响应样例**：

```json
{
  "code": 200,
  "message": "成功",
  "data": null
}
```

### 3.6 发送找回密码验证码

```
POST business-app/v2/user/password/find/sendFindPasswordCode
Content-Type: application/json
```

**请求参数**（Query Parameters）：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `input` | String | 是 | 邮箱地址 |
| `passwordFindType` | String | 是 | `email_code`（邮箱）或 `sms_code`（短信） |

**响应样例**：

```json
{
  "code": 200,
  "message": "成功",
  "data": null
}
```

### 3.7 重置密码

```
POST business-app/v1/user/password/find/resetPassword
Content-Type: application/json
```

**请求参数**（JSON Body）：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `input` | String | 是 | 邮箱地址 |
| `password` | String | 是 | 新密码 |
| `passwordFindType` | String | 是 | `email_code` 或 `sms_code` |
| `verifyCode` | String | 是 | 验证码 |

**忘记密码流程**：
1. 用户输入邮箱，点击"获取验证码"调用 3.5 发送验证码
2. 进入验证码输入页面（输入框数量根据 3.3 接口返回的 `verifyCodeLength` 动态生成）
3. 输入验证码后点击"下一步"进入密码设置页面
4. 输入新密码 + 确认密码后调用本接口重置密码

**响应样例**：

```json
{
  "code": 200,
  "message": "成功",
  "data": null
}
```

### 3.8 修改密码

```
POST business-app/v1/user/password/update/updatePassword
Content-Type: application/json
```

**请求参数**（JSON Body）：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `oldPassword` | String | 是 | 旧密码 |
| `password` | String | 是 | 新密码 |
| `passwordUpdateType` | String | 是 | 固定 `password` |

**响应样例**：

```json
{
  "code": 200,
  "message": "成功",
  "data": null
}
```

### 3.9 登出

```
POST /auth/oauth/logout
```

无请求参数。

**响应样例**：

```json
{
  "code": 200,
  "message": "成功",
  "data": null
}
```

### 3.10 获取用户资料

```
POST business-app/v1/user/profile
```

无请求参数。

**响应 data**（User 对象）：

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` / `userId` / `memberId` | String | 用户 ID |
| `nickname` | String? | 昵称 |
| `userName` | String? | 用户名 |
| `email` | String? | 邮箱 |
| `phone` | String? | 手机号 |
| `avatarUrl` | String? | 头像 URL |
| `areaCode` | String? | 区号 |
| `userType` | int | 用户类型 |
| `tz` | String? | 时区 |
| `tempUnit` | String? | 温度单位 |

```json
{
  "code": 200,
  "message": "成功",
  "data": {
    "id": "1780000000000001",
    "nickname": "张三",
    "userName": "user@example.com",
    "email": "user@example.com",
    "phone": null,
    "avatarUrl": "https://cdn.example.com/avatar/1.jpg",
    "areaCode": "86",
    "userType": 1,
    "tz": "Asia/Shanghai",
    "tempUnit": "celsius"
  }
}
```

### 3.11 更新用户信息

```
POST business-app/v1/user/updateInfo
Content-Type: application/json
```

**请求参数**（JSON Body）：动态字段，如 `{"nickname": "新昵称"}` 或 `{"avatarUrl": "https://..."}`

**请求参数**（JSON Body）：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `nickname` | String | 否 | 昵称 |
| `avatarUrl` | String | 否 | 头像 URL |
| 其他字段 | any | 否 | 支持 User 模型中的任意可更新字段 |

**响应样例**：

```json
{
  "code": 200,
  "message": "成功",
  "data": null
}
```

### 3.12 上传文件

```
POST business-app/v1/file/uploadFile
Content-Type: multipart/form-data
```

**请求参数**：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `file` | File | 是 | 文件（如头像图片） |

**响应 data**：`String`（文件 URL）

```json
{
  "code": 200,
  "message": "成功",
  "data": "https://cdn.example.com/upload/avatar_20260413.jpg"
}
```

---

## 4. 资产管理接口

### 4.1 获取资产树

```
POST business-app/v1/asset/assetTree
```

无请求参数。

**响应 data**（Asset 数组）：

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | String | 资产 ID |
| `name` | String | 资产名称 |
| `currentSelected` | bool | 是否当前选中 |
| `childrens` | Asset[]? | 子资产列表 |

```json
{
  "code": 200,
  "message": "成功",
  "data": [
    {
      "id": "asset_001",
      "name": "我的家",
      "currentSelected": true,
      "childrens": []
    }
  ]
}
```

---

## 5. 设备管理接口

### 5.1 获取设备列表

```
POST business-app/v1/device/getHomeDeviceAndGroupList
Content-Type: application/json
```

**请求参数**（JSON Body）：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `assetIds` | String[] | 是 | 资产 ID 列表 |

**响应 data**：

```json
{
  "deviceList": [Device, ...]
}
```

**Device 对象**：

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | String | 设备 ID |
| `uuid` | String? | 设备 UUID |
| `productId` | String? | 产品 ID |
| `name` | String? | 设备名称 |
| `imageUrl` | String? | 设备图片 URL |
| `onlineStatus` | int? | 在线状态（1=在线，0=离线） |
| `firmwareVersion` | String? | 固件版本 |
| `mcuVersion` | String? | MCU 版本 |
| `protocolType` | String? | 协议类型 |
| `ip` | String? | IP 地址 |
| `currentSsid` | String? | 当前 WiFi SSID |
| `signalStrength` | int? | 信号强度 |
| `mac` | String? | MAC 地址 |
| `networkType` | String? | 网络类型 |
| `barcode` | String? | 条形码 |
| `timeZone` | String? | 时区 |
| `propertiesInfoDTO` | Map? | 设备属性 |

```json
{
  "code": 200,
  "message": "成功",
  "data": {
    "deviceList": [
      {
        "id": "dev_001",
        "uuid": "ct01CykKfw5SMybt",
        "productId": "zuNuadqzsxEh75",
        "name": "智能音箱",
        "imageUrl": "https://cdn.example.com/device/speaker.png",
        "onlineStatus": 1,
        "firmwareVersion": "1.2.3",
        "mcuVersion": "0.1.0",
        "protocolType": "WiFi+BLE",
        "ip": "192.168.1.100",
        "currentSsid": "MyWiFi",
        "signalStrength": 75,
        "mac": "AA:BB:CC:DD:EE:FF",
        "networkType": "WiFi",
        "barcode": "SN123456789",
        "timeZone": "Asia/Shanghai",
        "propertiesInfoDTO": {"volume": 50}
      }
    ]
  }
}
```

### 5.2 获取设备简要信息

```
POST business-app/v1/device/getSimpleDeviceInfo
Content-Type: application/json
```

**请求参数**（JSON Body）：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `productId` | String | 是 | 产品 ID（从 BLE 广播解析） |
| `uuid` | String | 是 | 设备 UUID（从 BLE 广播解析） |

**响应 data**：Device 对象（主要使用 `name` 和 `imageUrl`）

```json
{
  "code": 200,
  "message": "成功",
  "data": {
    "id": "dev_001",
    "name": "智能音箱",
    "imageUrl": "https://cdn.example.com/device/speaker.png",
    "uuid": "ct01CykKfw5SMybt",
    "productId": "zuNuadqzsxEh75"
  }
}
```

### 5.3 根据设备 ID 获取设备详情

```
POST business-app/v1/device/getByDeviceId/{deviceId}
```

**路径参数**：`deviceId` — 设备 ID

**响应 data**：Device 对象（字段同 5.1）

```json
{
  "code": 200,
  "message": "成功",
  "data": {
    "id": "dev_001",
    "uuid": "ct01CykKfw5SMybt",
    "productId": "zuNuadqzsxEh75",
    "name": "智能音箱",
    "imageUrl": "https://cdn.example.com/device/speaker.png",
    "onlineStatus": 1,
    "firmwareVersion": "1.2.3",
    "mac": "AA:BB:CC:DD:EE:FF",
    "ip": "192.168.1.100",
    "networkType": "WiFi",
    "timeZone": "Asia/Shanghai"
  }
}
```

### 5.4 设备重命名

```
POST business-app/v1/device/initDevice
Content-Type: application/json
```

**请求参数**（JSON Body）：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `assetId` | String | 是 | 资产 ID |
| `deviceUuid` | String | 是 | 设备 UUID |
| `deviceName` | String | 是 | 新名称 |

**响应样例**：

```json
{
  "code": 200,
  "message": "成功",
  "data": null
}
```

### 5.5 解绑设备

```
POST business-app/v1/device/unbindFromAsset
Content-Type: application/json
```

**请求参数**（JSON Body）：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `deviceId` | String | 是 | 设备 ID |
| `isCleanData` | int | 是 | 0=仅解绑，1=解绑并清除数据 |

**响应样例**：

```json
{
  "code": 200,
  "message": "成功",
  "data": null
}
```

### 5.6 下发设备属性

```
POST business-app/v1/device/command/propsIssue
Content-Type: application/json
```

**请求参数**（JSON Body）：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `deviceId` | String | 是 | 设备 ID |
| `data` | Map | 是 | 属性键值对，如 `{"volume": 50}` |

**响应样例**：

```json
{
  "code": 200,
  "message": "成功",
  "data": null
}
```

### 5.7 网络检测

```
POST business-app/v1/device/command/checkSignal
Content-Type: application/json
```

**请求参数**（JSON Body）：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `deviceId` | String | 是 | 设备 ID |

检测结果通过 MQTT `device_property_update` 消息推送，包含 `signal`（1好/2中/3差）和 `signalValue`（0-100%）。

**响应样例**：

```json
{
  "code": 200,
  "message": "成功",
  "data": null
}
```


### 5.8 获取设备物模型 DP 点信息

```
POST business-app/v1/device/getDpInfos/{deviceId}
```

**路径参数**：`deviceId` — 设备 ID

**响应 data**（DeviceDpInfoVO 数组）：

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | String | DP 点 ID |
| `key` | String | 属性标识符（如 `volume_set`） |
| `name` | String | 属性名称 |
| `type` | String | DP 点取值类型 |
| `value` | dynamic | 当前值 |
| `specs` | String | 模型规格 JSON（含 min/max/step） |
| `dpBusiId` | String | 属性业务 ID |
| `imageUrl` | String? | 功能点图标 |
| `valueCastType` | int | 0=原始值，1=百分比 |

```json
{
  "code": 200,
  "message": "成功",
  "data": [
    {
      "id": "dp_001",
      "key": "volume_set",
      "name": "音量设置",
      "type": "value",
      "value": 5,
      "specs": "{\"min\":0,\"max\":10,\"step\":1}",
      "dpBusiId": "busi_001",
      "imageUrl": null,
      "valueCastType": 0
    }
  ]
}
```

设备面板中音量组件使用 `key == 'volume_set'` 的 DP 点，从 `specs` 解析 `min`/`max` 渲染 Slider，`value` 为当前音量值（整型）。


---

## 6. 设备配网接口与流程

### 6.1 配网方式概览

| 方式 | 适用场景 | 关键接口 |
|------|----------|----------|
| BLE 蓝牙配网 | WiFi+BLE 双模设备 | BLE 协议 + `checkBindResult` |
| 4G 绑定码 | 4G 设备 | `bindDeviceBy4gCode` |
| 条形码 | 扫码绑定 | `bindDeviceFromBarcode` |

### 6.2 BLE 蓝牙配网完整流程

```
┌─────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│  BLE 扫描    │ →  │  选择设备     │ →  │  WiFi 配置    │ →  │  BLE 发送     │ →  │  轮询绑定     │ →  │  配网完成     │
│  过滤 "RY"   │    │  获取设备信息  │    │  输入SSID/密码│    │  thing.network│    │  checkBind   │    │  刷新设备列表  │
└─────────────┘    └──────────────┘    └──────────────┘    └──────────────┘    └──────────────┘    └──────────────┘
```

#### Step 1: BLE 扫描

- 使用 `flutter_blue_plus` 扫描 BLE 设备
- 过滤条件：设备广播名 == `"RY"`
- Android 权限：`BLUETOOTH_SCAN`、`BLUETOOTH_CONNECT`、`ACCESS_FINE_LOCATION`

#### Step 2: 解析广播数据

**Manufacturer Data（厂商数据，Key=0x0000）**：

| 偏移 | 长度 | 说明 |
|------|------|------|
| 0 | 1B | config_flag（0x01=待配网） |
| 1 | 1B | protocol_version |
| 2 | 1B | encryption_method |
| 3-4 | 2B | commun_capability（高字节在前） |
| 5 | 1B | 标识类型（0=UUID，1=MAC） |
| 6+ | nB | 标识内容（UUID 为 ASCII 文本，最多 19 字节，去尾部 0） |

**Service Data（服务数据）**：

- 匹配 UUID 包含 `a101` 或前缀为 `0xA1, 0x01`
- 第 3 字节为 type，type=0 时后续 14~16 字节为 PID（产品 ID，ASCII 文本）

#### Step 3: 获取设备信息

调用 `getSimpleDeviceInfo` 接口（见 5.2），传入解析到的 `productId` 和 `uuid`，获取设备名称和图片。

#### Step 4: 连接设备并发送配网数据

**BLE 服务与特征**：

| 项目 | UUID |
|------|------|
| Service | `00001910-0000-1000-8000-00805f9b34fb` |
| Write Characteristic | `00002b11-0000-1000-8000-00805f9b34fb` |
| Notify Characteristic | `00002b10-0000-1000-8000-00805f9b34fb` |

**配网数据 JSON**：

```json
{
  "type": "thing.network.set",
  "msgId": "{timestamp}001",
  "ts": 1234567890000,
  "data": {
    "force_bind": true,
    "sid": "WiFi名称",
    "pw": "WiFi密码",
    "mq": "mqtt.sentino.jp",
    "port": 2883,
    "bid": "资产ID",
    "userId": "用户数字ID",
    "country": "CN",
    "areaCode": "86",
    "tz": "Asia/Shanghai"
  }
}
```

**BLE 分包协议**：

数据通过 `BleProtocol` 分包后逐包写入 Write Characteristic。

帧格式（每包最大 128 字节）：

```
FF + type(1B) + seq(2B, BigEndian) + totalPackets(2B, BigEndian) + totalLength(2B, BigEndian) + dataLength(1B) + data(nB) + checksum(1B)
```

| 字段 | 长度 | 说明 |
|------|------|------|
| Header | 1B | 固定 `0xFF` |
| Type | 1B | 包类型，默认 `1` |
| Seq | 2B | 当前包序号（从 0 开始，Big Endian） |
| TotalPackets | 2B | 总包数（Big Endian） |
| TotalLength | 2B | 原始数据总长度（Big Endian） |
| DataLength | 1B | 本包数据长度 |
| Data | nB | 本包数据片段 |
| Checksum | 1B | 校验和 = (type + seq高 + seq低 + ... + 所有data字节) & 0xFF |

- 固定开销 10 字节，每包最大数据 118 字节
- 每包间隔 10ms

**WiFi 列表获取**（可选，通过 BLE Notify 通道）：

请求：
```json
{"type": "thing.network.getwifis", "scan": true}
```

响应：
```json
{"type": "thing.network.getwifis.response", "code": 0, "data": [{"ssid": "...", "rssi": -50, "security": true}]}
```

#### Step 5: 轮询绑定结果

```
POST business-app/v1/device/bind/checkBindResult/{uuid}
```

**路径参数**：`uuid` — 设备 UUID

**响应 data**：`int`
- `0` = 绑定成功
- 其他值 = 未完成

轮询策略：每 10 秒一次，最多 120 秒（12 次）。

```json
{
  "code": 200,
  "message": "成功",
  "data": 0
}
```

### 6.3 4G 绑定码配网

```
POST business-app/v1/device/bind/bindDeviceBy4gCode
Content-Type: application/json
```

**请求参数**（JSON Body）：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `assetId` | String | 是 | 资产 ID |
| `bindCode` | String | 是 | 5 位数字绑定码 |

**响应样例**：

```json
{
  "code": 200,
  "message": "成功",
  "data": null
}
```

### 6.4 条形码配网

```
POST business-app/v1/device/bind/bindDeviceFromBarcode
Content-Type: application/json
```

**请求参数**（JSON Body）：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `assetId` | String | 是 | 资产 ID |
| `barcode` | String | 是 | 条形码 |

**响应样例**：

```json
{
  "code": 200,
  "message": "成功",
  "data": null
}
```

### 6.5 直接绑定设备

```
POST business-app/v1/device/bind/bindDevice
Content-Type: application/json
```

**请求参数**（JSON Body）：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `assetId` | String | 是 | 资产 ID |
| `deviceUuid` | String | 是 | 设备 UUID |

**响应样例**：

```json
{
  "code": 200,
  "message": "成功",
  "data": null
}
```

### 6.6 配网数据加密

```
POST business-app/v1/distributionNet/dataEncrypt
Content-Type: application/json
```

**请求参数**（JSON Body）：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| 配网数据 | Map | 是 | 需要加密的配网参数键值对 |

**响应 data**：`String`（加密后的数据）

```json
{
  "code": 200,
  "message": "成功",
  "data": "U2FsdGVkX1+abc123..."
}
```

---

## 7. 智能体管理接口

### 7.1 获取推荐智能体列表

```
POST business-app/v1/sentino-agents/recommend/agents-list
```

> 当 `agentPlatform == 'platform'` 时路径为 `business-app/v1/agents/recommend/agents-list`

无请求参数。

**响应 data**（Agent 数组）：

| 字段 | 类型 | 说明 |
|------|------|------|
| `agentId` | String | 智能体 ID |
| `name` | String? | 名称 |
| `avatarUrl` | String? | 头像 URL |
| `description` | String? | 描述 |
| `languageId` | String? | 语言 ID |
| `languageName` | String? | 语言名称 |
| `modelId` | String? | 模型 ID |
| `modelName` | String? | 模型名称 |
| `voiceId` | String? | 音色 ID |
| `voiceName` | String? | 音色名称 |
| `agentType` | String? | 类型（自动赋值：sentino/official） |
| `tagList` | AgentTag[]? | 标签列表 |

```json
{
  "code": 200,
  "message": "成功",
  "data": [
    {
      "agentId": "agent_001",
      "name": "小助手",
      "avatarUrl": "https://cdn.example.com/agent/avatar1.png",
      "description": "一个友好的智能助手",
      "languageId": "lang_zh",
      "languageName": "中文",
      "modelId": "model_gpt4",
      "modelName": "GPT-4",
      "voiceId": "voice_001",
      "voiceName": "甜美女声",
      "agentType": "sentino",
      "tagList": [
        {"tagId": "tag_001", "name": "教育"},
        {"tagId": "tag_002", "name": "陪伴"}
      ]
    }
  ]
}
```

**agentType 取值规则**：
- `sentino`：从 `sentino-agents` 接口获取
- `official`：从 `agents`（platform）接口获取
- `customize`：从 `agents/customize` 接口获取

### 7.2 获取自定义智能体列表

```
POST business-app/v1/agents/customize/agents-list
```

无请求参数。响应同上，`agentType` 自动设为 `customize`。

**响应样例**：

```json
{
  "code": 200,
  "message": "成功",
  "data": [
    {
      "agentId": "custom_001",
      "name": "我的助手",
      "avatarUrl": "https://cdn.example.com/agent/custom1.png",
      "description": "自定义的智能助手",
      "languageId": "lang_zh",
      "languageName": "中文",
      "modelId": "model_gpt4",
      "modelName": "GPT-4",
      "voiceId": "voice_002",
      "voiceName": "磁性男声",
      "agentType": "customize",
      "tagList": []
    }
  ]
}
```

### 7.3 获取智能体详情

```
POST business-app/v1/sentino-agents/detail
```

**请求参数**（Query Parameters）：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `agentId` | String | 是 | 智能体 ID |

**响应 data**：Agent 对象（字段同 7.1）

```json
{
  "code": 200,
  "message": "成功",
  "data": {
    "agentId": "agent_001",
    "name": "小助手",
    "avatarUrl": "https://cdn.example.com/agent/avatar1.png",
    "description": "一个友好的智能助手",
    "languageId": "lang_zh",
    "languageName": "中文",
    "modelId": "model_gpt4",
    "modelName": "GPT-4",
    "voiceId": "voice_001",
    "voiceName": "甜美女声",
    "agentType": "sentino",
    "tagList": [{"tagId": "tag_001", "name": "教育"}]
  }
}
```

### 7.4 创建自定义智能体

```
POST business-app/v1/agents/customize/create
Content-Type: application/json
```

**请求参数**（JSON Body）：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `name` | String | 是 | 名称 |
| `description` | String | 否 | 描述 |
| `avatarUrl` | String | 否 | 头像 URL |
| `langId` | String | 否 | 语言 ID |
| `llmModelId` | String | 否 | 模型 ID |
| `ttsVoiceId` | String | 否 | 音色 ID |

**响应样例**：

```json
{
  "code": 200,
  "message": "成功",
  "data": null
}
```

### 7.5 更新自定义智能体

```
POST business-app/v1/agents/customize/update
Content-Type: application/json
```

**请求参数**（JSON Body）：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `agentId` | String | 是 | 智能体 ID |
| `name` | String | 否 | 名称 |
| `description` | String | 否 | 描述 |
| `avatarUrl` | String | 否 | 头像 URL |
| `langId` | String | 否 | 语言 ID |
| `llmModelId` | String | 否 | 模型 ID |
| `ttsVoiceId` | String | 否 | 音色 ID |

**响应样例**：

```json
{
  "code": 200,
  "message": "成功",
  "data": null
}
```

### 7.6 删除自定义智能体

```
POST business-app/v1/agents/customize/deleteById
```

**请求参数**（Query Parameters）：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `agentId` | String | 是 | 智能体 ID |

**响应样例**：

```json
{
  "code": 200,
  "message": "成功",
  "data": null
}
```

### 7.7 绑定智能体到设备

```
POST business-app/v1/agents/device/bind-agent
Content-Type: application/json
```

**请求参数**（JSON Body）：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `agentId` | String | 是 | 智能体 ID |
| `agentType` | String | 是 | `sentino` / `customize` / `official` |
| `deviceId` | String | 是 | 设备 ID |

**响应样例**：

```json
{
  "code": 200,
  "message": "成功",
  "data": null
}
```

### 7.8 解绑智能体

```
POST business-app/v1/agents/device/unbind-agent
```

**请求参数**（Query Parameters）：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `deviceId` | String | 是 | 设备 ID |

**响应样例**：

```json
{
  "code": 200,
  "message": "成功",
  "data": null
}
```

### 7.9 获取设备绑定的智能体

```
POST business-app/v1/agents/device/getAgentBaseByDeviceId
```

**请求参数**（Query Parameters）：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `deviceId` | String | 是 | 设备 ID |

**响应 data**：Agent 对象（字段同 7.1）

```json
{
  "code": 200,
  "message": "成功",
  "data": {
    "agentId": "agent_001",
    "name": "小助手",
    "avatarUrl": "https://cdn.example.com/agent/avatar1.png",
    "description": "一个友好的智能助手",
    "agentType": "sentino"
  }
}
```

### 7.10 获取对话历史

```
POST business-app/v1/agents/conversation/history
```

**请求参数**（Query Parameters）：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `agentId` | String | 是 | 智能体 ID |
| `targetId` | String | 是 | 目标 ID（设备 ID） |
| `targetType` | String | 是 | 目标类型，默认 `device` |

**响应 data**（消息数组）：

| 字段 | 类型 | 说明 |
|------|------|------|
| `role` | String | `user` 或 `assistant` |
| `content` | String | 消息内容 |
| `createTime` | int | 时间戳（毫秒） |

```json
{
  "code": 200,
  "message": "成功",
  "data": [
    {
      "role": "user",
      "content": "你好",
      "createTime": 1681234567000
    },
    {
      "role": "assistant",
      "content": "你好！有什么可以帮你的吗？",
      "createTime": 1681234568000
    }
  ]
}
```

### 7.11 清空对话历史

```
POST business-app/v1/agents/conversation/history/clean
```

**请求参数**（Query Parameters）：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `agentId` | String | 是 | 智能体 ID |

**响应样例**：

```json
{
  "code": 200,
  "message": "成功",
  "data": null
}
```

### 7.12 辅助接口

#### 7.12.1 获取语言列表

```
POST business-app/v1/agents/customize/language-list
```

无请求参数。

**响应样例**：

```json
{
  "code": 200,
  "message": "成功",
  "data": [
    {"id": "lang_zh", "name": "中文"},
    {"id": "lang_en", "name": "English"},
    {"id": "lang_ja", "name": "日本語"}
  ]
}
```

#### 7.12.2 获取音色列表

```
POST business-app/v1/agents/customize/voice-list
```

无请求参数。

**响应样例**：

```json
{
  "code": 200,
  "message": "成功",
  "data": [
    {"id": "voice_001", "name": "甜美女声"},
    {"id": "voice_002", "name": "磁性男声"}
  ]
}
```

#### 7.12.3 获取 LLM 模型列表

```
POST business-app/v1/agents/customize/llm-list
```

无请求参数。

**响应样例**：

```json
{
  "code": 200,
  "message": "成功",
  "data": [
    {"id": "model_gpt4", "name": "GPT-4"},
    {"id": "model_gpt35", "name": "GPT-3.5"}
  ]
}
```

#### 7.12.4 文本润色

```
POST business-app/v1/agents/customize/refinement-text
Content-Type: application/json
```

**请求参数**（JSON Body）：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `content` | String | 是 | 需要润色的文本 |
| `language` | String | 否 | 目标语言 |

**响应 data**：`String`（润色后的文本）

```json
{
  "code": 200,
  "message": "成功",
  "data": "你是一位知识渊博的天文学家，拥有丰富的宇宙探索经验..."
}
```

---

## 8. OTA 升级接口

### 8.1 检查固件升级

```
POST business-app/v1/ota/checkUpgrade/{deviceId}/{firmwareType}
```

**路径参数**：
- `deviceId` — 设备 ID
- `firmwareType` — 固件类型，默认 `1`

**响应 data**（OtaInfo 对象，无更新时为 null）：

| 字段 | 类型 | 说明 |
|------|------|------|
| `version` | String | 新版本号 |
| `url` | String | 固件下载 URL |
| `md5sum` | String | MD5 校验 |
| `fileSize` | int | 文件大小（字节） |
| `firmwareType` | int | 固件类型 |
| `description` | String? | 升级说明 |

```json
{
  "code": 200,
  "message": "成功",
  "data": {
    "version": "2.0.1",
    "url": "https://cdn.example.com/ota/firmware_2.0.1.bin",
    "md5sum": "d41d8cd98f00b204e9800998ecf8427e",
    "fileSize": 1048576,
    "firmwareType": 1,
    "description": "修复蓝牙连接稳定性问题"
  }
}
```

无更新时响应：

```json
{
  "code": 200,
  "message": "成功",
  "data": null
}
```

---

## 9. MQTT 实时消息

### 9.1 连接认证

| 参数 | 值 |
|------|------|
| Host | `mqtt.sentino.jp` |
| Port | `2883` |
| userName | `{userId}\|signMethod=hmacSha256,ts={timestamp}` |
| password | `HMAC-SHA256(key=appId, data="uuid={userId},ts={timestamp}")` |
| clientId | `app_{userId}\|{randomUUID}` |

- `userId` 必须是登录返回的数字 ID，不是用户名
- `appId` = `cnsgdnmp2xhgf8`
- `timestamp` = 当前秒级时间戳

### 9.2 Topic 订阅

| Topic | 说明 |
|-------|------|
| `app/v2/{assetId}/notify` | 设备通知（属性变化、在线状态等） |
| `app/v2/{userId}/userNotify` | 用户通知（绑定结果等） |

### 9.3 消息类型

| code | 说明 |
|------|------|
| `device_property_update` | 设备属性变化（含网络检测结果） |
| `status` | 设备在线/离线状态变化 |
| `ota_progress` | OTA 升级进度 |
| `bind_result` | 绑定结果通知 |

**消息 JSON 样例**：

设备属性变化（网络检测结果）：
```json
{
  "code": "device_property_update",
  "deviceId": "dev_001",
  "data": {
    "signal": 1,
    "signalValue": 85
  }
}
```

设备在线状态变化：
```json
{
  "code": "status",
  "deviceId": "dev_001",
  "data": {
    "onlineStatus": 1
  }
}
```

OTA 升级进度：
```json
{
  "code": "ota_progress",
  "deviceId": "dev_001",
  "data": {
    "progress": 45,
    "status": "downloading"
  }
}
```

---

## 10. 错误码说明

| 错误码 | 说明 | 客户端处理 |
|--------|------|-----------|
| `200` | 成功 | — |
| `11013` | Token 失效 | 清除缓存，跳转登录页 |
| HTTP `401` | 未授权 | 清除缓存，跳转登录页 |
| HTTP `404` | 接口不存在 | 检查接口路径 |
