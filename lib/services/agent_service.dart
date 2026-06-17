import 'dart:typed_data';
import '../models/agent.dart';
import '../repositories/agent_repository.dart';

/// 智能体业务逻辑层
class AgentService {
  final AgentRepository _repository;

  AgentService({required AgentRepository repository})
      : _repository = repository;

  /// 分页查询当前用户可见的 Sentino 智能体
  Future<List<Agent>> queryAgents({
    String? name,
    bool? status,
    bool? isRecommend,
    int? currentPage,
    int? pageSize,
  }) =>
      _repository.queryAgents(
        name: name,
        status: status,
        isRecommend: isRecommend,
        currentPage: currentPage,
        pageSize: pageSize,
      );

  /// 获取 APP 创建的智能体详情（仅本人创建的可获取）
  Future<Agent> getAgentDetail(String agentId) =>
      _repository.getAgentDetail(agentId);

  Future<bool> createCustomAgent(Agent agent) =>
      _repository.createCustomAgent(agent);

  Future<bool> updateCustomAgent(Agent agent) =>
      _repository.updateCustomAgent(agent);

  Future<bool> deleteCustomAgent(String agentId) =>
      _repository.deleteCustomAgent(agentId);

  /// 上传智能体头像，返回文件 URL（纯上传，无副作用）
  Future<String> uploadAvatar(Uint8List bytes, {required String filename}) =>
      _repository.uploadAvatar(bytes, filename: filename);

  Future<bool> bindAgentToDevice(
          String agentId, String agentType, String deviceId) =>
      _repository.bindAgentToDevice(agentId, agentType, deviceId);
}
