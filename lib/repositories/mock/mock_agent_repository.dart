import 'dart:typed_data';
import '../../models/agent.dart';
import '../../utils/api_client.dart';
import '../agent_repository.dart';

/// Mock 智能体 Repository
class MockAgentRepository implements AgentRepository {
  /// 平台创建的智能体（所有用户可见、不可编辑/删除）
  final List<Agent> _platformAgents = const [
    Agent(
      agentId: 'agent_001',
      name: '小智',
      description: '通用智能助手，擅长日常对话和知识问答',
      agentType: 'sentino',
      isRecommend: true,
      status: 1,
      tagList: [AgentTag(tagId: '1', name: '通用'), AgentTag(tagId: '2', name: '问答')],
    ),
    Agent(
      agentId: 'agent_002',
      name: '故事大王',
      description: '专为儿童设计的故事讲述智能体',
      agentType: 'sentino',
      isRecommend: true,
      status: 1,
      tagList: [AgentTag(tagId: '3', name: '儿童'), AgentTag(tagId: '4', name: '故事')],
    ),
  ];

  /// 当前用户在 APP 创建的智能体（仅本人可见、可编辑/删除）
  final List<Agent> _customAgents = [];
  int _customSeq = 0;

  @override
  Future<List<Agent>> queryAgents({
    String? name,
    bool? status,
    bool? isRecommend,
    int? currentPage,
    int? pageSize,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    var all = [..._platformAgents, ..._customAgents];
    if (name != null && name.isNotEmpty) {
      all = all.where((a) => (a.name ?? '').contains(name)).toList();
    }
    if (isRecommend != null) {
      all = all.where((a) => (a.isRecommend ?? false) == isRecommend).toList();
    }
    if (status != null) {
      all = all.where((a) => (a.status == 1) == status).toList();
    }
    return List.unmodifiable(all);
  }

  @override
  Future<Agent> getAgentDetail(String agentId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final mine = _customAgents.where((a) => a.agentId == agentId).toList();
    if (mine.isEmpty) {
      // 平台智能体没有 APP 详情，用于判定「非本人创建、不可编辑」
      throw ApiException(bizCode: 403, message: 'Not your agent');
    }
    return mine.first;
  }

  @override
  Future<bool> createCustomAgent(Agent agent) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _customSeq += 1;
    _customAgents.add(Agent(
      agentId: 'custom_${DateTime.now().millisecondsSinceEpoch}_$_customSeq',
      name: agent.name,
      description: agent.description,
      avatarUrl: agent.avatarUrl,
      agentType: 'sentino',
      isRecommend: true,
      status: 1,
      refAgentId: agent.refAgentId,
      apiKey: agent.apiKey,
      greetingMessage: agent.greetingMessage,
    ));
    return true;
  }

  @override
  Future<bool> updateCustomAgent(Agent agent) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final idx = _customAgents.indexWhere((a) => a.agentId == agent.agentId);
    if (idx < 0) return false;
    final old = _customAgents[idx];
    _customAgents[idx] = Agent(
      agentId: old.agentId,
      name: agent.name ?? old.name,
      description: agent.description ?? old.description,
      avatarUrl: agent.avatarUrl ?? old.avatarUrl,
      agentType: 'sentino',
      isRecommend: old.isRecommend,
      status: old.status,
      refAgentId: agent.refAgentId ?? old.refAgentId,
      greetingMessage: agent.greetingMessage ?? old.greetingMessage,
      apiKey: (agent.apiKey != null && agent.apiKey!.isNotEmpty)
          ? agent.apiKey
          : old.apiKey,
    );
    return true;
  }

  @override
  Future<bool> deleteCustomAgent(String agentId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _customAgents.removeWhere((a) => a.agentId == agentId);
    return true;
  }

  @override
  Future<String> uploadAvatar(Uint8List bytes, {required String filename}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return 'https://example.com/avatar/mock.jpg';
  }

  @override
  Future<bool> bindAgentToDevice(
      String agentId, String agentType, String deviceId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }
}
