import 'dart:math';
import 'package:test/test.dart';
import 'package:sentino/skills/skill_capability.dart';
import 'package:sentino/skills/skill_descriptor.dart';
import 'package:sentino/skills/skill_pretty_printer.dart';

// ---------------------------------------------------------------------------
// Random generators for property-based testing
// ---------------------------------------------------------------------------

final _random = Random(42);

String _randomString(int minLen, int maxLen) {
  final length = minLen + _random.nextInt(maxLen - minLen + 1);
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789_';
  return String.fromCharCodes(
    Iterable.generate(length, (_) => chars.codeUnitAt(_random.nextInt(chars.length))),
  );
}

/// Generate a random forward-slash relative path (e.g. "lib/models/foo.dart")
String _randomRelativePath() {
  final segments = 1 + _random.nextInt(3);
  final parts = List.generate(segments, (_) => _randomString(2, 8));
  parts.add('${_randomString(3, 10)}.dart');
  return parts.join('/');
}

SkillCapability _randomCapability() => SkillCapability(
      name: _randomString(3, 12),
      description: _randomString(5, 30),
    );

SkillDescriptor _randomDescriptor() {
  final capCount = _random.nextInt(5); // 0-4 capabilities
  final depCount = _random.nextInt(3); // 0-2 dependencies
  final requiredKeys = ['models', 'repositories', 'services', 'providers'];
  final codePaths = <String, List<String>>{};
  for (final key in requiredKeys) {
    final pathCount = 1 + _random.nextInt(3);
    codePaths[key] = List.generate(pathCount, (_) => _randomRelativePath());
  }
  return SkillDescriptor(
    skillId: _randomString(3, 10),
    name: _randomString(3, 15),
    description: _randomString(10, 40),
    capabilities: List.generate(capCount, (_) => _randomCapability()),
    dependencies: List.generate(depCount, (_) => _randomString(3, 10)),
    codePaths: codePaths,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // **Feature: skills-sdk, Property 2: Skill Descriptor JSON round-trip**
  // **Validates: Requirements 6.1**
  test('Property 2: Skill Descriptor JSON round-trip (100 iterations)', () {
    for (var i = 0; i < 100; i++) {
      final original = _randomDescriptor();
      final json = original.toJson();
      final restored = SkillDescriptor.fromJson(json);
      expect(restored, equals(original),
          reason: 'Round-trip failed at iteration $i for skillId=${original.skillId}');
    }
  });

  // **Feature: skills-sdk, Property 6: Descriptor completeness**
  // **Validates: Requirements 2.1**
  test('Property 6: Descriptor completeness (100 iterations)', () {
    for (var i = 0; i < 100; i++) {
      final descriptor = _randomDescriptor();
      expect(descriptor.skillId.isNotEmpty, isTrue,
          reason: 'skillId must be non-empty at iteration $i');
      expect(descriptor.name.isNotEmpty, isTrue,
          reason: 'name must be non-empty at iteration $i');
      expect(descriptor.description.isNotEmpty, isTrue,
          reason: 'description must be non-empty at iteration $i');
      expect(descriptor.codePaths.isNotEmpty, isTrue,
          reason: 'codePaths must have at least one entry at iteration $i');
    }
  });

  // **Feature: skills-sdk, Property 9: CodePaths validity**
  // **Validates: Requirements 5.1, 5.2**
  test('Property 9: CodePaths validity (100 iterations)', () {
    for (var i = 0; i < 100; i++) {
      final descriptor = _randomDescriptor();

      // Must contain required keys
      for (final key in ['models', 'repositories', 'services', 'providers']) {
        expect(descriptor.codePaths.containsKey(key), isTrue,
            reason: 'codePaths missing key "$key" at iteration $i');
      }

      // Each path must use forward slashes, be relative (no absolute prefix)
      for (final entry in descriptor.codePaths.entries) {
        for (final path in entry.value) {
          expect(path.contains('\\'), isFalse,
              reason: 'Path "$path" contains backslash at iteration $i');
          expect(path.startsWith('/'), isFalse,
              reason: 'Path "$path" starts with / at iteration $i');
          // No Windows absolute path prefix like C:\ or D:\
          expect(RegExp(r'^[A-Za-z]:\\').hasMatch(path), isFalse,
              reason: 'Path "$path" has absolute Windows prefix at iteration $i');
        }
      }
    }
  });

  // **Feature: skills-sdk, Property 8: Descriptor pretty print completeness**
  // **Validates: Requirements 6.2, 6.3**
  test('Property 8: Descriptor pretty print completeness (100 iterations)', () {
    for (var i = 0; i < 100; i++) {
      final descriptor = _randomDescriptor();
      final output = SkillDescriptorPrettyPrinter.format(descriptor);

      // Output must contain name and description regardless of capabilities
      expect(output.contains(descriptor.name), isTrue,
          reason: 'Output missing name "${descriptor.name}" at iteration $i');
      expect(output.contains(descriptor.description), isTrue,
          reason: 'Output missing description at iteration $i');

      // Each capability name must appear
      for (final cap in descriptor.capabilities) {
        expect(output.contains(cap.name), isTrue,
            reason: 'Output missing capability name "${cap.name}" at iteration $i');
      }

      // Each dependency skillId must appear
      for (final dep in descriptor.dependencies) {
        expect(output.contains(dep), isTrue,
            reason: 'Output missing dependency "$dep" at iteration $i');
      }

      // Each codePath value must appear
      for (final paths in descriptor.codePaths.values) {
        for (final path in paths) {
          expect(output.contains(path), isTrue,
              reason: 'Output missing codePath "$path" at iteration $i');
        }
      }
    }
  });
}
