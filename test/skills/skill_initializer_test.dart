import 'package:test/test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sentino/utils/storage.dart';
import 'package:sentino/utils/api_client.dart';
import 'package:sentino/skills/skill_config.dart';
import 'package:sentino/skills/initializers/auth_skill.dart';
import 'package:sentino/skills/initializers/device_skill.dart';
import 'package:sentino/skills/initializers/ble_pairing_skill.dart';
import 'package:sentino/skills/initializers/agent_skill.dart';
import 'package:sentino/skills/initializers/mqtt_skill.dart';
import 'package:sentino/skills/initializers/ota_skill.dart';
import 'package:sentino/repositories/mock/mock_auth_repository.dart';
import 'package:sentino/repositories/mock/mock_device_repository.dart';
import 'package:sentino/repositories/mock/mock_agent_repository.dart';
import 'package:sentino/repositories/mock/mock_ota_repository.dart';
import 'package:sentino/repositories/api/api_auth_repository.dart';
import 'package:sentino/repositories/api/api_device_repository.dart';
import 'package:sentino/repositories/api/api_agent_repository.dart';
import 'package:sentino/repositories/api/api_ota_repository.dart';

void main() {
  late StorageUtil storage;
  late ApiClient apiClient;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storage = StorageUtil(prefs);
    apiClient = ApiClient(
      baseUrl: 'https://example.com',
      storage: storage,
      language: 'en_US',
    );
  });

  // --- AuthSkillInitializer ---

  group('AuthSkillInitializer', () {
    test('mock mode creates MockAuthRepository', () {
      final config = SkillConfig(
        baseUrl: 'https://example.com',
        storage: storage,
        language: 'en_US',
        useMock: true,
      );
      final bundle = AuthSkillInitializer.initialize(config);
      expect(bundle.repository, isA<MockAuthRepository>());
      expect(bundle.service, isNotNull);
      expect(bundle.provider, isNotNull);
    });

    test('API mode creates ApiAuthRepository', () {
      final config = SkillConfig(
        baseUrl: 'https://example.com',
        storage: storage,
        language: 'en_US',
        useMock: false,
        apiClient: apiClient,
      );
      final bundle = AuthSkillInitializer.initialize(config);
      expect(bundle.repository, isA<ApiAuthRepository>());
    });

    test('API mode without apiClient throws ArgumentError', () {
      final config = SkillConfig(
        baseUrl: 'https://example.com',
        storage: storage,
        language: 'en_US',
        useMock: false,
      );
      expect(() => AuthSkillInitializer.initialize(config),
          throwsA(isA<ArgumentError>()));
    });

    test('descriptor has correct skillId', () {
      expect(AuthSkillInitializer.descriptor.skillId, equals('auth'));
    });
  });

  // --- DeviceSkillInitializer ---

  group('DeviceSkillInitializer', () {
    test('mock mode creates MockDeviceRepository', () {
      final config = SkillConfig(
        baseUrl: 'https://example.com',
        storage: storage,
        language: 'en_US',
        useMock: true,
      );
      final bundle = DeviceSkillInitializer.initialize(config);
      expect(bundle.repository, isA<MockDeviceRepository>());
      expect(bundle.service, isNotNull);
      expect(bundle.provider, isNotNull);
    });

    test('API mode creates ApiDeviceRepository', () {
      final config = SkillConfig(
        baseUrl: 'https://example.com',
        storage: storage,
        language: 'en_US',
        useMock: false,
        apiClient: apiClient,
      );
      final bundle = DeviceSkillInitializer.initialize(config);
      expect(bundle.repository, isA<ApiDeviceRepository>());
    });

    test('API mode without apiClient throws ArgumentError', () {
      final config = SkillConfig(
        baseUrl: 'https://example.com',
        storage: storage,
        language: 'en_US',
        useMock: false,
      );
      expect(() => DeviceSkillInitializer.initialize(config),
          throwsA(isA<ArgumentError>()));
    });

    test('descriptor has correct skillId', () {
      expect(DeviceSkillInitializer.descriptor.skillId, equals('device'));
    });
  });

  // --- BlePairingSkillInitializer ---

  group('BlePairingSkillInitializer', () {
    test('descriptor has correct skillId', () {
      expect(BlePairingSkillInitializer.descriptor.skillId, equals('ble_pairing'));
    });

    test('descriptor lists BLE capabilities', () {
      final caps = BlePairingSkillInitializer.descriptor.capabilities;
      expect(caps.any((c) => c.name == 'startScan'), isTrue);
      expect(caps.any((c) => c.name == 'connectDevice'), isTrue);
    });
  });

  // --- AgentSkillInitializer ---

  group('AgentSkillInitializer', () {
    test('mock mode creates MockAgentRepository', () {
      final config = SkillConfig(
        baseUrl: 'https://example.com',
        storage: storage,
        language: 'en_US',
        useMock: true,
      );
      final bundle = AgentSkillInitializer.initialize(config);
      expect(bundle.repository, isA<MockAgentRepository>());
      expect(bundle.service, isNotNull);
      expect(bundle.provider, isNotNull);
    });

    test('API mode creates ApiAgentRepository', () {
      final config = SkillConfig(
        baseUrl: 'https://example.com',
        storage: storage,
        language: 'en_US',
        useMock: false,
        apiClient: apiClient,
      );
      final bundle = AgentSkillInitializer.initialize(config);
      expect(bundle.repository, isA<ApiAgentRepository>());
    });

    test('API mode without apiClient throws ArgumentError', () {
      final config = SkillConfig(
        baseUrl: 'https://example.com',
        storage: storage,
        language: 'en_US',
        useMock: false,
      );
      expect(() => AgentSkillInitializer.initialize(config),
          throwsA(isA<ArgumentError>()));
    });

    test('descriptor has correct skillId', () {
      expect(AgentSkillInitializer.descriptor.skillId, equals('agent'));
    });
  });

  // --- MqttSkillInitializer ---

  group('MqttSkillInitializer', () {
    test('descriptor has correct skillId', () {
      expect(MqttSkillInitializer.descriptor.skillId, equals('mqtt'));
    });

    test('descriptor lists MQTT capabilities', () {
      final caps = MqttSkillInitializer.descriptor.capabilities;
      expect(caps.any((c) => c.name == 'connect'), isTrue);
      expect(caps.any((c) => c.name == 'disconnect'), isTrue);
    });
  });

  // --- OtaSkillInitializer ---

  group('OtaSkillInitializer', () {
    test('mock mode creates MockOtaRepository', () {
      final config = SkillConfig(
        baseUrl: 'https://example.com',
        storage: storage,
        language: 'en_US',
        useMock: true,
      );
      final bundle = OtaSkillInitializer.initialize(config);
      expect(bundle.repository, isA<MockOtaRepository>());
      expect(bundle.service, isNotNull);
      expect(bundle.provider, isNotNull);
    });

    test('API mode creates ApiOtaRepository', () {
      final config = SkillConfig(
        baseUrl: 'https://example.com',
        storage: storage,
        language: 'en_US',
        useMock: false,
        apiClient: apiClient,
      );
      final bundle = OtaSkillInitializer.initialize(config);
      expect(bundle.repository, isA<ApiOtaRepository>());
    });

    test('API mode without apiClient throws ArgumentError', () {
      final config = SkillConfig(
        baseUrl: 'https://example.com',
        storage: storage,
        language: 'en_US',
        useMock: false,
      );
      expect(() => OtaSkillInitializer.initialize(config),
          throwsA(isA<ArgumentError>()));
    });

    test('descriptor has correct skillId', () {
      expect(OtaSkillInitializer.descriptor.skillId, equals('ota'));
    });
  });
}
