/// Auth Skill 初始化器，封装认证模块的 Repository/Service/Provider 创建逻辑
import '../../providers/auth_provider.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/api/api_auth_repository.dart';
import '../../repositories/mock/mock_auth_repository.dart';
import '../../services/auth_service.dart';
import '../skill_capability.dart';
import '../skill_config.dart';
import '../skill_descriptor.dart';

/// Auth Skill 初始化结果
class AuthSkillBundle {
  final AuthRepository repository;
  final AuthService service;
  final AuthProvider provider;

  const AuthSkillBundle({
    required this.repository,
    required this.service,
    required this.provider,
  });
}

/// Auth Skill 初始化器
class AuthSkillInitializer {
  static AuthSkillBundle initialize(SkillConfig config) {
    final AuthRepository repo;
    if (config.useMock) {
      repo = MockAuthRepository();
    } else {
      if (config.apiClient == null) {
        throw ArgumentError('AuthSkillInitializer: apiClient is required in API mode');
      }
      repo = ApiAuthRepository(api: config.apiClient!);
    }
    final service = AuthService(
      repository: repo,
      storage: config.storage,
      coucouApi: config.coucouApi, // 复用同一实例（含 401→刷新拦截器）
    );
    final provider = AuthProvider(authService: service);
    return AuthSkillBundle(repository: repo, service: service, provider: provider);
  }

  static SkillDescriptor get descriptor => const SkillDescriptor(
    skillId: 'auth',
    name: '认证',
    description: '用户认证与账户管理',
    capabilities: [
      SkillCapability(name: 'login', description: '用户登录并持久化令牌'),
      SkillCapability(name: 'register', description: '用户注册（邮箱验证码）'),
      SkillCapability(name: 'sendRegisterCode', description: '发送注册验证码'),
      SkillCapability(name: 'forgotPassword', description: '发送忘记密码验证信息'),
      SkillCapability(name: 'resetPassword', description: '重置密码'),
      SkillCapability(name: 'changePassword', description: '修改密码'),
      SkillCapability(name: 'logout', description: '登出并清除令牌'),
      SkillCapability(name: 'getUserProfile', description: '获取用户资料'),
      SkillCapability(name: 'uploadAvatar', description: '上传头像'),
      SkillCapability(name: 'updateUserInfo', description: '更新用户信息'),
    ],
    dependencies: [],
    codePaths: {
      'models': ['lib/models/user.dart', 'lib/models/auth_result.dart'],
      'repositories': [
        'lib/repositories/auth_repository.dart',
        'lib/repositories/api/api_auth_repository.dart',
        'lib/repositories/mock/mock_auth_repository.dart',
      ],
      'services': ['lib/services/auth_service.dart'],
      'providers': ['lib/providers/auth_provider.dart'],
    },
  );
}
