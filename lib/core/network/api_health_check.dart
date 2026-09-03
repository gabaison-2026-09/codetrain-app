import 'api_client.dart';

/// 共通APIクライアント経由でダミーのGETリクエストを送るための疎通確認用ヘルパ。
///
/// `docs/API_DESIGN.md` §1 の `GET /healthz`（`/v1` を付けない）を叩く。
/// Issue 30 の完了条件「共通APIクライアント経由でダミーのGETリクエストが
/// 送信できる」を満たすための最小実装で、個別エンドポイントの Repository は
/// Issue 2 以降で追加する。
class ApiHealthCheck {
  const ApiHealthCheck(this._client);

  final ApiClient _client;

  /// `GET /healthz` を送信する。エラー時は [ApiException] を投げる。
  Future<void> ping() async {
    await _client.get('/healthz');
  }
}
