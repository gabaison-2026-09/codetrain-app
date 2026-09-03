import 'dart:convert';

import 'package:codetrain_app/core/env/app_config.dart';
import 'package:codetrain_app/core/env/app_environment.dart';
import 'package:codetrain_app/core/network/api_client.dart';
import 'package:codetrain_app/core/network/api_exception.dart';
import 'package:codetrain_app/core/network/auth_header_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

AppConfig _config([String baseUrl = 'https://api.example.com']) {
  return AppConfig.resolve(
    apiBaseUrl: baseUrl,
    authMode: 'dev',
    devUser: 'tester',
  );
}

ApiClient _client(
  AppConfig config,
  Future<http.Response> Function(http.Request request) handler,
) {
  return ApiClient(
    config: config,
    authHeaderProvider: authHeaderProviderFor(config),
    httpClient: MockClient(handler),
  );
}

void main() {
  test('正常GETでJSONボディをデコードして返す', () async {
    final client = _client(_config(), (request) async {
      return http.Response(
        jsonEncode({'ok': true}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final body = await client.get('/v1/me');
    expect(body, {'ok': true});
  });

  test('共通ヘッダーと X-Dev-User ヘッダーが送信される', () async {
    late http.Request captured;
    final client = _client(_config(), (request) async {
      captured = request;
      return http.Response('{}', 200);
    });

    await client.get('/v1/me');

    expect(captured.headers['content-type'], contains('application/json'));
    expect(captured.headers['accept'], 'application/json');
    expect(captured.headers['x-dev-user'], 'tester');
  });

  test('先頭スラッシュ無しのパスには /v1 が前置される', () async {
    late Uri url;
    final client = _client(_config(), (request) async {
      url = request.url;
      return http.Response('{}', 200);
    });

    await client.get('questions', query: {'limit': 20, 'type': null});

    expect(url.path, '/v1/questions');
    expect(url.queryParameters, {'limit': '20'});
  });

  test('PUTと複数値クエリを送信できる', () async {
    late http.Request captured;
    final client = _client(_config(), (request) async {
      captured = request;
      return http.Response('{}', 200);
    });

    await client.put('task-slots/1', body: {'difficulty': 2});
    expect(captured.method, 'PUT');
    expect(jsonDecode(captured.body), {'difficulty': 2});

    await client.get('questions', query: {
      'tag': ['array', 'es2020'],
    });
    expect(captured.url.queryParametersAll['tag'], ['array', 'es2020']);
  });

  test('ベースURL切替がリクエストURLに反映される', () async {
    late Uri url;
    final client = _client(_config('https://staging.example.com/base'), (
      request,
    ) async {
      url = request.url;
      return http.Response('{}', 200);
    });

    await client.get('/healthz');

    expect(url.toString(), 'https://staging.example.com/base/healthz');
  });

  test('エラーレスポンスは ApiException に変換される', () async {
    final client = _client(_config(), (request) async {
      return http.Response(
        jsonEncode({
          'error': {'code': 'QUESTION_NOT_FOUND', 'message': '問題が見つかりません'},
        }),
        404,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

    expect(
      () => client.get('/v1/questions/xxx'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.code, 'code', 'QUESTION_NOT_FOUND')
            .having((e) => e.statusCode, 'statusCode', 404),
      ),
    );
  });

  test('getPaginated が items と next_cursor を読む', () async {
    final client = _client(_config(), (request) async {
      return http.Response(
        jsonEncode({
          'questions': [
            {'id': 'a'},
            {'id': 'b'},
          ],
          'next_cursor': 'cursor-2',
        }),
        200,
      );
    });

    final page = await client.getPaginated<String>(
      '/v1/questions',
      resourceKey: 'questions',
      parse: (json) => json['id'] as String,
      limit: 20,
    );

    expect(page.items, ['a', 'b']);
    expect(page.nextCursor, 'cursor-2');
    expect(page.hasMore, isTrue);
  });

  test('接続失敗は NETWORK_ERROR にマップされる', () async {
    final client = _client(_config(), (request) async {
      throw http.ClientException('connection failed');
    });

    expect(
      () => client.get('/v1/me'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.code,
          'code',
          ApiException.codeNetworkError,
        ),
      ),
    );
  });

  test('prod 環境では X-Dev-User を送らない', () async {
    final config = AppConfig.resolve(
      apiBaseUrl: 'https://api.example.com',
      authMode: 'prod',
      devUser: 'tester',
    );
    expect(config.environment, AppEnvironment.prod);

    late http.Request captured;
    final client = _client(config, (request) async {
      captured = request;
      return http.Response('{}', 200);
    });

    await client.get('/v1/me');
    expect(captured.headers.containsKey('x-dev-user'), isFalse);
  });
}
