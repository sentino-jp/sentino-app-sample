/// Skills SDK barrel file — 统一导出所有公开类
library skills;

// 核心数据模型
export 'skill_capability.dart';
export 'skill_config.dart';
export 'skill_descriptor.dart';

// 注册表与格式化
export 'skills_registry.dart';
export 'skill_pretty_printer.dart';
export 'default_registry.dart';

// Skill 初始化器
export 'initializers/auth_skill.dart';
export 'initializers/device_skill.dart';
export 'initializers/ble_pairing_skill.dart';
export 'initializers/agent_skill.dart';
export 'initializers/mqtt_skill.dart';
export 'initializers/ota_skill.dart';
