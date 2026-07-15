import 'dart:math';
import 'package:test/test.dart';
import 'package:sentino/skills/skill_capability.dart';
import 'package:sentino/skills/skill_descriptor.dart';
import 'package:sentino/skills/skills_registry.dart';

// ---------------------------------------------------------------------------
// Random generators for property-based testing
// ---------------------------------------------------------------------------

final _random = Random(42);

String _randomString(int minLen, int maxLen) {
  final length = minLen + _random.nextInt(maxLen - minLen + 1);
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789_';
  return String.fromCharCodes(
    Iterable.generate(
        length, (_) => chars.codeUnitAt(_random.nextInt(chars.length))),
  );
}

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
  final capCount = 1 + _random.nextInt(4); // 1-4 capabilities
  final depCount = _random.nextInt(3);
  final codePaths = <String, List<String>>{};
  for (final key in ['models', 'repositories', 'services', 'providers']) {
    codePaths[key] = List.generate(
        1 + _random.nextInt(3), (_) => _randomRelativePath());
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

SkillsRegistry _randomRegistry({int? count}) {
  final n = count ?? (1 + _random.nextInt(6));
  return SkillsRegistry(List.generate(n, (_) => _randomDescriptor()));
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // **Feature: skills-sdk, Property 1: Skills Registry JSON round-trip**
  // **Validates: Requirements 2.4**
  test('Property 1: Skills Registry JSON round-trip (100 iterations)', () {
    for (var i = 0; i < 100; i++) {
      final original = _randomRegistry();
      final json = original.toJson();
      final restored = SkillsRegistry.fromJson(json);
      expect(restored, equals(original),
          reason: 'Round-trip failed at iteration $i');
    }
  });

  // **Feature: skills-sdk, Property 3: Registry is additive**
  // **Validates: Requirements 2.2**
  test('Property 3: Registry is additive (100 iterations)', () {
    for (var i = 0; i < 100; i++) {
      final original = _randomRegistry();
      final newDescriptor = _randomDescriptor();
      final extended = SkillsRegistry([...original.all, newDescriptor]);

      // All original descriptors must be preserved
      for (final desc in original.all) {
        expect(extended.all.contains(desc), isTrue,
            reason:
                'Original descriptor ${desc.skillId} missing at iteration $i');
      }
      // New descriptor must be present
      expect(extended.all.contains(newDescriptor), isTrue,
          reason: 'New descriptor missing at iteration $i');
      // Length must grow by exactly 1
      expect(extended.all.length, equals(original.all.length + 1),
          reason: 'Length mismatch at iteration $i');
    }
  });

  // **Feature: skills-sdk, Property 4: Query by skillId correctness**
  // **Validates: Requirements 2.3**
  test('Property 4: Query by skillId correctness (100 iterations)', () {
    for (var i = 0; i < 100; i++) {
      final registry = _randomRegistry();

      // Every descriptor in the registry should be found by its skillId
      for (final desc in registry.all) {
        final result = registry.getById(desc.skillId);
        expect(result, equals(desc),
            reason:
                'getById failed for skillId=${desc.skillId} at iteration $i');
      }

      // A random non-existent skillId should return null
      final missingId = '___nonexistent_${_randomString(5, 10)}';
      expect(registry.getById(missingId), isNull,
          reason: 'getById should return null for missing id at iteration $i');
    }
  });

  // **Feature: skills-sdk, Property 5: Query by capability keyword correctness**
  // **Validates: Requirements 3.1, 3.3**
  test('Property 5: Query by capability keyword correctness (100 iterations)',
      () {
    for (var i = 0; i < 100; i++) {
      final registry = _randomRegistry();
      final allSkills = registry.all;

      // Pick a random capability name from a random skill as keyword
      final skillWithCaps =
          allSkills.where((s) => s.capabilities.isNotEmpty).toList();
      if (skillWithCaps.isNotEmpty) {
        final pick = skillWithCaps[_random.nextInt(skillWithCaps.length)];
        final cap = pick.capabilities[_random.nextInt(pick.capabilities.length)];
        final keyword = cap.name;
        final lowerKeyword = keyword.toLowerCase();

        final results = registry.queryByCapability(keyword);

        // Soundness: every returned result must have a matching capability
        for (final r in results) {
          final matches = r.capabilities.any((c) =>
              c.name.toLowerCase().contains(lowerKeyword) ||
              c.description.toLowerCase().contains(lowerKeyword));
          expect(matches, isTrue,
              reason:
                  'Result ${r.skillId} does not match keyword "$keyword" at iteration $i');
        }

        // Completeness: every skill that should match must be in results
        for (final s in allSkills) {
          final shouldMatch = s.capabilities.any((c) =>
              c.name.toLowerCase().contains(lowerKeyword) ||
              c.description.toLowerCase().contains(lowerKeyword));
          if (shouldMatch) {
            expect(results.any((r) => r.skillId == s.skillId), isTrue,
                reason:
                    'Skill ${s.skillId} should match keyword "$keyword" but was not returned at iteration $i');
          }
        }

        // The picked skill must be in the results
        expect(results.any((r) => r.skillId == pick.skillId), isTrue,
            reason:
                'Source skill ${pick.skillId} missing from results at iteration $i');
      }

      // Empty / whitespace keyword must return empty list (Req 3.3)
      expect(registry.queryByCapability(''), isEmpty,
          reason: 'Empty keyword should return empty list at iteration $i');
      expect(registry.queryByCapability('   '), isEmpty,
          reason:
              'Whitespace keyword should return empty list at iteration $i');
    }
  });

  // **Feature: skills-sdk, Property 7: Registry pretty print completeness**
  // **Validates: Requirements 2.5**
  test('Property 7: Registry pretty print completeness (100 iterations)', () {
    for (var i = 0; i < 100; i++) {
      final registry = _randomRegistry();
      final output = registry.prettyPrint();

      for (final desc in registry.all) {
        expect(output.contains(desc.name), isTrue,
            reason:
                'Output missing skill name "${desc.name}" at iteration $i');
        expect(output.contains(desc.description), isTrue,
            reason: 'Output missing description at iteration $i');
        for (final cap in desc.capabilities) {
          expect(output.contains(cap.name), isTrue,
              reason:
                  'Output missing capability "${cap.name}" at iteration $i');
        }
      }
    }
  });
}
