import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sentino/repositories/api/coucou_api.dart';
import 'package:sentino/repositories/auth_repository.dart';
import 'package:sentino/models/auth_result.dart';
import 'package:sentino/models/user.dart';
import 'package:sentino/services/auth_service.dart';
import 'package:sentino/services/native_oauth_client.dart';
import 'package:sentino/utils/storage.dart';

/// 假的系统级登录 SDK —— 单测不能真拉起 Credential Manager / GIDSignIn 面板。
class _FakeNative implements NativeOAuthClient {
  _FakeNative({this.credential, this.error, this.supported = true});

  final NativeCredential? credential;
  final Object? error;
  final bool supported;

  int signInCalls = 0;

  @override
  bool supports(String provider) => supported;

  @override
  Future<NativeCredential> signIn(String provider) async {
    signInCalls++;
    if (error != null) throw error!;
    return credential!;
  }
}

/// 假的 coucou-server 客户端 —— 记录请求参数、返回预设响应。
/// 继承真类只覆写两个 OAuth 方法，其余不会在本测试路径上被调到。
class _FakeCoucouApi extends CoucouApi {
  _FakeCoucouApi({
    required super.storage,
    required this.nativeResult,
    this.bindResult,
  });

  final CoucouOAuthResult nativeResult;
  final ({String accessToken, String? refreshToken})? bindResult;

  String? sentIdToken;
  String? sentNonce;
  String? sentFullName;
  String? sentProvider;
  String? sentBindingToken;
  int bindCalls = 0;

  @override
  Future<CoucouOAuthResult> oauthNative({
    required String provider,
    required String idToken,
    required String nonce,
    String? fullName,
  }) async {
    sentProvider = provider;
    sentIdToken = idToken;
    sentNonce = nonce;
    sentFullName = fullName;
    return nativeResult;
  }

  @override
  Future<({String accessToken, String? refreshToken})> oauthBind(
      String bindingToken) async {
    bindCalls++;
    sentBindingToken = bindingToken;
    if (bindResult == null) {
      throw CoucouApiException('bind not stubbed');
    }
    return bindResult!;
  }
}

/// AuthService 构造要求，但 Google 路径完全不经过它。
class _UnusedRepository implements AuthRepository {
  @override
  Never noSuchMethod(Invocation invocation) =>
      throw StateError('cetus repository must not be touched by Google login');

  @override
  Future<AuthResult> login(String uid, String password, String areaCode,
          String countryKey) =>
      throw StateError('unused');

  @override
  Future<User> getUserProfile() => throw StateError('unused');
}

