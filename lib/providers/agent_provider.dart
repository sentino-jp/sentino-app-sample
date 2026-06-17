import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/agent.dart';
import '../services/agent_service.dart';
import '../utils/toast_util.dart';

/// 智能体状态管理 Provider
class AgentProvider extends ChangeNotifier {
  final AgentService _agentService;

  AgentProvider({required AgentService agentService})
      : _agentService = agentService;

  bool _isLoading = false;
  bool _myLoading = false;
  String? _errorMessage;
  // queryPage 返回当前用户可见的全部智能体（平台 + 本人创建）。
  //   _agents          = 全部可见（供设备绑定选择器使用）
  //   _myAgents        = 本人创建（Tab2「我的」），逐个调用 /detail 判定（仅本人创建的会成功）
  //   _recommendAgents = 推荐（Tab1）= 全部 - 我的，不包含本人创建的
  List<Agent> _agents = [];
  List<Agent> _recommendAgents = [];
  List<Agent> _myAgents = [];
  Agent? _selectedAgent;

  bool get isLoading => _isLoading;
  bool get myLoading => _myLoading;
  String? get errorMessage => _errorMessage;
  List<Agent> get agents => _agents;
  List<Agent> get recommendAgents => _recommendAgents;
  List<Agent> get myAgents => _myAgents;
  Agent? get selectedAgent => _selectedAgent;

  /// 加载当前用户可见的全部 Sentino 智能体（单次 queryPage）。
  /// [withMine] 为 true 时，额外通过 /detail 解析「我的」列表（Tab2）。
  Future<void> loadAll({bool withMine = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _agents = await _agentService.queryAgents(pageSize: 100);
      // 探测「我的」之前，先把全部展示在推荐 Tab（探测完成后再剔除本人创建的）
      _recommendAgents = _agents;
      debugPrint('AgentProvider: loaded ${_agents.length} agents');
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _agents = [];
      _recommendAgents = [];
      debugPrint('AgentProvider: loadAll error: $e');
    }

    _isLoading = false;
    notifyListeners();

    if (withMine) await _loadMyAgents();
  }

  /// 单次 /detail 探测的并发上限。一次性全发会把后端打成 500
  /// （单发返回正常的 24002），故分批节流。
  /// TODO: 后端在 queryPage 记录里加 isMine/editable 字段后，可整体移除本探测。
  static const int _detailProbeConcurrency = 4;

  /// 解析「我的智能体」：对每个可见智能体调用 /detail，
  /// 仅本人创建的会成功（平台智能体返回 24002 Permission Denial）。
  /// 分批（每批 [_detailProbeConcurrency] 个）节流，避免瞬时并发打爆后端。
  Future<void> _loadMyAgents() async {
    _myLoading = true;
    notifyListeners();

    final ids = _agents.map((a) => a.agentId).whereType<String>().toList();
    final mineIds = <String>{};
    for (var i = 0; i < ids.length; i += _detailProbeConcurrency) {
      final batch = ids.skip(i).take(_detailProbeConcurrency);
      await Future.wait(batch.map((id) async {
        try {
          await _agentService.getAgentDetail(id);
          mineIds.add(id);
        } catch (_) {
          // 非本人创建 / 获取失败 → 不计入「我的」
        }
      }));
    }
    _myAgents = _agents
        .where((a) => a.agentId != null && mineIds.contains(a.agentId))
        .toList();
    // Tab1「推荐」剔除本人创建的
    _recommendAgents = _agents
        .where((a) => a.agentId == null || !mineIds.contains(a.agentId))
        .toList();
    debugPrint('AgentProvider: myAgents = ${_myAgents.length}/${_agents.length}');

    _myLoading = false;
    notifyListeners();
  }

  /// 获取智能体详情。仅本人创建的智能体可获取；
  /// 返回 null 表示平台智能体（不可编辑/删除）或获取失败。
  Future<Agent?> fetchAgentDetail(String agentId) async {
    try {
      return await _agentService.getAgentDetail(agentId);
    } catch (e) {
      debugPrint('AgentProvider: fetchAgentDetail($agentId) failed: $e');
      return null;
    }
  }

  /// 创建 Sentino 智能体
  Future<bool> createCustomAgent(Agent agent) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ok = await _agentService.createCustomAgent(agent);
      _isLoading = false;
      notifyListeners();
      if (ok) await loadAll(withMine: true);
      return ok;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      ToastUtil.showError(_errorMessage!);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 更新 Sentino 智能体（apiKey 留空则后端不覆盖）
  Future<bool> updateCustomAgent(Agent agent) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ok = await _agentService.updateCustomAgent(agent);
      _isLoading = false;
      notifyListeners();
      if (ok) await loadAll(withMine: true);
      return ok;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      ToastUtil.showError(_errorMessage!);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 删除 Sentino 智能体（已关联设备的会被后端拒绝）
  Future<bool> deleteCustomAgent(String agentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ok = await _agentService.deleteCustomAgent(agentId);
      if (ok) {
        _agents.removeWhere((a) => a.agentId == agentId);
        _myAgents.removeWhere((a) => a.agentId == agentId);
      }
      _isLoading = false;
      notifyListeners();
      return ok;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      ToastUtil.showError(_errorMessage!);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 上传智能体头像，返回文件 URL；失败返回 null（已 toast）。
  /// 注意：与 [AuthProvider.uploadAvatar] 不同，这里不写入用户资料，仅返回 URL 供智能体使用。
  Future<String?> uploadAvatar(Uint8List bytes, {required String filename}) async {
    try {
      return await _agentService.uploadAvatar(bytes, filename: filename);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      ToastUtil.showError(_errorMessage!);
      return null;
    }
  }

  /// 绑定智能体到设备
  Future<bool> bindAgentToDevice(
      String agentId, String agentType, String deviceId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ok =
          await _agentService.bindAgentToDevice(agentId, agentType, deviceId);
      _isLoading = false;
      notifyListeners();
      return ok;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
