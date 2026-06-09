# Flutter Web 自动化截图流程

用 puppeteer 控制本地 Chrome 跑 Flutter Web，生成功能截图。本指南记录本机网络环境下（墙了 `*.gstatic.com`）让这条链路跑通的全部前提与排坑。

> 已在 macOS 26.1 + Flutter 3.44.0 + Chrome 148 + Node 25 验证通过，生成 7 张 400x900 截图，中文 i18n + 中文 mock 数据均正常渲染。

---

## 0. 适用场景

- 给 PR 描述/产品评审/对外文档贴功能截图
- 不依赖真机/模拟器，CI 也可以跑
- **不**用于回归测试（puppeteer 用坐标点击，UI 改一下坐标全废）

不适用：iOS/Android 平台特有交互（蓝牙、相机、push）。

## 1. 整体思路

```
Flutter Web (release build → build/web/)
        ↑ 本地静态服务 :8767
        ↑
   puppeteer-core 驱动系统 Chrome
        + 拦截 fonts.gstatic.com → 注入 Noto CJK 字体
        + 重写 navigator.language → zh-CN
        + CSS 坐标 click/type 模拟交互
        + screenshot 保存 PNG
```

## 2. 一次性准备

### 2.1 关键依赖

- **系统 Chrome**：`/Applications/Google Chrome.app/Contents/MacOS/Google Chrome`
- **Node 18+**：跑 puppeteer 和静态 server
- **完整 CJK 字体**（含 Latin + 中文，约 16MB）：

  ```bash
  curl -sL --max-time 60 -o tmp/screenshot/cjk-full.otf \
    "https://cdn.jsdelivr.net/gh/notofonts/noto-cjk@main/Sans/OTF/SimplifiedChinese/NotoSansCJKsc-Regular.otf"
  ```

  > 必须**含 Latin + CJK 的同一个文件**。fontsource 那种按 unicode-range 切片的 woff2 不行——Flutter 只请求一个 URL，subset 喂上去会缺字符。

### 2.2 准备工作目录

```bash
mkdir -p tmp/screenshot/shots
cd tmp/screenshot
npm init -y >/dev/null
npm install puppeteer-core --no-audit --no-fund
```

`tmp/` 在 `.gitignore` 里，不会污染仓库。

### 2.3 本地静态 server（`tmp/screenshot/server.js`）

**不能用 `python -m http.server` 或 `npx serve`** — 它们在 puppeteer 高并发请求下会断连。自己写一个最小 node http server，无 keepalive 困扰：

```js
const http = require('http'); const fs = require('fs'); const path = require('path');
const ROOT = process.argv[2] || './build/web';
const PORT = parseInt(process.argv[3] || '8767', 10);
const MIME = { '.html':'text/html','.js':'application/javascript','.mjs':'application/javascript',
  '.json':'application/json','.css':'text/css','.png':'image/png','.svg':'image/svg+xml',
  '.woff2':'font/woff2','.otf':'font/otf','.ttf':'font/ttf','.wasm':'application/wasm','.bin':'application/octet-stream' };
http.createServer((req, res) => {
  let p = decodeURIComponent(req.url.split('?')[0]);
  if (p === '/' || p === '') p = '/index.html';
  const full = path.join(ROOT, p);
  if (!full.startsWith(ROOT)) return res.writeHead(403).end();
  fs.stat(full, (err, st) => {
    if (err || !st.isFile()) return res.writeHead(404).end();
    res.writeHead(200, { 'Content-Type': MIME[path.extname(full).toLowerCase()] || 'application/octet-stream',
      'Content-Length': st.size, 'Access-Control-Allow-Origin': '*' });
    fs.createReadStream(full).pipe(res);
  });
}).listen(PORT, '127.0.0.1', () => console.log(`http://127.0.0.1:${PORT}`));
```

## 3. 单次跑截图流程

### 3.1 临时切 mock 模式（截图后还原）

```dart
// lib/utils/app_config.dart
static bool get useMock => true;
```

> 不需要改 `mock_auth_repository`：mock 用户表里已经有 `demo@demo.com: demo123`，符合 client validator 的 email 要求，登录可直接走真实 UI 流程。

### 3.2 Build web

```bash
flutter build web --release
```

约 50-70s。每次 build 会**覆盖** `build/web/flutter_bootstrap.js`，下一步的 patch 必须重新打。

### 3.3 关键 patch：让 canvaskit 走本地

默认 `flutter_bootstrap.js` 末尾长这样：

```js
_flutter.loader.load({
  serviceWorkerSettings: { serviceWorkerVersion: "..." }
});
```

`canvaskit.js`/`canvaskit.wasm` 会从 `https://www.gstatic.com/flutter-canvaskit/<engineRevision>/...` 加载——本机访问不到。

