import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../models/agent.dart';
import '../../models/device.dart';
import '../../models/user.dart';
import '../../utils/app_config.dart';
import '../../utils/storage.dart';

/// coucou-server（dragonflow）客户端 —— 与 cetus [ApiClient] 分离，不注入 cetus 公共头。
///
/// - [login]：coucou / dragonflow 统一账号登录（`/api/coucou/auth/*` 透传 workflow-api）→ 拿 dragonflow JWT。
/// - [linkLegacyIot]：旧 IoT 认证 —— 用旧 cetus 账密显式关联存量账号（带 dragonflow JWT）。
///
/// 设计见 coucou-iot-auth-federation-design.md（UID 默认 + 显式关联）。
class CoucouApi {
  final StorageUtil _storage;
  late final Dio _dio;

  /// access token 过期且刷新也失败（refresh 也过期/会话失效）时触发。
  /// 此时本地凭证已清空，需由外部跳转登录页。挂载见 main.dart。
  VoidCallback? onSessionExpired;

  /// 刷新去重：多个请求同时 401 时只发一次刷新，其余复用同一 Future。
  Future<String?>? _refreshInFlight;

  /// 已续期重放的标记，防止刷新后仍 401 造成无限循环。
  static const String _retriedFlag = '__cc_refresh_retried';