void main() {
  late StorageUtil storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = StorageUtil(await SharedPreferences.getInstance());
  });

  AuthService build({
    required _FakeCoucouApi api,
    required _FakeNative native,
  }) {
    return AuthService(
      repository: _UnusedRepository(),
      storage: storage,
      coucouApi: api,
      nativeOAuthClient: native,
    );
  }

  group('AuthService.loginWithGoogle', () {
    test('已绑账号：直接落 token 与 coucou 登录模式，不再走 bind', () async {
      final api = _FakeCoucouApi(
        storage: storage,
        nativeResult: const CoucouOAuthResult(
          bound: true,
          accessToken: 'at-1',
          refreshToken: 'rt-1',
        ),
      );
      final native = _FakeNative(
        credential: const NativeCredential(idToken: 'idt', nonce: 'raw-nonce'),
      );

      await build(api: api, native: native).loginWithGoogle();

      expect(storage.getAccessToken(), 'at-1');
      expect(storage.getRefreshToken(), 'rt-1');
      // loginMode 必须是 coucou：cetus 模式会让「我的」页去打 cetus profile（无 session → 全空）。
      expect(storage.isCoucouMode, isTrue);
      expect(api.bindCalls, 0);
    });

    test('首次登录：binding_token 自动换会话（本 App 无邀请码流程，不中断到补充页）', () async {
      final api = _FakeCoucouApi(
        storage: storage,
        nativeResult: const CoucouOAuthResult(
          bound: false,
          bindingToken: 'bt-9',
          email: 'a@b.com',
        ),
        bindResult: (accessToken: 'at-2', refreshToken: 'rt-2'),
      );
      final native = _FakeNative(
        credential: const NativeCredential(idToken: 'idt', nonce: 'raw-nonce'),
      );

      await build(api: api, native: native).loginWithGoogle();

      expect(api.bindCalls, 1);
      expect(api.sentBindingToken, 'bt-9');
      expect(storage.getAccessToken(), 'at-2');
      expect(storage.getRefreshToken(), 'rt-2');
      expect(storage.isCoucouMode, isTrue);
    });

    test('传给服务端的 nonce 必须是原始值（服务端按 provider 自算期望值比对）', () async {
      final api = _FakeCoucouApi(
        storage: storage,
        nativeResult: const CoucouOAuthResult(bound: true, accessToken: 'at'),
      );
      final native = _FakeNative(
        credential: const NativeCredential(
          idToken: 'the-id-token',
          nonce: 'raw-nonce-value',
          fullName: 'Ada L',
        ),
      );

      await build(api: api, native: native).loginWithGoogle();

      expect(api.sentProvider, 'google');
      expect(api.sentIdToken, 'the-id-token');
      expect(api.sentNonce, 'raw-nonce-value'); // 不是哈希
      expect(api.sentFullName, 'Ada L');
    });

    test('用户取消：原样抛出 NativeOAuthCancelled（由 provider 静默处理），不写任何登录态', () async {
      final api = _FakeCoucouApi(
        storage: storage,
        nativeResult: const CoucouOAuthResult(bound: true, accessToken: 'at'),
      );
      final native = _FakeNative(error: const NativeOAuthCancelled());

      await expectLater(
        build(api: api, native: native).loginWithGoogle(),
        throwsA(isA<NativeOAuthCancelled>()),
      );
      expect(storage.getAccessToken(), isNull);
    });

    test('未绑且没给 binding_token：早失败，不留半登录态', () async {
      final api = _FakeCoucouApi(
        storage: storage,
        nativeResult: const CoucouOAuthResult(bound: false),
      );
      final native = _FakeNative(
        credential: const NativeCredential(idToken: 'idt', nonce: 'n'),
      );

      await expectLater(
        build(api: api, native: native).loginWithGoogle(),
        throwsA(isA<CoucouApiException>()),
      );
      expect(storage.getAccessToken(), isNull);
      expect(api.bindCalls, 0);
    });

    test('平台不支持时 isGoogleSignInAvailable=false（登录页据此隐藏按钮）', () {
      final api = _FakeCoucouApi(
        storage: storage,
        nativeResult: const CoucouOAuthResult(bound: true, accessToken: 'at'),
      );
      final service =
          build(api: api, native: _FakeNative(supported: false));
      expect(service.isGoogleSignInAvailable, isFalse);
    });
  });

  group('CoucouOAuthResult.fromJson', () {
    test('已绑分支：AuthResponse 拍平在顶层（与 /login 同构）', () {
      final r = CoucouOAuthResult.fromJson({
        'bound': true,
        'access_token': 'at',
        'refresh_token': 'rt',
      });
      expect(r.bound, isTrue);
      expect(r.accessToken, 'at');
      expect(r.refreshToken, 'rt');
    });

    test('上游漏发 bound 但有 token 时仍判已绑，不会把成功登录误当待绑定', () {
      final r = CoucouOAuthResult.fromJson({'access_token': 'at'});
      expect(r.bound, isTrue);
    });

    test('未绑分支：binding_token + 三方资料，且 bound=false', () {
      final r = CoucouOAuthResult.fromJson({
        'bound': false,
        'binding_token': 'bt',
        'provider': 'google',
        'email': 'a@b.com',
        'name': 'Ada',
        'avatar_url': 'https://x/y.png',
      });
      expect(r.bound, isFalse);
      expect(r.bindingToken, 'bt');
      expect(r.provider, 'google');
      expect(r.email, 'a@b.com');
      expect(r.name, 'Ada');
      expect(r.avatarUrl, 'https://x/y.png');
      expect(r.accessToken, isNull);
    });

    test('camelCase 响应也能解析（后端换 Jackson 命名策略时不至于静默登录失败）', () {
      final r = CoucouOAuthResult.fromJson({
        'bound': true,
        'accessToken': 'at',
        'refreshToken': 'rt',
      });
      expect(r.accessToken, 'at');
      expect(r.refreshToken, 'rt');
    });

    test('空串字段归一为 null（后端对无 email/avatar 的 provider 降级为空串）', () {
      final r = CoucouOAuthResult.fromJson({
        'bound': false,
        'binding_token': 'bt',
        'email': '',
        'avatar_url': '',
      });
      expect(r.email, isNull);
      expect(r.avatarUrl, isNull);
    });
  });
}
