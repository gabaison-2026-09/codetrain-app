/// アプリの実行環境。
///
/// - [local]: ローカルの `codetrain-api`（`AUTH_MODE=dev`）に接続する既定の開発環境。
///   ベースURLが未指定で、フォールバック値が使われている状態。
/// - [dev]: ベースURLを明示指定したうえで dev 認証（`X-Dev-User`）を使う環境。
///   ステージング等の共有開発サーバーを想定する。
/// - [prod]: 本番環境。`Authorization: Bearer <token>` 認証を使う。
enum AppEnvironment {
  local,
  dev,
  prod;

  bool get isProduction => this == AppEnvironment.prod;

  /// dev 認証（`X-Dev-User` ヘッダー）を使う環境かどうか。
  bool get usesDevAuth =>
      this == AppEnvironment.local || this == AppEnvironment.dev;
}
