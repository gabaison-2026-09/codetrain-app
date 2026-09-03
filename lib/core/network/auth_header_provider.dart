import '../env/app_config.dart';

/// リクエストへ付与する認証ヘッダーを供給する。
abstract interface class AuthHeaderProvider {
  /// このリクエストに付与する認証ヘッダーを返す。付与不要なら空マップ。
  Future<Map<String, String>> headers();
}

/// [AppConfig] の環境に応じて適切な実装を返すファクトリ。
AuthHeaderProvider authHeaderProviderFor(AppConfig config) {
  if (config.environment.isProduction) {
    return const BearerTokenAuthHeaderProvider();
  }
  return DevUserAuthHeaderProvider(config.devUser ?? AppConfig.defaultDevUser);
}

/// dev 認証（ローカルの `codetrain-api` `AUTH_MODE=dev` 向け）。
///
/// `X-Dev-User: <任意の文字列>` を `sub` として扱う（`docs/API_DESIGN.md` §1）。
class DevUserAuthHeaderProvider implements AuthHeaderProvider {
  const DevUserAuthHeaderProvider(this._devUser);

  final String _devUser;

  @override
  Future<Map<String, String>> headers() async => {'X-Dev-User': _devUser};
}

/// prod 認証。`Authorization: Bearer <token>` を付与する「口」だけを用意する。
///
/// TODO(issue-30): トークンの取得方法は Cognito / Firebase Authentication の
///   どちらを採用するか未決定のため、このIssueでは実装しない。方式決定後、
///   ここにトークン取得（キャッシュ・リフレッシュ含む）を実装する。
///   暫定的に `--dart-define=AUTH_BEARER_TOKEN=...` を読むだけにしている。
class BearerTokenAuthHeaderProvider implements AuthHeaderProvider {
  const BearerTokenAuthHeaderProvider();

  @override
  Future<Map<String, String>> headers() async {
    const token = String.fromEnvironment('AUTH_BEARER_TOKEN');
    if (token.isEmpty) return const {};
    return {'Authorization': 'Bearer $token'};
  }
}
