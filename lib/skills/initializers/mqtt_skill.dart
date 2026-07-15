/// MQTT Skill 初始化器，MqttService 为独立服务，仅提供 descriptor
import '../skill_capability.dart';
import '../skill_descriptor.dart';

/// MQTT Skill 初始化器（MqttService 是独立服务，无需 initialize）
class MqttSkillInitializer {
  static SkillDescriptor get descriptor => const SkillDescriptor(
    skillId: 'mqtt',
    name: 'MQTT 消息',
    description: 'MQTT 连接、订阅、消息分发',
    capabilities: [
      SkillCapability(name: 'connect', description: '连接 MQTT 服务器'),
      SkillCapability(name: 'subscribeAsset', description: '订阅资产消息通知'),
      SkillCapability(name: 'subscribeUser', description: '订阅用户消息通知'),
      SkillCapability(name: 'disconnect', description: '断开 MQTT 连接'),
    ],
    dependencies: ['auth'],
    codePaths: {
      'models': <String>[],
      'repositories': <String>[],
      'services': ['lib/services/mqtt_service.dart'],
      'providers': <String>[],
    },
  );
}
