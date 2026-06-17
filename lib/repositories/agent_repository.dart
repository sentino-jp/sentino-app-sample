import 'dart:typed_data';
import '../models/agent.dart';

/// 智能体数据访问抽象接口
abstract class AgentRepository {
  /// 分页查询当前用户可见的 Sentino 智能体。
  /// 可见范围 = 平台创建（所有用户可见）+ 当前用户在 APP 创建（仅本人可见）。
  /// [status] 启用/禁用筛选；[isRecommend] 是否推荐筛选；[name] 名称模糊查询。
  Future<List<Agent>> queryAgents({
    String? name,
    bool? status,
    bool? isRecommend,
    int? currentPage,
    int? pageSize,
  });

  /// 获取 APP 创建的智能体详情（含 refAgentId / apiKey / greetingMessage）。
  /// 仅本人创建的智能体可获取；平台智能体会失败（用于判定可编辑/删除）。
  Future<Agent> getAgentDetail(String agentId);

  /// 创建 Sentino 智能体 —— 绑定 refAgentId/apiKey；创建后仅本人可见。
  Future<bool> createCustomAgent(Agent agent);

  /// 更新自己创建的 Sentino 智能体；apiKey 为空时不覆盖。
  Future<bool> updateCustomAgent(Agent agent);

  /// 删除自己创建且未关联设备的 Sentino 智能体。
  Future<bool> deleteCustomAgent(String agentId);

  /// 上传智能体头像图片（字节流），返回可访问的文件 URL（失败抛 [ApiException]）。
  /// 复用 business-app/v1/file/uploadFile（与用户头像同端点）。
  /// 用字节流而非文件路径，以兼容 Web（dart:io File 在 Web 不可用）。
  Future<String> uploadAvatar(Uint8List bytes, {required String filename});

  Future<bool> bindAgentToDevice(
      String agentId, String agentType, String deviceId);
}
