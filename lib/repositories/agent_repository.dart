import '../models/agent.dart';

/// 智能体数据访问抽象接口
abstract class AgentRepository {
  Future<List<Agent>> getRecommendAgents();

  Future<bool> bindAgentToDevice(
      String agentId, String agentType, String deviceId);
}
