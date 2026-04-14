/// Agent Skill 初始化器，封装智能体模块的 Repository/Service/Provider 创建逻辑
import '../../providers/agent_provider.dart';
import '../../repositories/agent_repository.dart';
import '../../repositories/api/api_agent_repository.dart';
import '../../repositories/mock/mock_agent_repository.dart';
import '../../services/agent_service.dart';
import '../skill_capability.dart';
import '../skill_config.dart';
import '../skill_descriptor.dart';

/// Agent Skill 初始化结果
class AgentSkillBundle {
  final AgentRepository repository;
  final AgentService service;
  final AgentProvider provider;

  const AgentSkillBundle({
    required this.repository,
    required this.service,
    required this.provider,
  });
}

/// Agent Skill 初始化器
class AgentSkillInitializer {
  static AgentSkillBundle initialize(SkillConfig config) {
    final AgentRepository repo;
    if (config.useMock) {
      repo = MockAgentRepository();
    } else {
      if (config.apiClient == null) {
        throw ArgumentError('AgentSkillInitializer: apiClient is required in API mode');
      }
      repo = ApiAgentRepository(api: config.apiClient!);
    }
    final service = AgentService(repository: repo);
    final provider = AgentProvider(agentService: service);
    return AgentSkillBundle(repository: repo, service: service, provider: provider);
  }

  static SkillDescriptor get descriptor => const SkillDescriptor(
    skillId: 'agent',
    name: '智能体',
    description: '推荐/自定义智能体、创建/删除、绑定到设备',
    capabilities: [
      SkillCapability(name: 'getRecommendAgents', description: '获取推荐智能体列表'),
      SkillCapability(name: 'getCustomAgents', description: '获取自定义智能体列表'),
      SkillCapability(name: 'createCustomAgent', description: '创建自定义智能体'),
      SkillCapability(name: 'deleteCustomAgent', description: '删除自定义智能体'),
      SkillCapability(name: 'bindAgentToDevice', description: '绑定智能体到设备'),
    ],
    dependencies: ['auth'],
    codePaths: {
      'models': ['lib/models/agent.dart'],
      'repositories': [
        'lib/repositories/agent_repository.dart',
        'lib/repositories/api/api_agent_repository.dart',
        'lib/repositories/mock/mock_agent_repository.dart',
      ],
      'services': ['lib/services/agent_service.dart'],
      'providers': ['lib/providers/agent_provider.dart'],
    },
  );
}
