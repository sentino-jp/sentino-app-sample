/// 技能注册表，管理所有 SkillDescriptor 的查询、序列化和格式化输出
import 'package:flutter/foundation.dart';
import 'skill_descriptor.dart';
import 'skill_pretty_printer.dart';

class SkillsRegistry {
  final List<SkillDescriptor> _skills;

  SkillsRegistry(List<SkillDescriptor> skills)
      : _skills = List.unmodifiable(skills);

  /// 按 skillId 查询，未找到返回 null
  SkillDescriptor? getById(String skillId) {
    for (final s in _skills) {
      if (s.skillId == skillId) return s;
    }
    return null;
  }

  /// 按能力关键词查询（case-insensitive substring match）
  /// 空或纯空白关键词返回空列表
  List<SkillDescriptor> queryByCapability(String keyword) {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) return [];
    final lower = trimmed.toLowerCase();
    return _skills.where((s) {
      return s.capabilities.any((cap) =>
          cap.name.toLowerCase().contains(lower) ||
          cap.description.toLowerCase().contains(lower));
    }).toList();
  }

  /// 获取所有 Skill
  List<SkillDescriptor> get all => List.unmodifiable(_skills);

  /// JSON 序列化
  Map<String, dynamic> toJson() => {
        'version': '1.0.0',
        'skills': _skills.map((s) => s.toJson()).toList(),
      };

  /// JSON 反序列化
  factory SkillsRegistry.fromJson(Map<String, dynamic> json) {
    final skillsList = (json['skills'] as List<dynamic>)
        .map((e) => SkillDescriptor.fromJson(e as Map<String, dynamic>))
        .toList();
    return SkillsRegistry(skillsList);
  }

  /// Pretty Print
  String prettyPrint() => SkillDescriptorPrettyPrinter.formatRegistry(_skills);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SkillsRegistry &&
          runtimeType == other.runtimeType &&
          listEquals(_skills, other._skills);

  @override
  int get hashCode => Object.hashAll(_skills);
}
