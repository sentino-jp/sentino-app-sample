# Google 登录接入清单（sentino-app-sample）

Google 登录走**系统级登录 API 直出 id_token**，不经系统浏览器的 `authorize → callback` 往返：

```
Android  Credential Manager（系统账号弹窗，全程无浏览器）
iOS      GIDSignIn（内部仍是 ASWebAuthenticationSession —— Google 强制要求，无 SDK 能绕开；
         收益是省掉服务端两跳重定向、直接拿 id_token）
   ↓ id_token + 原始 nonce
POST /api/coucou/auth/oauth2/native/google      （coucou-server 转发 → DragonFlow workflow-api）
   ↓
bound=true  → 顶层即 AuthResponse（access_token/refresh_token），会话已建立
bound=false → binding_token → POST /api/coucou/auth/oauth2/bind → 会话建立
```

拿到的是 **dragonflow JWT**，与账密的 CouCou 登录落同一套登录态（`loginMode=coucou`），
所以 Google 按钮只在 coucou 模式显示 —— 旧 IoT（cetus）账号体系没有三方登录端点。

**代码已经写完，但下面的外部配置不做就跑不起来。**

## 0. 后端前置：三个 PR 必须先合并并部署

三处改动缺一不可，且当前**全是 DRAFT**：

| 仓库 | PR | 作用 |
|---|---|---|
| DragonFlow | [#913](https://github.com/sentino-jp/DragonFlow/pull/913) | 新增 `POST /api/auth/oauth2/native/{provider}` + id_token 验签 |
| coucou-server | [#157](https://github.com/sentino-jp/coucou-server/pull/157) | 转发层放行该端点 + 接 `afterLogin` hook |
| coucou-mobile | [#3](https://github.com/sentino-jp/coucou-mobile/pull/3) | CouCou App 侧接入（本仓的参考实现） |

## 1. 后端环境变量：`GOOGLE_NATIVE_AUDIENCES`

`aud` 白名单**为空 = 该 provider 原生登录关闭**（端点恒返回 400），与 `oauth2.google.enabled` 解耦。
校验失败一律 400 且**不回传具体失败项**（避免给攻击者当 oracle 用），所以线上排查只能看后端日志。

```properties
# 逗号分隔，都是「客户端」的 client id
GOOGLE_NATIVE_AUDIENCES=<CouCou iOS client id>,<web client id>,<本 App 的 iOS client id>
```

为什么要分两类：

- **Android**：Credential Manager 按 `serverClientId` 签发，token 的 `aud` = **web** client id；
- **iOS**：GIDSignIn 签发，`aud` = 该 App **自己的 iOS** client id。

⚠️ **本 App 的 iOS bundle 是 `jp.sentino.general`，与 CouCou App 的 `jp.sentino.coucou` 不同**，
所以要新建一条 iOS client id 并**追加**进这个白名单。
Android 侧不用动后端 —— 复用同一条 web client id，CouCou App 已经把它加进白名单了。

## 2. Google Cloud Console

在与后端 `oauth2.google.client-id` 同一个 GCP 项目下：

| 类型 | 值 | 填到哪 |
|---|---|---|
| **Web 应用** | 已存在（后端网页流在用的那条） | 已内置在 [`lib/utils/app_config.dart`](../lib/utils/app_config.dart) 的 `googleServerClientId` |
| **iOS**（新建） | Bundle ID = `jp.sentino.general` | `ios/Flutter/Local.xcconfig` + 后端白名单 |
| **Android**（新建） | 包名 = `com.agplay.ag_play` + SHA-1 | **哪里都不用填** |

### 包名的坑

**Android 的 applicationId 是 `com.agplay.ag_play`，不是 `jp.sentino.general`。**
后者是 iOS bundle id，也是 API 请求头里的 `package_name` —— 两者同名会以为只有一个。
建 Android client 时填错包名的表现是「Google 登录失败而其余功能正常」。

见 [`android/app/build.gradle.kts`](../android/app/build.gradle.kts) 的 `applicationId`。

Android client ID 本身不进代码、不进后端白名单 —— 它只是让 Google 认得
「这个包名 + 签名的 App 有权用我们的 web client id」，签发的 token `aud` 仍是 web client id。

一条 Android client = **一个包名 + 一个 SHA-1**，没法多填，所以 debug 与 release
签名各要一条。取 SHA-1：

```sh
cd android && ./gradlew :app:signingReport
```

⚠️ `~/.android/debug.keystore` 是**每台机器首次构建时各自随机生成**的，SHA-1 互不相同。
同事拉下代码跑 debug 会 Google 登录失败而其余功能正常 —— 要么每台机器的 SHA-1 都登记一条，
要么像 coucou-mobile 那样在仓库里固定一份共享 debug keystore。本仓目前**没做**共享 keystore。

若启用了 **Play App Signing**，商店里那个包的 SHA-1 与本地 release keystore 的不是同一个
（表现为「本地 release 能登、商店下载登不了」）：去 Play Console → 应用完整性 → 应用签名
取 Google 生成的 SHA-1 一并登记。

### iOS：填进 Local.xcconfig

```sh
cp ios/Flutter/Local.xcconfig.example ios/Flutter/Local.xcconfig   # 已被 .gitignore 忽略
```

填两个值（Console 页面直接给出）：

```
GOOGLE_IOS_CLIENT_ID=000000000000-xxxxxxxx.apps.googleusercontent.com
GOOGLE_IOS_URL_SCHEME=com.googleusercontent.apps.000000000000-xxxxxxxx
```

`Info.plist` 的 `GIDClientID` / `CFBundleURLTypes` 已用 `$(...)` 引用它们，不必再改。
**URL scheme 漏配的表现是「授权完停在 Safari、App 没反应」**，不是任何可辨识的报错 ——
GIDSignIn 靠它把结果回跳进 App。

### 切 stage 环境

`AppConfig.coucouBaseUrl` 当前指向生产 `https://api.coucou.fun`，`googleServerClientId`
的内置默认值与之配对。切 stage 时两个一起改，或构建时覆盖：

```sh
flutter build apk --dart-define=GOOGLE_SERVER_CLIENT_ID=<stage web client id>
```

**不要从仓库配置文件推断某环境在用哪条 web client id** —— 生产的
`application-cloud.properties` 只存在于服务器上，本地 `application.properties` 的默认值
与生产实际使用的并不是同一条。直接问那个环境自己：

```sh
curl -sS -o /dev/null -D - \
  "https://api.coucou.fun/api/coucou/auth/oauth2/authorize/google?client=app" \
  | grep -i location      # URL 里的 client_id 就是答案
```

## 3. nonce 合约（改动时别踩）

客户端每次登录生成一枚随机原始 nonce（`Random.secure()`），**传给服务端的始终是原始值**；
传给 SDK 的形式各家不同：

- **Google**：原样传（`GoogleSignIn.initialize(nonce: raw)`），id_token 回显原始值；
- **Apple**（尚未接入）：传 `sha256(raw)` 十六进制，id_token 回显该哈希。

服务端按 provider 各自算期望值比对。改任何一端都要两端一起改，否则登录会以
`id_token nonce mismatch` 静默失败。

> `nonce` 是 `initialize` 级参数（SDK 未开放 per-authenticate 传入），所以
> [`native_oauth_client.dart`](../lib/services/native_oauth_client.dart) 每次登录前**重新
> initialize** 以换取每次不同的 nonce。这是安全的：两个移动平台的 `init()` 都只是赋值字段。

## 4. 已知边界

- **无 Google Play 服务的设备**（华为、部分国产 ROM、无 GApps 模拟器）：Credential Manager 报
  `providerConfigurationError` 且**不会**自己退回浏览器 → 这些设备登不了 Google，
  App 提示「当前设备不支持 Google 登录，请改用账号密码登录」。
  刻意**不接** `clientConfigurationError`（少配 serverClientId / SHA-1 未登记之类）——
  那是构建配置错误，掩盖成「设备不支持」会让联调时永远查不出来。
- **首次登录自动建号**：`bound=false` 时本 App **自动**调 `/oauth2/bind`（不传邀请码），
  后端按邮箱自动合并到同邮箱老账号或新建。CouCou H5/App 会中断到补充信息页收邀请码，
  本 App 没有该流程，故直通。
- **Sign in with Apple 尚未接入**。⚠️ App Store 审核指南 **4.8**：iOS 上提供了第三方登录
  就**必须**同时提供 Sign in with Apple —— 本 App 上了 Google 之后，
  **Apple 登录成为上架阻断项**。最短见效路径：Apple 开发者后台给 `jp.sentino.general`
  勾 "Sign in with Apple" + 重新生成 profile + 后端 `APPLE_NATIVE_AUDIENCES=jp.sentino.general`，
  不需要 Service ID / client secret / `.p8`。客户端侧
  [`native_oauth_client.dart`](../lib/services/native_oauth_client.dart) 已按可加 provider 的
  形状写好（`NativeCredential.fullName` 就是给 Apple 首次授权的姓名留的）。

## 5. 自检

```sh
flutter analyze
flutter test test/auth
flutter run
```

- Android：点「使用 Google 账号登录」应弹出**系统账号选择弹窗**（不是浏览器）；
- 后端未配 `GOOGLE_NATIVE_AUDIENCES` → 400 → App 显示通用错误，此时先查第 1 节；
- 弹窗**根本不出现**且日志有 `MISSING_SERVER_CLIENT_ID` → `googleServerClientId` 没生效；
- 弹窗出现但选账号后失败 → SHA-1 / 包名没在 Console 登记对。
