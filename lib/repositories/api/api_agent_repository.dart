import 'package:flutter/foundation.dart';
import '../../models/agent.dart';
import '../../utils/api_client.dart';
import '../../utils/app_config.dart';
import '../agent_repository.dart';

/// Real API agent repository
class ApiAgentRepository implements AgentRepository {
  final ApiClient _api;

  ApiAgentRepository({required ApiClient api}) : _api = api;

  String get _recommendPrefix => AppConfig.agentPlatform == 'sentino'
      ? 'business-app/v1/sentino-agents'
      : 'business-app/v1/agents';

  @override
  Future<List<Agent>> getRecommendAgents() async {
    final url = '$_recommendPrefix/recommend/agents-list';
    debugPrint('[AgentRepo] getRecommendAgents → POST $url');
    try {
      final rawResp = await _api.dio.post(url);
      debugPrint('[AgentRepo] getRecommendAgents statusCode=${rawResp.statusCode}');
      debugPrint('[AgentRepo] getRecommendAgents rawData=${rawResp.data}');
      final body = rawResp.data as Map<String, dynamic>;
      final code = body['code'] as int? ?? -1;
      final message = body['message']?.toString() ?? '';
      debugPrint('[AgentRepo] getRecommendAgents bizCode=$code message=$message');
      if (code != 200) {
        throw ApiException(bizCode: code, message: message.isNotEmpty ? message : 'Failed');
      }
      final data = body['data'];
      debugPrint('[AgentRepo] getRecommendAgents data type=${data.runtimeType} data=$data');
      if (data == null || data is! List) {
        debugPrint('[AgentRepo] getRecommendAgents: data is null or not a List, returning empty');
        return [];
      }
      // 根据接口来源设置 agentType：sentino-agents → sentino，agents → official
      final defaultType = AppConfig.agentPlatform == 'sentino' ? 'sentino' : 'official';
      final agents = data.whereType<Map<String, dynamic>>().map((e) {
        if (e['agentType'] == null || (e['agentType'] as String).isEmpty) {
          e['agentType'] = defaultType;
        }
        return Agent.fromJson(e);
      }).toList();
      debugPrint('[AgentRepo] getRecommendAgents: parsed ${agents.length} agents');
      for (final a in agents) {
        debugPrint('[AgentRepo]   → id=${a.agentId} name=${a.name} type=${a.agentType}');
      }
      return agents;
    } catch (e, stack) {
      debugPrint('[AgentRepo] getRecommendAgents ERROR: $e');
      debugPrint('[AgentRepo] getRecommendAgents STACK: $stack');
      rethrow;
    }
  }

  Future<Agent> getAgentDetail(String agentId) async {
    final path = AppConfig.agentPlatform == 'sentino'
        ? 'business-app/v1/sentino-agents/detail'
        : 'business-app/v1/agents/detail';
    final resp = await _api.post(path,
        queryParameters: {'agentId': agentId},
        fromData: (d) => Agent.fromJson(d as Map<String, dynamic>));
    return resp.data!;
  }

  Future<Agent?> getAgentByDeviceId(String deviceId) async {
    try {
      final resp = await _api.post(
          'business-app/v1/agents/device/getAgentBaseByDeviceId',
          queryParameters: {'deviceId': deviceId},
          fromData: (d) => Agent.fromJson(d as Map<String, dynamic>));
      return resp.data;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getConversationHistory(
      String agentId, String targetId, String targetType) async {
    debugPrint('[AgentRepo] getConversationHistory agentId=$agentId targetId=$targetId targetType=$targetType');
    try {
      final resp = await _api.post(
          'business-app/v1/agents/conversation/history',
          queryParameters: {
            'agentId': agentId,
            'targetId': targetId,
            'targetType': targetType,
          },
          fromData: (d) => List<dynamic>.from(d));
      debugPrint('[AgentRepo] getConversationHistory resp.data=${resp.data}');
      final result = (resp.data ?? []).whereType<Map<String, dynamic>>().toList();
      debugPrint('[AgentRepo] getConversationHistory parsed ${result.length} messages');
      if (result.isNotEmpty) {
        debugPrint('[AgentRepo] first message: ${result.first}');
      }
      return result;
    } on ApiException catch (e) {
      // 74008 = 没有数据，返回空列表
      if (e.bizCode == 74008) return [];
      rethrow;
    }
  }

  /// 清理对话记录
  Future<bool> clearConversationHistory(String agentId) async {
    await _api.post('business-app/v1/agents/conversation/history/clean',
        queryParameters: {'agentId': agentId});
    return true;
  }

  @override
  Future<bool> bindAgentToDevice(
      String agentId, String agentType, String deviceId) async {
    await _api.post('business-app/v1/agents/device/bind-agent', data: {
      'agentId': agentId,
      'agentType': agentType,
      'deviceId': deviceId,
    });
    return true;
  }

  Future<bool> unbindAgentFromDevice(String deviceId) async {
    await _api.post('business-app/v1/agents/device/unbind-agent',
        queryParameters: {'deviceId': deviceId});
    return true;
  }
}
