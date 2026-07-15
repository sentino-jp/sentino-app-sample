/// 默认 SkillsRegistry，包含所有 6 个 Skill 的 Descriptor
import 'initializers/agent_skill.dart';
import 'initializers/auth_skill.dart';
import 'initializers/ble_pairing_skill.dart';
import 'initializers/device_skill.dart';
import 'initializers/mqtt_skill.dart';
import 'initializers/ota_skill.dart';
import 'skills_registry.dart';

/// 构建包含所有内置 Skill 的默认注册表
SkillsRegistry buildDefaultRegistry() {
  return SkillsRegistry([
    AuthSkillInitializer.descriptor,
    DeviceSkillInitializer.descriptor,
    BlePairingSkillInitializer.descriptor,
    AgentSkillInitializer.descriptor,
    MqttSkillInitializer.descriptor,
    OtaSkillInitializer.descriptor,
  ]);
}
