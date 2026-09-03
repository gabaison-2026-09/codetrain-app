import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../env/app_config.dart';
import 'api_exception.dart';
import 'auth_header_provider.dart';
import 'paginated_response.dart';

/// 共通APIクライアント。
///
/// `docs/API_DESIGN.md` を正とする。
/// - ベースURL・共通ヘッダー（`Content-Type` / `Accept`）の付与
/// - 認証ヘッダーの付与（[AuthHeaderProvider] に委譲）
/// - エラーエンベロープの [ApiException] へのマッピング
/// - カーソルページング（`cursor` / `limit` / `next_cursor`）の下地
///
/// 個別エンドポイントの通信処理は各 feature の data 層で本クラスを使う。
class ApiClient {
  // 名前付きパラメータはアンダースコア始まりにできず initializing formal を
  // 使えないため、prefer_initializing_formals はここでは適用できない。
  // ignore_for_file: prefer_initializing_formals
  ApiClient({
    required AppConfig config,
    required AuthHeaderProvider authHeaderProvider,
    http.Client? httpClient,
    Duration timeout = const Duration(seconds: 15),
  }) : _config = config,
       _authHeaderProvider = authHeaderProvider,
       _timeout = timeout,
       _httpClient = httpClient ?? http.Client();

  /// [AppConfig] から認証プロバイダを解決して組み立てる簡易ファクトリ。
  factory ApiClient.fromConfig(AppConfig config, {http.Client? httpClient}) {
    return ApiClient(
      config: config,
      authHeaderProvider: authHeaderProviderFor(config),
      httpClient: httpClient,
    );
  }

  final AppConfig _config;
  final AuthHeaderProvider _authHeaderProvider;
  final http.Client _httpClient;
  final Duration _timeout;

  /// API設計 §1 のベースパス。先頭が `/` で始まらないパスに前置する。
  static const String _apiPrefix = '/v1';

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) {
    return _send('GET', path, query: query);
  }

  Future<dynamic> post(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
  }) {
    return _send('POST', path, body: body, query: query);
  }

  Future<dynamic> patch(String path, {Object? body}) {
    return _send('PATCH', path, body: body);
  }

  Future<dynamic> put(String path, {Object? body}) {
    return _send('PUT', path, body: body);
  }

  Future<dynamic> delete(String path, {Object? body}) {
    return _send('DELETE', path, body: body);
  }

  /// カーソルページング対応の一覧取得。
  ///
  /// [resourceKey] はレスポンス内の配列キー（例: `questions` / `users` / `items`）。
  Future<PaginatedResponse<T>> getPaginated<T>(
    String path, {
    required String resourceKey,
    required T Function(Map<String, dynamic> json) parse,
    String? cursor,
    int? limit,
    Map<String, dynamic>? query,
  }) async {
    final mergedQuery = <String, dynamic>{
      ...?query,
      'cursor': ?cursor,
      'limit': ?limit,
    };
    final body = await get(path, query: mergedQuery);
    if (body is! Map<String, dynamic>) {
      throw ApiException(
        code: ApiException.codeInternalError,
        message: 'ページングレスポンスの形式が不正です',
        statusCode: 200,
      );
    }
    final rawItems = body[resourceKey];
    final items = <T>[
      if (rawItems is List)
        for (final element in rawItems)
          if (element is Map<String, dynamic>) parse(element),
    ];
    return PaginatedResponse<T>(
      items: items,
      nextCursor: body['next_cursor'] as String?,
    );
  }

  /// 使用終了時に内部の [http.Client] を閉じる。
  void close() => _httpClient.close();

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
  }) async {
    final request = http.Request(method, _resolveUri(path, query));
    request.headers.addAll(await _buildHeaders());
    if (body != null) {
      request.body = jsonEncode(body);
    }

    final http.Response response;
    try {
      final streamed = await _httpClient.send(request).timeout(_timeout);
      response = await http.Response.fromStream(streamed);
    } on TimeoutException catch (e) {
      throw ApiException.network(e);
    } on SocketException catch (e) {
      throw ApiException.network(e);
    } on http.ClientException catch (e) {
      throw ApiException.network(e);
    }

    return _handle(response);
  }

  Uri _resolveUri(String path, Map<String, dynamic>? query) {
    final normalizedPath = path.startsWith('/') ? path : '$_apiPrefix/$path';
    final base = _config.apiBaseUrl;
    final queryParameters = <String, dynamic>{
      ...base.queryParameters,
      if (query != null)
        for (final entry in query.entries)
          if (entry.value != null)
            entry.key: entry.value is Iterable
                ? (entry.value as Iterable).map((value) => '$value').toList()
                : '${entry.value}',
    };
    return base.replace(
      path: '${base.path}$normalizedPath',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
  }

  Future<Map<String, String>> _buildHeaders() async {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...await _authHeaderProvider.headers(),
    };
  }

  dynamic _handle(http.Response response) {
    final decoded = _tryDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }
    throw ApiException.fromResponse(response.statusCode, decoded);
  }

  static dynamic _tryDecode(String body) {
    if (body.trim().isEmpty) return null;
    try {
      return jsonDecode(body);
    } on FormatException {
      return null;
    }
  }
}
