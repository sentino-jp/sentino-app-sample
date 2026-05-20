import '../models/agent.dart';
import '../repositories/agent_repository.dart';

/// 智能体业务逻辑层
class AgentService {
  final AgentRepository _repository;

  AgentService({required AgentRepository repository})
      : _repository = repository;

  Future<List<Agent>> getRecommendAgents() => _repository.getRecommendAgents();

  Future<bool> bindAgentToDevice(
          String agentId, String agentType, String deviceId) =>
      _repository.bindAgentToDevice(agentId, agentType, deviceId);
}