  CoucouApi({required StorageUtil storage}) : _storage = storage {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.coucouBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        // 带规范 User-Agent,让会话列表能识别为 CouCou App + 平台(否则前端 UA 解析兜底成 Browser·Unknown)。
        'User-Agent':
            'CouCouApp/${AppConfig.appVersion} (${AppConfig.osName}; Flutter)',
        // 稳定设备指纹:dragonflow 按 device_fingerprint_hash 去重会话(同一台机器多次登录归一台)。
        // 值在 app 启动时 storage.initDeviceFingerprint() 从硬件标识派生;这里同步读缓存。
        'X-Device-Fingerprint': storage.getDeviceFingerprint(),
      },
      // 4xx 不抛 DioException，交由下方按 body 解析出可读错误
      validateStatus: (s) => s != null && s < 500,
    ));
    // Accept-Language 每请求动态注入（BCP-47），供上游按用户语言渲染验证码邮件（§5.5，5 语繁简分开）。
    // 构造期静态 header 跟不上运行时切语言，故用拦截器每次现算。
    _dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      options.headers['Accept-Language'] = _resolveAcceptLanguage();
      handler.next(options);
    }));
    // dragonflow JWT 过期时后端返回 401；此拦截器静默用 refresh token 换新 access → 重放原请求，
    // 用户不再被「token 失效」踢回登录页（历史坑：coucou 模式从不续期，过期后一直硬打 401）。
    // 注意 validateStatus<500 使 401 走 onResponse（非 onError）。
    _dio.interceptors.add(InterceptorsWrapper(onResponse: _onResponse));
  }

  /// 解析当前生效语言 → BCP-47（与 LocaleProvider.language 口径一致）：
  /// 显式选择（`app_locale` pref）优先，否则跟随系统 locale。
  String _resolveAcceptLanguage() {
    final override = _storage.getLocaleOverrideTag(); // 形如 zh_CN；null=跟随系统
    Locale locale;
    if (override != null && override.isNotEmpty) {
      final parts = override.split('_');
      locale = Locale(parts[0], parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null);
    } else {
      locale = PlatformDispatcher.instance.locale;
    }
    return _toBcp47(locale);
  }

  /// 归一到上游支持的 5 语 BCP-47（对齐 coucou-app / workflow-api），命不中 fallback en。繁简分开。
  static String _toBcp47(Locale l) {
    final lang = l.languageCode.toLowerCase();
    final region = (l.countryCode ?? '').toUpperCase();
    final script = (l.scriptCode ?? '').toLowerCase();
    if (lang == 'zh') {
      if (region == 'TW' || region == 'HK' || region == 'MO' || script == 'hant') return 'zh-TW';
      return 'zh-CN';
    }
    if (lang == 'ja') return 'ja';
    if (lang == 'ko') return 'ko';
    return 'en';
  }

  /// 401 → 静默刷新 dragonflow JWT → 用新 token 重放原请求。
  Future<void> _onResponse(
      Response response, ResponseInterceptorHandler handler) async {
    final opts = response.requestOptions;
    final is401 = response.statusCode == 401;
    // 登录/刷新端点本身的 401 是真失败，不参与续期；已重放过的也不再刷（防循环）。
    final isAuthFlow = opts.path.contains('/auth/login') ||
        opts.path.contains('/auth/refresh-token');
    final alreadyRetried = opts.extra[_retriedFlag] == true;
    if (!is401 || isAuthFlow || alreadyRetried) {
      return handler.next(response);
    }
    final rt = _storage.getRefreshToken();
    if (rt == null || rt.isEmpty) {
      // 无 refresh token（旧登录态未存 refresh）→ 无法续期，须清凭证再登出。
      // ⚠️ 必须清 access token：否则残留使 storage.isLoggedIn 仍 true，
      //    router _guard 会把 go(login) 弹回 home，用户卡在空白页（正是本次 bug）。
      await _storage.removeAccessToken();
      await _storage.removeRefreshToken();
      onSessionExpired?.call();
      return handler.next(response);
    }
    String? newToken;
    try {
      newToken = await _ensureRefreshed();
    } on _RefreshNetworkException {
      // 刷新遇网络/服务端临时错误（非 refresh 失效）→ 保留凭证、不登出；本次请求以原 401 返回
      // （上层 best-effort 降级），网络恢复后下次请求自动续期自愈。
      return handler.next(response);
    }
    if (newToken == null) {
      onSessionExpired?.call();
      return handler.next(response);
    }
    // 用新 token 重放原请求。
    opts.extra[_retriedFlag] = true;
    opts.headers['Authorization'] = 'Bearer $newToken';
    try {
      final retried = await _dio.fetch<dynamic>(opts);
      return handler.resolve(retried);
    } on DioException catch (e) {
      if (e.response != null) return handler.resolve(e.response!);
      return handler.next(response);
    }
  }

  /// 刷新去重入口：并发 401 只触发一次实际刷新，其余复用同一 Future。
  Future<String?> _ensureRefreshed() {
    return _refreshInFlight ??=
        _performRefresh().whenComplete(() => _refreshInFlight = null);
  }

  /// POST /api/coucou/auth/refresh-token（body {refreshToken}）→ 存新 access+refresh，返回新 access。
  /// 三态：① 成功 → 新 access token；② refresh 明确失效（端点非 200 / 无 token）→ 清凭证返回 null（上层登出）；
  /// ③ 网络/服务端临时错误（超时/断连/5xx）→ 抛 [_RefreshNetworkException]（保留凭证、不登出，下次自愈）。
  Future<String?> _performRefresh() async {
    final rt = _storage.getRefreshToken();
    if (rt == null || rt.isEmpty) return null;
    final Response resp;
    try {
      resp = await _dio.post(
        '/api/coucou/auth/refresh-token',
        data: {'refreshToken': rt}, // 上游按 camelCase 读取（AuthController）
        options: Options(extra: {_retriedFlag: true}), // 防自身被拦截再刷
      );
    } on DioException {
      // validateStatus<500 使 refresh 失效的 4xx 走正常响应（不抛）；能抛到这里的只有
      // 网络层错误（超时/断连/取消）或 5xx —— 都是临时故障，保留凭证、交由上层放弃本次续期。
      throw _RefreshNetworkException();
    }
    if (resp.statusCode == 200 && resp.data is Map) {
      final m = resp.data as Map;
      final at = (m['access_token'] ?? m['accessToken'])?.toString();
      final nrt = (m['refresh_token'] ?? m['refreshToken'])?.toString();
      if (at != null && at.isNotEmpty) {
        await _storage.saveAccessToken(at);
        if (nrt != null && nrt.isNotEmpty) {
          await _storage.saveRefreshToken(nrt);
        }
        return at;
      }
    }
    // refresh 明确失效（非 200 / 无 token）→ 清本地凭证，上层据此登出。
    await _storage.removeAccessToken();
    await _storage.removeRefreshToken();
    return null;
  }

  /// coucou / dragonflow 登录 → 返回 access + refresh token（JWT）。失败抛 [CoucouApiException]。
  Future<({String accessToken, String? refreshToken})> login(
      String email, String password) async {
    final resp = await _dio.post('/api/coucou/auth/login',
        data: {'email': email, 'password': password});
    final data = resp.data;
    if (resp.statusCode == 200 && data is Map) {
      final token = (data['access_token'] ?? data['accessToken'])?.toString();
      final refresh =
          (data['refresh_token'] ?? data['refreshToken'])?.toString();
      if (token != null && token.isNotEmpty) {
        return (accessToken: token, refreshToken: refresh);
      }
    }
    throw CoucouApiException(_message(data) ?? '登录失败', resp.statusCode);
  }

  // ── 注册前置验证码码流（scene=register）──

  /// 注册前置发码：校验邮箱未注册 + 发 6 位码。返回 (倒计时间隔, 码长)。失败抛 [CoucouApiException]（EMAIL_EXISTS / RATE_LIMITED …）。
  Future<({int intervalSeconds, int codeLength})> sendRegisterCode(String email) async {
    final resp = await _dio.post('/api/coucou/auth/register/send-code', data: {'email': email});
    final data = resp.data;
    if (resp.statusCode == 200 && data is Map) {
      return (
        intervalSeconds: (data['interval_seconds'] as num?)?.toInt() ?? 60,
        codeLength: (data['code_length'] as num?)?.toInt() ?? 6,
      );
    }
    throw CoucouApiException(_message(data) ?? '发送验证码失败', resp.statusCode);
  }

  /// 注册验证码预校验（不消费）。有效 true；码错/过期返回 false（对齐 cetus checkVerifyCode 语义，让 UI 提示重输）。
  Future<bool> checkRegisterCode(String email, String code) async {
    final resp = await _dio.post('/api/coucou/auth/register/verify-code',
        data: {'email': email, 'code': code});
    final data = resp.data;
    return resp.statusCode == 200 && data is Map && (data['valid'] == true || data['success'] == true);
  }

  /// 注册（带 code，自动登录）→ 返回 access_token（JWT）。失败抛 [CoucouApiException]（CODE_INVALID / CODE_EXPIRED …）。
  Future<String> register(String email, String password, String code) async {
    final resp = await _dio.post('/api/coucou/auth/register',
        data: {'email': email, 'password': password, 'code': code});
    final data = resp.data;
    if (resp.statusCode == 200 && data is Map) {
      final token = data['access_token'] ?? data['accessToken'];
      if (token is String && token.isNotEmpty) return token;
    }
    throw CoucouApiException(_message(data) ?? '注册失败', resp.statusCode);
  }

  // ── 找回密码码流（scene=reset）──

  /// 找回密码发码（恒 200 防枚举，邮箱不存在也返回同结构）。返回 (倒计时间隔, 码长)。
  Future<({int intervalSeconds, int codeLength})> forgotPassword(String email) async {
    final resp = await _dio.post('/api/coucou/auth/forgot-password', data: {'email': email});
    final data = resp.data;
    if (resp.statusCode == 200 && data is Map) {
      return (
        intervalSeconds: (data['interval_seconds'] as num?)?.toInt() ?? 60,
        codeLength: (data['code_length'] as num?)?.toInt() ?? 6,
      );
    }
    throw CoucouApiException(_message(data) ?? '发送验证码失败', resp.statusCode);
  }

  /// 找回验证码预校验（不消费）。有效 true；否则 false。
  Future<bool> checkForgotCode(String email, String code) async {
    final resp = await _dio.post('/api/coucou/auth/forgot-password/verify-code',
        data: {'email': email, 'code': code});
    final data = resp.data;
    return resp.statusCode == 200 && data is Map && (data['valid'] == true || data['success'] == true);
  }

  /// 重置密码（email + code + 新密码）。成功后上游失效该用户所有 session。失败抛 [CoucouApiException]。
  Future<void> resetPassword(String email, String code, String newPassword) async {
    final resp = await _dio.post('/api/coucou/auth/reset-password',
        data: {'email': email, 'code': code, 'new_password': newPassword});
    final data = resp.data;
    if (resp.statusCode == 200) return;
    throw CoucouApiException(_message(data) ?? '重置密码失败', resp.statusCode);
  }

  /// coucou 模式用户资料：GET /api/coucou/auth/me（带 dragonflow JWT）。
  /// ⚠️ cetus 的 business-app/v1/user/profile 在 coucou 态取不到（无 cetus session），故必须走此端点。
  /// 返回体是 coucou-server（AuthMeController）自包的一层、**snake_case**：
  ///   {user:{id,username,email,full_name,avatar_url,phone,...}, coucou:{status,display_name,avatar_url}}
  /// 手动映射到 [User]（display_name/full_name 作昵称，coucou.avatar_url 优先）。
  Future<User> getMe() async {
    final token = _storage.getAccessToken();
    final resp = await _dio.get(
      '/api/coucou/auth/me',
      options: Options(headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      }),
    );
    if (resp.statusCode == 200 && resp.data is Map) {
      final root = resp.data as Map;
      final u = root['user'] is Map
          ? Map<String, dynamic>.from(root['user'] as Map)
          : <String, dynamic>{};
      final c = root['coucou'] is Map
          ? Map<String, dynamic>.from(root['coucou'] as Map)
          : <String, dynamic>{};
      return User(
        uid: u['id']?.toString(),
        email: u['email']?.toString(),
        userName: u['username']?.toString(),
        nickname: (c['display_name'] ?? u['full_name'])?.toString(),
        avatarUrl: (c['avatar_url'] ?? u['avatar_url'])?.toString(),
        phoneNumber: u['phone']?.toString(),
      );
    }
    throw CoucouApiException(_message(resp.data) ?? '用户信息获取失败', resp.statusCode);
  }

  /// 旧 IoT 认证：显式关联存量 cetus 账号（带当前 dragonflow JWT）。
  /// 返回后端 body（含 linked / iot_user_id / devices）。凭证无效 → 401 → [CoucouApiException]。
  Future<Map<String, dynamic>> linkLegacyIot(
      String cetusEmail, String cetusPassword) async {
    final token = _storage.getAccessToken();
    final resp = await _dio.post(
      '/api/coucou/devices/link-legacy-iot',
      data: {'cetus_email': cetusEmail, 'cetus_password': cetusPassword},
      options: Options(headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      }),
    );
    final data = resp.data;
    if (resp.statusCode == 200 && data is Map) {
      return Map<String, dynamic>.from(data);
    }
    throw CoucouApiException(_message(data) ?? '关联失败', resp.statusCode);
  }

  /// coucou 模式设备列表：`GET /api/coucou/devices`（带 dragonflow JWT）→ 映射为 [Device]。
  /// 后端 best-effort（上游故障也返回 {devices:[]}）；非 200 抛 [CoucouApiException] 交上层降级。
  Future<List<Device>> listDevices() async {
    final token = _storage.getAccessToken();
    final resp = await _dio.get(
      '/api/coucou/devices',
      options: Options(headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      }),
    );
    final data = resp.data;
    if (resp.statusCode == 200 && data is Map && data['devices'] is List) {
      return (data['devices'] as List)
          .whereType<Map>()
          .map((d) => _deviceFromCoucou(Map<String, dynamic>.from(d)))
          .toList();
    }
    throw CoucouApiException(_message(data) ?? '设备列表获取失败', resp.statusCode);
  }

  /// coucou-server 设备 JSON（snake_case）→ 复用 cetus 侧 [Device] 模型（供 DeviceCard 展示）。
  static Device _deviceFromCoucou(Map<String, dynamic> j) {
    final uuid = j['device_uuid']?.toString() ?? '';
    final online = j['online'] == true;
    return Device(
      deviceId: uuid, // 列表 key + 路由 /device/{id}
      uuid: uuid,
      productId: j['product_id']?.toString(),
      name: j['name']?.toString(),
      onlineStatusCode: online ? 1 : 0, // Device.online = code==1
    );
  }

  /// coucou 角色列表(scope=all=我的全集/subscribed/owned)→ 映射为 [Agent](复用卡片)。带 dragonflow JWT。
  /// 默认 all:Coucou tab / 设备切换角色分区显示用户全部 coucou 角色(subscribed 常为空)。
  Future<List<Agent>> listCoucouAgents({String scope = 'all'}) async {
    final token = _storage.getAccessToken();
    final resp = await _dio.get(
      '/api/coucou/agents',
      queryParameters: {'scope': scope},
      options: Options(headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      }),
    );
    if (resp.statusCode != 200) {
      throw CoucouApiException(_message(resp.data) ?? '角色列表获取失败', resp.statusCode);
    }
    final data = resp.data;
    final list = data is List
        ? data
        : (data is Map
            ? (data['agents'] ?? data['data'] ?? data['records'] ?? data['list'] ?? const [])
            : const []);
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((e) => _coucouAgent(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// 收藏/关注 coucou 角色(加入「我的」)。
  Future<void> favoriteCoucouAgent(String coucouAgentId) async {
    final token = _storage.getAccessToken();
    final resp = await _dio.post(
      '/api/coucou/agents/$coucouAgentId/favorite',
      options: Options(headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      }),
    );
    if (resp.statusCode != 200) {
      throw CoucouApiException(_message(resp.data) ?? '收藏失败', resp.statusCode);
    }
  }

  /// 设备切换到某 coucou 角色(后端绑设备时懒建 cetus 镜像 + 绑定)。
  Future<void> setDeviceAgent(String deviceUuid, String coucouAgentId) async {
    final token = _storage.getAccessToken();
    final resp = await _dio.put(
      '/api/coucou/devices/$deviceUuid/agent',
      data: {'coucou_agent_id': coucouAgentId},
      options: Options(headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      }),
    );
    if (resp.statusCode != 200) {
      throw CoucouApiException(_message(resp.data) ?? '切换角色失败', resp.statusCode);
    }
  }

  /// 查设备当前绑定的角色:GET /devices/{uuid}/agent → {agent:{...}|null}。best-effort→null。
  /// 镜像的 Coucou 角色 agent_type='coucou'(agentId=coucou 角色 id);cetus 原生为 sentino/customize。
  Future<Agent?> getDeviceBoundAgent(String deviceUuid) async {
    final token = _storage.getAccessToken();
    final resp = await _dio.get(
      '/api/coucou/devices/$deviceUuid/agent',
      options: Options(headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      }),
    );
    if (resp.statusCode == 200 && resp.data is Map) {
      final a = (resp.data as Map)['agent'];
      if (a is Map) return _cetusAgent(Map<String, dynamic>.from(a));
    }
    return null;
  }

  /// 绑定 cetus 原生 agent(为我推荐/自定义)到设备:POST /devices/{uuid}/cetus-agent {agent_id,agent_type}。
  /// coucou 模式 flutter 无 cetus token,经 coucou-server 用 per-user cetus token 代理绑定(区别于 [setDeviceAgent] 的 coucou 角色镜像)。
  Future<void> bindCetusAgent(String deviceUuid, String agentId, String agentType) async {
    final token = _storage.getAccessToken();
    final resp = await _dio.post(
      '/api/coucou/devices/$deviceUuid/cetus-agent',
      data: {'agent_id': agentId, 'agent_type': agentType},
      options: Options(headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      }),
    );
    if (resp.statusCode != 200) {
      throw CoucouApiException(_message(resp.data) ?? '绑定失败', resp.statusCode);
    }
  }

  /// coucou 角色公开信息(扫码预览;GET /agents/{id}/public)→ [Agent]。不存在/未发布 → [CoucouApiException]。
  Future<Agent> agentPublic(String coucouAgentId) async {
    final token = _storage.getAccessToken();
    final resp = await _dio.get(
      '/api/coucou/agents/$coucouAgentId/public',
      options: Options(headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      }),
    );
    if (resp.statusCode == 200 && resp.data is Map) {
      return _coucouAgent(Map<String, dynamic>.from(resp.data as Map));
    }
    throw CoucouApiException(_message(resp.data) ?? '角色不存在', resp.statusCode);
  }

  /// 解析 coucou 角色二维码 → agentId(设计 coucou-agent-iot-mirror-design.md §7.3)。
  /// 契约:同域 URL,路径 `/c/{agentId}`(带 ref/source 归因参数);非 coucou 域/非 /c/ → null。
  static String? parseCoucouAgentQr(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return null;
    Uri u;
    try {
      u = Uri.parse(v);
    } catch (_) {
      return null;
    }
    if (u.scheme != 'http' && u.scheme != 'https') return null;
    final host = u.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
    final coucouHost =
        host == 'coucou.fun' || host.endsWith('.coucou.fun') || host.contains('coucou');
    if (!coucouHost) return null;
    final segs = u.pathSegments;
    if (segs.length >= 2 && segs[0] == 'c' && segs[1].isNotEmpty) return segs[1];
    return null;
  }

  /// coucou 角色 JSON(snake_case)→ 复用 cetus 侧 [Agent] 模型;agentType='coucou' 标记来源。
  static Agent _coucouAgent(Map<String, dynamic> j) => Agent(
        agentId: (j['agent_id'] ?? j['id'])?.toString(),
        name: j['name']?.toString(),
        avatarUrl: (j['card_url'] ?? j['avatar_url'] ?? j['avatarUrl'])?.toString(),
        description: j['description']?.toString(),
        agentType: 'coucou',
      );

  /// 代理 cetus agent 列表(coucou 模式):GET /api/coucou/iot/agents?kind=recommend|custom → [Agent]。
  Future<List<Agent>> listCetusAgents(String kind) async {
    final token = _storage.getAccessToken();
    final resp = await _dio.get(
      '/api/coucou/iot/agents',
      queryParameters: {'kind': kind},
      options: Options(headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      }),
    );
    if (resp.statusCode != 200) {
      throw CoucouApiException(_message(resp.data) ?? 'agent 列表获取失败', resp.statusCode);
    }
    final data = resp.data;
    final list = data is Map ? (data['agents'] ?? const []) : const [];
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((e) => _cetusAgent(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// cetus 代理 agent JSON(snake_case)→ [Agent];保留 agent_type(sentino/customize)供后续绑定。
  static Agent _cetusAgent(Map<String, dynamic> j) => Agent(
        agentId: (j['agent_id'] ?? j['id'])?.toString(),
        name: j['name']?.toString(),
        avatarUrl: (j['avatar_url'] ?? j['avatarUrl'])?.toString(),
        description: j['description']?.toString(),
        agentType: j['agent_type']?.toString() ?? 'sentino',
      );

  /// 代理 cetus 设备 dp 读(音量等):GET /api/coucou/devices/{uuid}/dp → dp 列表(原样,flutter 解析)。
  Future<List<Map<String, dynamic>>> getDeviceDp(String deviceUuid) async {
    final token = _storage.getAccessToken();
    final resp = await _dio.get(
      '/api/coucou/devices/$deviceUuid/dp',
      options: Options(headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      }),
    );
    if (resp.statusCode == 200 && resp.data is Map) {
      final dp = (resp.data as Map)['dp'];
      if (dp is List) {
        return dp.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
    }
    return const [];
  }

  /// 代理 cetus 设备属性下发(音量等):POST /api/coucou/devices/{uuid}/dp {data:{...}}。
  Future<void> setDeviceDp(String deviceUuid, Map<String, dynamic> data) async {
    final token = _storage.getAccessToken();
    final resp = await _dio.post(
      '/api/coucou/devices/$deviceUuid/dp',
      data: {'data': data},
      options: Options(headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      }),
    );
    if (resp.statusCode != 200) {
      throw CoucouApiException(_message(resp.data) ?? '下发失败', resp.statusCode);
    }
  }

  /// 配网扫描期取设备简要信息(name/imageUrl)——代理 cetus getSimpleDeviceInfo(走服务端 cetus token)。
  /// coucou 模式无 cetus token 走此;best-effort:失败/无数据 → null(调用方用默认名兜底)。
  Future<Map<String, dynamic>?> getDeviceInfo(String productId, String deviceUuid) async {
    final token = _storage.getAccessToken();
    final resp = await _dio.get(
      '/api/coucou/devices/$deviceUuid/info',
      queryParameters: {'productId': productId},
      options: Options(headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      }),
    );
    if (resp.statusCode == 200 && resp.data is Map && (resp.data as Map).isNotEmpty) {
      return Map<String, dynamic>.from(resp.data as Map);
    }
    return null;
  }

  /// 配网前取 cetus 透传参数:{user_id(cn20…), asset_id, broker, app_mqtt_password}。
  /// coucou 模式无 cetus token,userId/assetId 从这里取(非本地 storage);cetus 不可达 → 后端 503。
  Future<Map<String, dynamic>> provisionInit() async {
    final token = _storage.getAccessToken();
    final resp = await _dio.post(
      '/api/coucou/devices/provision-init',
      options: Options(headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      }),
    );
    if (resp.statusCode == 200 && resp.data is Map) {
      final p = (resp.data as Map)['provisioning'];
      if (p is Map) return Map<String, dynamic>.from(p);
    }
    throw CoucouApiException(_message(resp.data) ?? '配网参数获取失败', resp.statusCode);
  }

  /// 配网期轮询绑定结果——代理 cetus checkBindResult(走服务端 cetus token)。返状态码(0=已绑成功);失败 → -1。
  Future<int> checkBindResult(String deviceUuid) async {
    final token = _storage.getAccessToken();
    final resp = await _dio.post(
      '/api/coucou/devices/$deviceUuid/bind-check',
      options: Options(headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      }),
    );
    if (resp.statusCode == 200 && resp.data is Map) {
      final r = (resp.data as Map)['result'];
      if (r is int) return r;
      return int.tryParse(r.toString()) ?? -1;
    }
    return -1;
  }

  /// 是否 coucou 登录态(供 provider 判断走 coucou 代理还是 cetus 直调)。
  bool get isCoucouMode => _storage.isCoucouMode;

  /// 解绑设备——代理 cetus unbind(走服务端 cetus token)。deviceId=数字 device id;cleanData=是否清除数据。
  /// 写操作:失败抛 CoucouApiException(不静默)。
  Future<void> unbindDevice(String deviceId, {bool cleanData = false}) async {
    final token = _storage.getAccessToken();
    final resp = await _dio.delete(
      '/api/coucou/devices/$deviceId',
      queryParameters: {'cleanData': cleanData},
      options: Options(headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      }),
    );
    if (resp.statusCode != 200) {
      throw CoucouApiException(_message(resp.data) ?? '解绑失败', resp.statusCode);
    }
  }

  /// 代理 cetus 设备对话历史(读):POST /devices/{uuid}/chat-history {agent_id} → 消息列表(原样)。best-effort→空。
  Future<List<Map<String, dynamic>>> getDeviceChatHistory(String deviceUuid, String agentId) async {
    final token = _storage.getAccessToken();
    final resp = await _dio.post(
      '/api/coucou/devices/$deviceUuid/chat-history',
      data: {'agent_id': agentId},
      options: Options(headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      }),
    );
    if (resp.statusCode == 200 && resp.data is Map) {
      final m = (resp.data as Map)['messages'];
      if (m is List) {
        return m.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
    }
    return const [];
  }

  /// 代理清空 cetus 设备对话历史:POST /devices/{uuid}/chat-history/clean {agent_id}。
  Future<void> clearDeviceChatHistory(String deviceUuid, String agentId) async {
    final token = _storage.getAccessToken();
    final resp = await _dio.post(
      '/api/coucou/devices/$deviceUuid/chat-history/clean',
      data: {'agent_id': agentId},
      options: Options(headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      }),
    );
    if (resp.statusCode != 200) {
      throw CoucouApiException(_message(resp.data) ?? '清空失败', resp.statusCode);
    }
  }

  String? _message(dynamic data) {
    if (data is Map) {
      final m = data['message'] ?? data['error'];
      if (m != null) return m.toString();
    }
    return null;
  }
}

/// coucou-server 调用错误（带可读 message + HTTP 状态）。
class CoucouApiException implements Exception {
  final String message;
  final int? statusCode;

  CoucouApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

/// 刷新令牌时遇网络/服务端临时错误（超时/断连/5xx，非 refresh 失效）——
/// 用于让拦截器保留凭证、不触发登出，交由下次请求重试自愈。
class _RefreshNetworkException implements Exception {}
