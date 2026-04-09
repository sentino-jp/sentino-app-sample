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

  @override
  Future<List<Agent>> getCustomAgents() async {
    final resp = await _api.post(
        'business-app/v1/agents/customize/agents-list',
        fromData: (d) => List<dynamic>.from(d));
    return (resp.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map((e) {
          if (e['agentType'] == null || (e['agentType'] as String).isEmpty) {
            e['agentType'] = 'customize';
          }
          return Agent.fromJson(e);
        })
        .toList();
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
  }

  @override
  Future<bool> createCustomAgent(Agent agent) async {
    await _api.post('business-app/v1/agents/customize/create', data: {
      'name': agent.name ?? '',
      'description': agent.description ?? '',
      'avatarUrl': agent.avatarUrl ?? '',
      'langId': agent.languageId ?? '',
      'llmModelId': agent.modelId ?? '',
      'ttsVoiceId': agent.voiceId ?? '',
    });
    return true;
  }

  @override
  Future<bool> deleteCustomAgent(String agentId) async {
    await _api.post('business-app/v1/agents/customize/deleteById',
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

  Future<List<Map<String, dynamic>>> getLanguageList() async {
    final resp = await _api.post(
        'business-app/v1/agents/customize/language-list',
        fromData: (d) => List<dynamic>.from(d));
    return (resp.data ?? []).whereType<Map<String, dynamic>>().toList();
  }

  Future<List<Map<String, dynamic>>> getVoiceList() async {
    final resp = await _api.post(
        'business-app/v1/agents/customize/voice-list',
        fromData: (d) => List<dynamic>.from(d));
    return (resp.data ?? []).whereType<Map<String, dynamic>>().toList();
  }

  Future<List<Map<String, dynamic>>> getLlmList() async {
    final resp = await _api.post(
        'business-app/v1/agents/customize/llm-list',
        fromData: (d) => List<dynamic>.from(d));
    return (resp.data ?? []).whereType<Map<String, dynamic>>().toList();
  }

  Future<String> refinementText(String content, {String? language}) async {
    final data = <String, dynamic>{'content': content};
    if (language != null) data['language'] = language;
    final resp = await _api.post<String>(
        'business-app/v1/agents/customize/refinement-text', data: data);
    return resp.data?.toString() ?? content;
  }

  Future<bool> updateCustomAgent(Map<String, dynamic> data) async {
    await _api.post('business-app/v1/agents/customize/update', data: data);
    return true;
  }
}
