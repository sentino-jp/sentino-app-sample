import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:google_sign_in/google_sign_in.dart';

import '../utils/app_config.dart';

/// 一次原生三方登录换回的身份凭据（转交后端验签换会话）。
class NativeCredential {
  /// Google 的 `idToken`（Apple 接入后为 `identityToken`）。
  final String idToken;

  /// 本次登录的**原始** nonce（未哈希）。服务端按 provider 各自算期望值比对。
  final String nonce;

  /// Apple 仅**首次**授权返回姓名且不在 id_token 内 → 转交服务端兜底建档。
  /// Google 的 name 在 id_token 里，恒为 null。
  final String? fullName;

  const NativeCredential({
    required this.idToken,
    required this.nonce,
    this.fullName,
  });
}

/// 用户在系统授权面板上取消。
///
/// 与「登录失败」区分：取消是正常操作，登录页只提示「已取消」而非报错。
class NativeOAuthCancelled implements Exception {
  const NativeOAuthCancelled();

  @override
  String toString() => 'Native sign-in cancelled by user';
}

/// 该 provider 在当前平台/设备上走不了原生流程（无 SDK、或设备缺底层认证服务）。
class NativeOAuthUnsupported implements Exception {
  final String provider;

  const NativeOAuthUnsupported(this.provider);

  @override
  String toString() => 'Native sign-in unsupported for provider: $provider';
}

/// 原生登录在 SDK 层失败（非用户取消）。[code] 仅用于日志/排查，不直接展示。
class NativeOAuthFailure implements Exception {
  final String code;

  const NativeOAuthFailure(this.code);

  @override
  String toString() => 'Native sign-in failed: $code';
}

/// 系统级登录 API 的注入缝（生产走 Google SDK；测试注入假实现）。
abstract class NativeOAuthClient {
  /// 该 provider 在**当前平台**能否走原生流程。
  bool supports(String provider);

  /// 拉起系统授权面板。
  /// 取消抛 [NativeOAuthCancelled]，不支持抛 [NativeOAuthUnsupported]，
  /// 其余 SDK 错误抛 [NativeOAuthFailure]。
  Future<NativeCredential> signIn(String provider);
}

/// 生产实现：Android → Credential Manager；iOS → GIDSignIn。
///
/// 各平台的**真实**形态（别抱错预期）：
/// - **Android**：`CredentialManager` + `GetSignInWithGoogleOption`，系统账号底部弹窗，全程无浏览器；
/// - **iOS**：GIDSignIn 内部仍是 `ASWebAuthenticationSession`——Google 自家强制要求，无 SDK 能绕开。
///   相较网页流的收益是省掉服务端 authorize→callback 两跳、直接拿 id_token，不再经 custom scheme 回跳；
/// - 其余平台（web/desktop）不支持 → [supports] 恒 false，登录页据此隐藏按钮。
class PlatformNativeOAuthClient implements NativeOAuthClient {
  static const String providerGoogle = 'google';

  const PlatformNativeOAuthClient();

  @override
  bool supports(String provider) {
    if (provider != providerGoogle) return false;
    return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
  }

  @override
  Future<NativeCredential> signIn(String provider) {
    if (!supports(provider)) throw NativeOAuthUnsupported(provider);
    return _signInWithGoogle(_generateNonce());
  }

  Future<NativeCredential> _signInWithGoogle(String nonce) async {
    try {
      // nonce 是 initialize 级参数（SDK 未开放 per-authenticate 传入），所以每次登录前
      // 重新 initialize 以换取**每次不同**的 nonce（防重放）。这是安全的：两个移动平台的
      // init() 都只是赋值字段，不会重复订阅事件流。
      await GoogleSignIn.instance.initialize(
        // iOS 留空则由 SDK 读 Info.plist 的 GIDClientID（那里还要配 URL scheme，
        // 以 Info.plist 为单一来源，避免两处分填写歪一处）。
        clientId: _nullIfEmpty(AppConfig.googleIosClientId),
        serverClientId: _nullIfEmpty(AppConfig.googleServerClientId),
        nonce: nonce,
      );
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const NativeOAuthFailure('google_missing_id_token');
      }
      return NativeCredential(idToken: idToken, nonce: nonce);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        throw const NativeOAuthCancelled();
      }
      if (e.code == GoogleSignInExceptionCode.providerConfigurationError) {
        // 底层认证 SDK 不可用——设备没有 Google Play 服务（华为、部分国产 ROM、
        // 无 GApps 的模拟器）。Credential Manager **不会**自己退回浏览器，
        // 这些设备就是登不了 Google，如实告知调用方。
        //
        // 注意不含 clientConfigurationError（少配 serverClientId / SHA-1 未登记之类）：
        // 那是构建配置错误，必须炸出来，不能和「设备不支持」混为一谈。
        throw const NativeOAuthUnsupported(providerGoogle);
      }
      throw NativeOAuthFailure('google_${e.code.name}');
    }
  }

  static String? _nullIfEmpty(String value) => value.isEmpty ? null : value;

  /// 每次登录一枚随机 nonce（防重放）。用密码学安全随机源。
  static String _generateNonce([int length = 32]) {
    final random = Random.secure();
    final bytes = List<int>.generate(length, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }
}
