import 'package:codetrain_app/core/env/app_config.dart';
import 'package:codetrain_app/core/network/api_client.dart';
import 'package:codetrain_app/core/network/api_exception.dart';
import 'package:codetrain_app/core/network/api_health_check.dart';
import 'package:codetrain_app/core/network/auth_header_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

ApiClient _client(Future<http.Response> Function(http.Request) handler) {
  final config = AppConfig.resolve(
    apiBaseUrl: 'https://api.example.com',
    authMode: 'dev',
    devUser: 'tester',
  );
  return ApiClient(
    config: config,
    authHeaderProvider: authHeaderProviderFor(config),
    httpClient: MockClient(handler),
  );
}

void main() {
  test('GET /healthzで疎通確認する', () async {
    final healthCheck = ApiHealthCheck(
      _client((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/healthz');
        return http.Response('{"status":"ok"}', 200);
      }),
    );
    await healthCheck.ping();
  });

  test('healthz失敗をApiExceptionで通知する', () async {
    final healthCheck = ApiHealthCheck(
      _client((request) async => http.Response(
            '{"error":{"code":"INTERNAL_ERROR","message":"failed"}}',
            500,
          )),
    );
    expect(healthCheck.ping, throwsA(isA<ApiException>()));
  });
}
