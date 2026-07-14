import 'package:dio/dio.dart';
import '../../models/agent.dart';
import '../../models/device.dart';
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
  final Dio _dio;

  CoucouApi({required StorageUtil storage})
      : _storage = storage,
        _dio = Dio(BaseOptions(
          baseUrl: AppConfig.coucouBaseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
          headers: {'Content-Type': 'application/json'},
          // 4xx 不抛 DioException，交由下方按 body 解析出可读错误
          validateStatus: (s) => s != null && s < 500,
        ));

  /// coucou / dragonflow 登录 → 返回 access_token（JWT）。失败抛 [CoucouApiException]。
  Future<String> login(String email, String password) async {
    final resp = await _dio.post('/api/coucou/auth/login',
        data: {'email': email, 'password': password});
    final data = resp.data;
    if (resp.statusCode == 200 && data is Map) {
      final token = data['access_token'] ?? data['accessToken'];
      if (token is String && token.isNotEmpty) return token;
    }
    throw CoucouApiException(_message(data) ?? '登录失败', resp.statusCode);
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
