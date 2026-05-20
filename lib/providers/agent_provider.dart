import 'package:flutter/material.dart';
import '../models/agent.dart';
import '../services/agent_service.dart';

/// 智能体状态管理 Provider
class AgentProvider extends ChangeNotifier {
  final AgentService _agentService;

  AgentProvider({required AgentService agentService})
      : _agentService = agentService;

  bool _isLoading = false;
  String? _errorMessage;
  List<Agent> _recommendAgents = [];
  Agent? _selectedAgent;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Agent> get recommendAgents => _recommendAgents;
  Agent? get selectedAgent => _selectedAgent;

  /// 加载推荐智能体列表
  Future<void> loadRecommendAgents() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _recommendAgents = await _agentService.getRecommendAgents();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 加载全部智能体
  Future<void> loadAll() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _recommendAgents = await _agentService.getRecommendAgents();
      debugPrint('AgentProvider: recommend loaded: ${_recommendAgents.length}');
      for (final a in _recommendAgents) {
        debugPrint('  recommend agent: ${a.agentId} ${a.displayName}');
      }
    } catch (e) {
      debugPrint('AgentProvider: loadRecommend error: $e');
      _recommendAgents = [];
    }

    _isLoading = false;
    notifyListeners();
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
