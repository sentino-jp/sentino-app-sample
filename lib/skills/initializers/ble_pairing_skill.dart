/// BLE Pairing Skill 初始化器，BleService 为单例模式，仅提供 descriptor
import '../skill_capability.dart';
import '../skill_descriptor.dart';

/// BLE Pairing Skill 初始化器（BleService 是单例，无需 initialize）
class BlePairingSkillInitializer {
  static SkillDescriptor get descriptor => const SkillDescriptor(
    skillId: 'ble_pairing',
    name: 'BLE 配网',
    description: '蓝牙扫描、连接、配网数据发送、WiFi 列表获取',
    capabilities: [
      SkillCapability(name: 'startScan', description: '扫描附近 BLE 设备'),
      SkillCapability(name: 'connectDevice', description: '连接 BLE 设备'),
      SkillCapability(name: 'sendPairingData', description: '发送配网数据到设备'),
      SkillCapability(name: 'requestDeviceWifiList', description: '获取设备周围 WiFi 列表'),
    ],
    dependencies: ['device'],
    codePaths: {
      'models': <String>[],
      'repositories': <String>[],
      'services': ['lib/services/ble_service.dart'],
      'providers': <String>[],
    },
  );
}
