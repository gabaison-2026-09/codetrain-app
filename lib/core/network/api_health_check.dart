import 'api_client.dart';

/// 共通APIクライアント経由でGETリクエストを送る疎通確認用ヘルパ。
///
/// `docs/API_DESIGN.md` §1 の `GET /healthz`（`/v1` を付けない）を叩く。
/// Composition RootでのRepository切替前にも、base URLと共通HTTP処理だけを
/// 独立して確認できる。
class ApiHealthCheck {
  const ApiHealthCheck(this._client);

  final ApiClient _client;

  /// `GET /healthz` を送信する。エラー時は [ApiException] を投げる。
  Future<void> ping() async {
    await _client.get('/healthz');
  }
}
