import '../models/agent.dart';
import '../repositories/agent_repository.dart';

/// 智能体业务逻辑层
class AgentService {
  final AgentRepository _repository;

  AgentService({required AgentRepository repository})
      : _repository = repository;

  Future<List<Agent>> getRecommendAgents() => _repository.getRecommendAgents();

  Future<List<Agent>> getCustomAgents() => _repository.getCustomAgents();

  Future<bool> createCustomAgent(Agent agent) =>
      _repository.createCustomAgent(agent);

  Future<bool> updateCustomAgent(Agent agent) =>
      _repository.updateCustomAgent(agent);

  Future<bool> deleteCustomAgent(String agentId) =>
      _repository.deleteCustomAgent(agentId);

  Future<bool> bindAgentToDevice(
          String agentId, String agentType, String deviceId) =>
      _repository.bindAgentToDevice(agentId, agentType, deviceId);
}