`build/web/canvaskit/chromium/canvaskit.js` build 时就已经包含，只需在 loader config 里告诉它走本地：

```js
_flutter.loader.load({
  config: { canvasKitBaseUrl: "canvaskit/" },        // ← 加这一行
  serviceWorkerSettings: { serviceWorkerVersion: "..." }
});
```

可以 `sed -i ''` 自动 patch，但因为 service worker version 每次 build 变，建议手工 Edit 或脚本里搜 `_flutter.loader.load({` 前插入。

### 3.4 启 server

```bash
node tmp/screenshot/server.js &
curl -s -o /dev/null -w "HTTP %{http_code}\n" http://127.0.0.1:8767/   # 期望 200
```

### 3.5 跑 puppeteer 脚本

```bash
node tmp/screenshot/shoot.js
```

脚本核心要点见下一节。

### 3.6 还原

```dart
// lib/utils/app_config.dart
static bool get useMock => false;
```

## 4. puppeteer 脚本要点

完整脚本见 `tmp/screenshot/shoot.js`。下面只列**必须做对**的几条：

### 4.1 拦截字体请求

```js
const cjkFont = fs.readFileSync('cjk-full.otf');
await page.setRequestInterception(true);
page.on('request', (req) => {
  if (req.url().includes('fonts.gstatic.com')) {
    req.respond({ status: 200, contentType: 'font/otf',
      headers: { 'Access-Control-Allow-Origin': '*' }, body: cjkFont });
  } else if (req.url().includes('fonts.googleapis.com')) {
    req.abort();
  } else {
    req.continue();
  }
});
```

Flutter Web canvaskit 在 boot 时会请求 Roboto woff2，本机被墙。喂任意有效的字体文件（这里是 Noto CJK SC）canvaskit 都会拿去渲染——所以**只要这一个字体含 Latin + CJK，全部文字都能显示**。

> ⚠️ canvaskit 不读浏览器/macOS 系统字体。这是 wasm 内部用 SkFontMgr，必须通过这条注入路径喂字体。

### 4.2 中文 locale

```js
const browser = await puppeteer.launch({
  args: ['--lang=zh-CN', '--accept-lang=zh-CN,zh,en', ...],
  ...
});
await page.setExtraHTTPHeaders({ 'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8' });
await page.evaluateOnNewDocument(() => {
  Object.defineProperty(navigator, 'language',  { get: () => 'zh-CN' });
  Object.defineProperty(navigator, 'languages', { get: () => ['zh-CN','zh','en'] });
});
```

**三联击都要**：chrome args 控制底层、HTTP header 走网络层、`navigator.language` 覆盖供 Flutter `PlatformDispatcher.locale` 读到。少任何一个都可能 locale 漂回 en。

### 4.3 坐标系——CSS 像素，不是截图像素

viewport 设 `{ width: 400, height: 900, deviceScaleFactor: 2 }`：

- 截图分辨率 = **800 × 1800** 像素
- `mouse.click(x, y)` / `mouse.move(x, y)` 用的是 **CSS 坐标 400 × 900**

**算 click 坐标的方法**：先截一张静态截图，看目标元素在截图里的像素 y，**除以 deviceScaleFactor (2)** 得到 CSS y。

我第一遍用截图像素直接当坐标，所有 click 都偏，TabBar 没击中、字段填错位置——找了一个小时。

