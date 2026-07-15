import 'package:flutter/foundation.dart';
import 'skill_capability.dart';

/// 描述单个 Skill 的元信息，包含 ID、名称、能力列表、依赖和代码路径
class SkillDescriptor {
  final String skillId;
  final String name;
  final String description;
  final List<SkillCapability> capabilities;
  final List<String> dependencies;
  final Map<String, List<String>> codePaths;

  const SkillDescriptor({
    required this.skillId,
    required this.name,
    required this.description,
    required this.capabilities,
    this.dependencies = const [],
    required this.codePaths,
  });

  factory SkillDescriptor.fromJson(Map<String, dynamic> json) {
    return SkillDescriptor(
      skillId: json['skillId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      capabilities: (json['capabilities'] as List<dynamic>)
          .map((e) => SkillCapability.fromJson(e as Map<String, dynamic>))
          .toList(),
      dependencies: (json['dependencies'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      codePaths: (json['codePaths'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          key,
          (value as List<dynamic>).map((e) => e as String).toList(),
        ),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'skillId': skillId,
        'name': name,
        'description': description,
        'capabilities': capabilities.map((c) => c.toJson()).toList(),
        'dependencies': dependencies,
        'codePaths': codePaths,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SkillDescriptor &&
          runtimeType == other.runtimeType &&
          skillId == other.skillId &&
          name == other.name &&
          description == other.description &&
          listEquals(capabilities, other.capabilities) &&
          listEquals(dependencies, other.dependencies) &&
          _codePathsEqual(codePaths, other.codePaths);

  @override
  int get hashCode =>
      skillId.hashCode ^
      name.hashCode ^
      description.hashCode ^
      Object.hashAll(capabilities) ^
      Object.hashAll(dependencies);

  static bool _codePathsEqual(
    Map<String, List<String>> a,
    Map<String, List<String>> b,
  ) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || !listEquals(a[key], b[key])) return false;
    }
    return true;
  }

  @override
  String toString() => 'SkillDescriptor(skillId: $skillId, name: $name)';
}
