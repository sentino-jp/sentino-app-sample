import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../models/agent.dart';
import '../../utils/api_client.dart';
import '../agent_repository.dart';

/// Real API agent repository —— Sentino 智能体（business-app/v1/sentino-ai/agents/*）
class ApiAgentRepository implements AgentRepository {
  final ApiClient _api;

  ApiAgentRepository({required ApiClient api}) : _api = api;

  // ============================================================
  // Sentino 智能体 —— business-app/v1/sentino-ai/agents/*
  // ============================================================

  @override
  Future<List<Agent>> queryAgents({
    String? name,
    bool? status,
    bool? isRecommend,
    int? currentPage,
    int? pageSize,
  }) async {
    final queryCondition = <String, dynamic>{
      if (name != null && name.isNotEmpty) 'name': name,
      if (status != null) 'status': status,
      if (isRecommend != null) 'isRecommend': isRecommend,
    };
    final resp = await _api.post(
      'business-app/v1/sentino-ai/agents/queryPage',
      data: {
        'currentPage': currentPage ?? 1,
        'pageSize': pageSize ?? 100,
        if (queryCondition.isNotEmpty) 'queryCondition': queryCondition,
      },
      fromData: (d) => d is Map<String, dynamic> ? d : null,
    );
    final records = resp.data?['records'];
    if (records is! List) {
      debugPrint('[AgentRepo] queryAgents: no records, data=${resp.data}');
      return [];
    }
    final agents = records.whereType<Map<String, dynamic>>().map((e) {
      // queryPage 返回的都是 Sentino 智能体；绑定按 'sentino' 处理（与历史一致）
      if (e['agentType'] == null || (e['agentType'] as String?)?.isEmpty == true) {
        e['agentType'] = 'sentino';
      }
      return Agent.fromJson(e);
    }).toList();
    debugPrint('[AgentRepo] queryAgents: parsed ${agents.length} agents');
    return agents;
  }

  @override
  Future<Agent> getAgentDetail(String agentId) async {
    final resp = await _api.post(
      'business-app/v1/sentino-ai/agents/detail',
      queryParameters: {'agentId': agentId},
      fromData: (d) => Agent.fromJson(d as Map<String, dynamic>),
    );
    return resp.data!;
  }

  @override
  Future<bool> createCustomAgent(Agent agent) async {
    await _api.post('business-app/v1/sentino-ai/agents/create', data: {
      'name': agent.name ?? '',
      'description': agent.description ?? '',
      'refAgentId': agent.refAgentId ?? '',
      'apiKey': agent.apiKey ?? '',
      'agentType': agent.agentType ?? 'sentino',
      if (agent.avatarUrl != null) 'avatarUrl': agent.avatarUrl,
      if (agent.greetingMessage != null) 'greetingMessage': agent.greetingMessage,
    });
    return true;
  }

  @override
  Future<bool> updateCustomAgent(Agent agent) async {
    final data = <String, dynamic>{
      'agentId': agent.agentId,
      'name': agent.name ?? '',
      'description': agent.description ?? '',
      if (agent.refAgentId != null) 'refAgentId': agent.refAgentId,
      if (agent.avatarUrl != null) 'avatarUrl': agent.avatarUrl,
      if (agent.greetingMessage != null) 'greetingMessage': agent.greetingMessage,
      // apiKey 为空时不覆盖，约定由后端识别
      if (agent.apiKey != null && agent.apiKey!.isNotEmpty) 'apiKey': agent.apiKey,
    };
    await _api.post('business-app/v1/sentino-ai/agents/update', data: data);
    return true;
  }

  @override
  Future<bool> deleteCustomAgent(String agentId) async {
    await _api.post('business-app/v1/sentino-ai/agents/deleteById',
        queryParameters: {'agentId': agentId});
    return true;
  }

  @override
  Future<String> uploadAvatar(Uint8List bytes, {required String filename}) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final response = await _api.dio.post(
      'business-app/v1/file/uploadFile',
      data: formData,
    );
    final data = response.data as Map<String, dynamic>;
    final code = data['code'] as int? ?? -1;
    if (code != 200) {
      throw ApiException(
        bizCode: code,
        message: data['message']?.toString() ?? 'Failed to upload avatar',
      );
    }
    return data['data']?.toString() ?? '';
  }

  // ============================================================
  // 以下为既有接口（不在本次新增范围内，保持不变）
  // ============================================================

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
