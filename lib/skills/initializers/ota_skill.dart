/// OTA Skill 初始化器，封装 OTA 升级模块的 Repository/Service/Provider 创建逻辑
import '../../providers/ota_provider.dart';
import '../../repositories/ota_repository.dart';
import '../../repositories/api/api_ota_repository.dart';
import '../../repositories/mock/mock_ota_repository.dart';
import '../../services/ota_service.dart';
import '../skill_capability.dart';
import '../skill_config.dart';
import '../skill_descriptor.dart';

/// OTA Skill 初始化结果
class OtaSkillBundle {
  final OtaRepository repository;
  final OtaService service;
  final OtaProvider provider;

  const OtaSkillBundle({
    required this.repository,
    required this.service,
    required this.provider,
  });
}

/// OTA Skill 初始化器
class OtaSkillInitializer {
  static OtaSkillBundle initialize(SkillConfig config) {
    final OtaRepository repo;
    if (config.useMock) {
      repo = MockOtaRepository();
    } else {
      if (config.apiClient == null) {
        throw ArgumentError('OtaSkillInitializer: apiClient is required in API mode');
      }
      repo = ApiOtaRepository(api: config.apiClient!);
    }
    final service = OtaService(repository: repo);
    final provider = OtaProvider(otaService: service);
    return OtaSkillBundle(repository: repo, service: service, provider: provider);
  }

  static SkillDescriptor get descriptor => const SkillDescriptor(
    skillId: 'ota',
    name: 'OTA 升级',
    description: '固件检查、升级进度',
    capabilities: [
      SkillCapability(name: 'checkUpgrade', description: '检查设备固件升级'),
      SkillCapability(name: 'startUpgrade', description: '开始固件升级（含进度）'),
    ],
    dependencies: ['auth', 'device'],
    codePaths: {
      'models': ['lib/models/ota_info.dart'],
      'repositories': [
        'lib/repositories/ota_repository.dart',
        'lib/repositories/api/api_ota_repository.dart',
        'lib/repositories/mock/mock_ota_repository.dart',
      ],
      'services': ['lib/services/ota_service.dart'],
      'providers': ['lib/providers/ota_provider.dart'],
    },
  );
}
