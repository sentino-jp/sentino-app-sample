import '../repositories/api/coucou_api.dart';
import '../utils/api_client.dart';
import '../utils/storage.dart';

/// Skill 初始化所需的公共配置
class SkillConfig {
  final String baseUrl;
  final StorageUtil storage;
  final String language;
  final bool useMock;
  final ApiClient? apiClient;
  final CoucouApi? coucouApi;   // coucou-server 客户端(coucou 模式注入 Device/Agent Provider)

  const SkillConfig({
    required this.baseUrl,
    required this.storage,
    required this.language,
    this.useMock = false,
    this.apiClient,
    this.coucouApi,
  });
}