### 4.4 等 Flutter render

`page.goto + waitUntil:'load'` 之后 Flutter 还在 boot wasm。最简单的检测：

```js
for (let i = 0; i < 30; i++) {
  await sleep(2000);
  const buf = await page.screenshot({ encoding: 'binary' });
  if (buf.length > 30000) break;   // 空白页 ~7-8KB，渲染好后 > 30KB
}
```

冷启动通常 3-5s。

### 4.5 输入清空

Flutter Web TextField 可能残留上一次的内容（特别是 reused controller），输入前按 50 次 Backspace 兜底：

```js
await page.mouse.click(x, y);
for (let i = 0; i < 50; i++) await page.keyboard.press('Backspace');
await page.keyboard.type(text, { delay: 30 });
```

## 5. 排坑清单

| 现象 | 根因 | 解决 |
|---|---|---|
| 截图全白 ~7-8KB | canvaskit 加载失败（`net::ERR_FAILED https://www.gstatic.com/flutter-canvaskit/.../canvaskit.js`） | patch `flutter_bootstrap.js` 加 `config: { canvasKitBaseUrl: "canvaskit/" }` |
| 截图有 logo/图标但所有文字消失 | `https://fonts.gstatic.com/.../Roboto-...woff2` 加载失败 | puppeteer 拦截层喂本地字体 |
| 中文是方块 | 喂的字体不含 CJK（如默认 Roboto Latin） | 换含 Latin + CJK 的字体，如 NotoSansCJKsc OTF |
| `python -m http.server` / `npx serve` 中途断连，`net::ERR_CONNECTION_CLOSED` | 单线程/默认 keepalive 配置扛不住 canvaskit 并发请求 | 用 `tmp/screenshot/server.js` 自写的最小 node http server |
| Click 坐标完全偏移 | 把截图像素当 CSS 坐标 | CSS y = 截图像素 y / deviceScaleFactor |
| Tab 切换没生效，点到了下面的卡片 | TabBar hit-test 区域比想象的小 | 严格按 CSS 坐标点 Tab label 中心，不是 padding 区 |
| 登录页 Login 按钮 disabled 点不动 | 没勾协议复选框 / 账号不是 email 格式 | 复选框精确点 (44, 452)；mock 用 `demo@demo.com` |
| `flutter build web` 后 canvaskit 又走 gstatic 了 | build 重写 `flutter_bootstrap.js` 覆盖 patch | 每次 rebuild 后**手动重打** patch |
| Flutter Web dev mode (`flutter run -d chrome`) 在 puppeteer 控制的 chrome 里不渲染 | DDC dev runtime 依赖 Dart Debug Chrome Extension，puppeteer 默认 profile 没装 | 用 `flutter build web --release` 出生产 bundle |
| nohup 启动的 server 进程跟着 puppeteer chrome 一起死 | shell 信号传递 | 用 Bash 工具的 `run_in_background: true` 启 server，独立生命周期 |

## 6. 维护建议

- **坐标改了要重新校准**：UI 任何位置/spacing 调整都可能让 click 失效。改 UI 后第一次跑 shoot 务必逐张肉眼检查。
- **字体文件别提交 git**：16MB OTF 放 `tmp/screenshot/cjk-full.otf`，跟着 `.gitignore`。新机器跑前 `curl` 一遍。
- **截图保存到 `tmp/screenshot/shots/`** —— 同样不进 git。要 commit 截图就单独 `cp` 到 `doc/screenshots/`。
- **本机网络不通时优先怀疑这条**：本机 `curl https://www.gstatic.com/` 不通 → canvaskit/字体全失败的根因。其他机器（直连 google）可能根本不需要本指南的所有 hack。

## 7. 参考产出

最近一次截图位置：`tmp/screenshot/shots/`，覆盖：

- 登录页（demo@demo.com / 中文 i18n / 协议已勾）
- 智能体 tab（推荐 / 自定义 双 TabBar）
- 自定义智能体创建页（空 / 填好 / API Key 显隐切换）
