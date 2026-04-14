/// 将 SkillDescriptor / SkillsRegistry 格式化为人类可读文本
import 'skill_descriptor.dart';

class SkillDescriptorPrettyPrinter {
  /// 格式化单个 SkillDescriptor 为可读文本
  static String format(SkillDescriptor descriptor) {
    final buf = StringBuffer();
    buf.writeln('Skill: ${descriptor.name}');
    buf.writeln('  ID: ${descriptor.skillId}');
    buf.writeln('  Description: ${descriptor.description}');

    if (descriptor.capabilities.isNotEmpty) {
      buf.writeln('  Capabilities:');
      for (final cap in descriptor.capabilities) {
        buf.writeln('    - ${cap.name}: ${cap.description}');
      }
    }

    if (descriptor.dependencies.isNotEmpty) {
      buf.writeln('  Dependencies:');
      for (final dep in descriptor.dependencies) {
        buf.writeln('    - $dep');
      }
    }

    if (descriptor.codePaths.isNotEmpty) {
      buf.writeln('  Code Paths:');
      for (final entry in descriptor.codePaths.entries) {
        buf.writeln('    ${entry.key}:');
        for (final path in entry.value) {
          buf.writeln('      - $path');
        }
      }
    }

    return buf.toString();
  }

  /// 格式化整个 registry（SkillDescriptor 列表）为可读文本
  static String formatRegistry(List<SkillDescriptor> skills) {
    if (skills.isEmpty) return 'Skills Registry: (empty)\n';
    final buf = StringBuffer();
    buf.writeln('Skills Registry (${skills.length} skills):');
    buf.writeln('${'=' * 40}');
    for (var i = 0; i < skills.length; i++) {
      if (i > 0) buf.writeln('${'─' * 40}');
      buf.write(format(skills[i]));
    }
    return buf.toString();
  }
}
