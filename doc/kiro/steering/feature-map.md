# AG Play Skills Registry — 功能模块索引

本项目将业务能力拆分为 6 个独立的 Skill 模块，每个 Skill 封装了完整的 Model → Repository → Service → Provider 四层代码。
当用户询问"某个功能在哪""哪个模块负责 XX"时，请根据以下信息回答。

---

## Skill 1: auth（认证）

- **描述**: 用户认证与账户管理
- **依赖**: 无
- **能力列表**:
  - `login` — 用户登录并持久化令牌
  - `register` — 用户注册（邮箱验证码）
  - `sendRegisterCode` — 发送注册验证码
  - `forgotPassword` — 发送忘记密码验证信息
  - `resetPassword` — 重置密码
  - `changePassword` — 修改密码
  - `logout` — 登出并清除令牌
  - `getUserProfile` — 获取用户资料
  - `uploadAvatar` — 上传头像
  - `updateUserInfo` — 更新用户信息
- **代码路径**:
  - Models: `lib/models/user.dart`, `lib/models/auth_result.dart`
  - Repositories: `lib/repositories/auth_repository.dart`, `lib/repositories/api/api_auth_repository.dart`, `lib/repositories/mock/mock_auth_repository.dart`
  - Services: `lib/services/auth_service.dart`
  - Providers: `lib/providers/auth_provider.dart`
  - Initializer: `lib/skills/initializers/auth_skill.dart`

## Skill 2: device（设备管理）

- **描述**: 设备列表、绑定/解绑、重命名、属性下发、信号检测
- **依赖**: auth
- **能力列表**:
  - `getAssetTree` — 获取资产树
  - `getDeviceList` — 获取设备列表
  - `bindDevice` — 绑定设备（UUID/条形码/4G）
  - `unbindDevice` — 解绑设备
  - `renameDevice` — 重命名设备
  - `checkSignal` — 网络检测（信号强度检查）
  - `getDpInfos` — 获取设备物模型 DP 点信息
- **代码路径**:
  - Models: `lib/models/device.dart`, `lib/models/asset.dart`
  - Repositories: `lib/repositories/device_repository.dart`, `lib/repositories/api/api_device_repository.dart`, `lib/repositories/mock/mock_device_repository.dart`
  - Services: `lib/services/device_service.dart`
  - Providers: `lib/providers/device_provider.dart`
  - Initializer: `lib/skills/initializers/device_skill.dart`

## Skill 3: ble_pairing（BLE 配网）

- **描述**: 蓝牙扫描、连接、配网数据发送、WiFi 列表获取
- **依赖**: device
- **能力列表**:
  - `startScan` — 扫描附近 BLE 设备
  - `connectDevice` — 连接 BLE 设备
  - `sendPairingData` — 发送配网数据到设备
  - `requestDeviceWifiList` — 获取设备周围 WiFi 列表
- **代码路径**:
  - Services: `lib/services/ble_service.dart`
  - Initializer: `lib/skills/initializers/ble_pairing_skill.dart`
- **备注**: BleService 为单例模式，无需通过 SkillConfig 初始化

## Skill 4: agent（智能体）

- **描述**: 推荐/自定义智能体、创建/删除、绑定到设备
- **依赖**: auth
- **能力列表**:
  - `getRecommendAgents` — 获取推荐智能体列表
  - `getCustomAgents` — 获取自定义智能体列表
  - `createCustomAgent` — 创建自定义智能体
  - `deleteCustomAgent` — 删除自定义智能体
  - `bindAgentToDevice` — 绑定智能体到设备
- **代码路径**:
  - Models: `lib/models/agent.dart`
  - Repositories: `lib/repositories/agent_repository.dart`, `lib/repositories/api/api_agent_repository.dart`, `lib/repositories/mock/mock_agent_repository.dart`
  - Services: `lib/services/agent_service.dart`
  - Providers: `lib/providers/agent_provider.dart`
  - Initializer: `lib/skills/initializers/agent_skill.dart`

## Skill 5: mqtt（MQTT 消息）

- **描述**: MQTT 连接、订阅、消息分发
- **依赖**: auth
- **能力列表**:
  - `connect` — 连接 MQTT 服务器
  - `subscribeAsset` — 订阅资产消息通知
  - `subscribeUser` — 订阅用户消息通知
  - `disconnect` — 断开 MQTT 连接
- **代码路径**:
  - Services: `lib/services/mqtt_service.dart`
  - Initializer: `lib/skills/initializers/mqtt_skill.dart`
- **备注**: MqttService 为独立服务，无需通过 SkillConfig 初始化

## Skill 6: ota（OTA 升级）

- **描述**: 固件检查、升级进度
- **依赖**: auth, device
- **能力列表**:
  - `checkUpgrade` — 检查设备固件升级
  - `startUpgrade` — 开始固件升级（含进度）
- **代码路径**:
  - Models: `lib/models/ota_info.dart`
  - Repositories: `lib/repositories/ota_repository.dart`, `lib/repositories/api/api_ota_repository.dart`, `lib/repositories/mock/mock_ota_repository.dart`
  - Services: `lib/services/ota_service.dart`
  - Providers: `lib/providers/ota_provider.dart`
  - Initializer: `lib/skills/initializers/ota_skill.dart`

---

## 架构说明

- 每个 Skill 通过 `XxxSkillInitializer.initialize(SkillConfig)` 创建，返回包含 Repository/Service/Provider 的 Bundle
- `SkillConfig` 统一管理 baseUrl、storage、language、useMock、apiClient
- `SkillsRegistry` 持有所有 SkillDescriptor，支持 `getById()`、`queryByCapability()` 查询
- 入口文件 `lib/main.dart` 通过 Skill Initializers 统一初始化
- Registry 构建: `lib/skills/default_registry.dart` → `buildDefaultRegistry()`
- Barrel 导出: `lib/skills/skills.dart`
