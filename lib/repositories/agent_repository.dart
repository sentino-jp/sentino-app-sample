import '../models/agent.dart';

/// 智能体数据访问抽象接口
abstract class AgentRepository {
  Future<List<Agent>> getRecommendAgents();

  /// 用户自定义（绑定 Sentino agent 凭证）的 agent 列表
  Future<List<Agent>> getCustomAgents();

  /// 创建一个自定义 agent —— 绑定用户在 Sentino 平台申请到的 agentId/apiKey
  Future<bool> createCustomAgent(Agent agent);

  /// 更新自定义 agent；apiKey 为空时不覆盖
  Future<bool> updateCustomAgent(Agent agent);

  Future<bool> deleteCustomAgent(String agentId);

  Future<bool> bindAgentToDevice(
      String agentId, String agentType, String deviceId);
}
