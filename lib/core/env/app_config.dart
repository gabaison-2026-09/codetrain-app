import 'app_environment.dart';

/// 実行時のアプリ設定。
///
/// `docs/API_DESIGN.md` §1 を正とする。ベースパス `/v1` は [apiBaseUrl] には
/// 含めず、`ApiClient` 側で各リクエストパスに付与する（`/healthz` のように
/// `/v1` を使わない口を残すため）。
///
/// 値は起動時に `--dart-define` で切り替える。
///
/// ```
/// flutter run \
///   --dart-define=API_BASE_URL=https://api.example.com \
///   --dart-define=AUTH_MODE=prod
/// ```
class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.environment,
    this.devUser,
  });

  /// `--dart-define` から設定を解決する。
  ///
  /// - `API_BASE_URL`: APIのベースURL。未指定時は [fallbackLocalBaseUrl]。
  /// - `AUTH_MODE`: `dev`（既定） / `prod`。
  /// - `DEV_USER`: dev 認証で `X-Dev-User` に載せる文字列。未指定時は
  ///   [defaultDevUser]。
  factory AppConfig.fromEnvironment() {
    return AppConfig.resolve(
      apiBaseUrl: const String.fromEnvironment('API_BASE_URL'),
      authMode: const String.fromEnvironment('AUTH_MODE', defaultValue: 'dev'),
      devUser: const String.fromEnvironment(
        'DEV_USER',
        defaultValue: defaultDevUser,
      ),
    );
  }

  /// 生の文字列設定から [AppConfig] を組み立てる。
  ///
  /// [AppConfig.fromEnvironment] は `String.fromEnvironment` に依存しテストで
  /// 差し替えられないため、解決ロジックだけを切り出してテスト可能にしている。
  factory AppConfig.resolve({
    required String apiBaseUrl,
    required String authMode,
    required String devUser,
  }) {
    final trimmedBaseUrl = apiBaseUrl.trim();
    final hasExplicitBaseUrl = trimmedBaseUrl.isNotEmpty;
    final resolvedBaseUrl = Uri.parse(
      hasExplicitBaseUrl ? trimmedBaseUrl : fallbackLocalBaseUrl,
    );

    final isProd = authMode.trim().toLowerCase() == 'prod';
    final AppEnvironment environment;
    if (isProd) {
      environment = AppEnvironment.prod;
    } else if (hasExplicitBaseUrl) {
      environment = AppEnvironment.dev;
    } else {
      environment = AppEnvironment.local;
    }

    return AppConfig(
      apiBaseUrl: resolvedBaseUrl,
      environment: environment,
      devUser: environment.usesDevAuth ? devUser.trim() : null,
    );
  }

  /// `API_BASE_URL` 未指定時のローカル既定値。
  ///
  /// `10.0.2.2` は Android エミュレータからホストマシンを指すアドレス。
  /// iOS シミュレータ・実機・Web では到達できないため、それらの環境では
  /// `--dart-define=API_BASE_URL=...` の指定が必須。
  static const String fallbackLocalBaseUrl = 'http://10.0.2.2:8080';

  /// `DEV_USER` 未指定時に `X-Dev-User` へ載せる既定値。
  static const String defaultDevUser = 'local-dev-user';

  /// APIのベースURL（`/v1` を含まない）。
  final Uri apiBaseUrl;

  /// 解決された実行環境。
  final AppEnvironment environment;

  /// dev 認証時に `X-Dev-User` へ載せる文字列。prod 環境では `null`。
  final String? devUser;

  @override
  String toString() =>
      'AppConfig(apiBaseUrl: $apiBaseUrl, environment: ${environment.name}, '
      'devUser: $devUser)';
}
