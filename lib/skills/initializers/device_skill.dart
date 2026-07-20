/// Device Skill 初始化器，封装设备管理模块的 Repository/Service/Provider 创建逻辑
import '../../providers/device_provider.dart';
import '../../repositories/device_repository.dart';
import '../../repositories/api/api_device_repository.dart';
import '../../repositories/mock/mock_device_repository.dart';
import '../../services/device_service.dart';
import '../skill_capability.dart';
import '../skill_config.dart';
import '../skill_descriptor.dart';

/// Device Skill 初始化结果
class DeviceSkillBundle {
  final DeviceRepository repository;
  final DeviceService service;
  final DeviceProvider provider;

  const DeviceSkillBundle({
    required this.repository,
    required this.service,
    required this.provider,
  });
}

/// Device Skill 初始化器
class DeviceSkillInitializer {
  static DeviceSkillBundle initialize(SkillConfig config) {
    final DeviceRepository repo;
    if (config.useMock) {
      repo = MockDeviceRepository();
    } else {
      if (config.apiClient == null) {
        throw ArgumentError('DeviceSkillInitializer: apiClient is required in API mode');
      }
      repo = ApiDeviceRepository(api: config.apiClient!);
    }
    final service = DeviceService(repository: repo);
    final provider = DeviceProvider(deviceService: service, coucouApi: config.coucouApi!);
    return DeviceSkillBundle(repository: repo, service: service, provider: provider);
  }

  static SkillDescriptor get descriptor => const SkillDescriptor(
    skillId: 'device',
    name: '设备管理',
    description: '设备列表、绑定/解绑、重命名、属性下发、信号检测',
    capabilities: [
      SkillCapability(name: 'getAssetTree', description: '获取资产树'),
      SkillCapability(name: 'getDeviceList', description: '获取设备列表'),
      SkillCapability(name: 'bindDevice', description: '绑定设备（UUID/条形码/4G）'),
      SkillCapability(name: 'unbindDevice', description: '解绑设备'),
      SkillCapability(name: 'renameDevice', description: '重命名设备'),
      SkillCapability(name: 'checkSignal', description: '网络检测（信号强度检查）'),
      SkillCapability(name: 'getDpInfos', description: '获取设备物模型 DP 点信息'),
    ],
    dependencies: ['auth'],
    codePaths: {
      'models': ['lib/models/device.dart', 'lib/models/asset.dart'],
      'repositories': [
        'lib/repositories/device_repository.dart',
        'lib/repositories/api/api_device_repository.dart',
        'lib/repositories/mock/mock_device_repository.dart',
      ],
      'services': ['lib/services/device_service.dart'],
      'providers': ['lib/providers/device_provider.dart'],
    },
  );
}
