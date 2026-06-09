import '../../models/agent.dart';
import '../agent_repository.dart';

/// Mock 智能体 Repository
class MockAgentRepository implements AgentRepository {
  final List<Agent> _recommendAgents = const [
    Agent(
      agentId: 'agent_001',
      name: '小智',
      description: '通用智能助手，擅长日常对话和知识问答',
      tagList: [AgentTag(tagId: '1', name: '通用'), AgentTag(tagId: '2', name: '问答')],
    ),
    Agent(
      agentId: 'agent_002',
      name: '故事大王',
      description: '专为儿童设计的故事讲述智能体',
      tagList: [AgentTag(tagId: '3', name: '儿童'), AgentTag(tagId: '4', name: '故事')],
    ),
  ];

  final List<Agent> _customAgents = [];
  int _customSeq = 0;

  @override
  Future<List<Agent>> getRecommendAgents() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_recommendAgents);
  }

  @override
  Future<List<Agent>> getCustomAgents() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.unmodifiable(_customAgents);
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
      agentType: 'customize',
      sentinoAgentId: agent.sentinoAgentId,
      sentinoApiKey: agent.sentinoApiKey,
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
      agentType: 'customize',
      sentinoAgentId: agent.sentinoAgentId ?? old.sentinoAgentId,
      sentinoApiKey: (agent.sentinoApiKey != null && agent.sentinoApiKey!.isNotEmpty)
          ? agent.sentinoApiKey
          : old.sentinoApiKey,
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
  Future<bool> bindAgentToDevice(
      String agentId, String agentType, String deviceId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }
}
