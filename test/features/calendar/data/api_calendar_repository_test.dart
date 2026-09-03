import 'dart:convert';

import 'package:codetrain_app/core/env/app_config.dart';
import 'package:codetrain_app/core/network/api_client.dart';
import 'package:codetrain_app/core/network/api_exception.dart';
import 'package:codetrain_app/core/network/auth_header_provider.dart';
import 'package:codetrain_app/features/calendar/data/api_calendar_repository.dart';
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
  test('日付クエリを送りCalendarResponseDtoをドメインへ変換する', () async {
    final repository = ApiCalendarRepository(
      _client((request) async {
        expect(request.url.queryParameters, {
          'from': '2026-09-01',
          'to': '2026-09-30',
        });
        return http.Response(
          jsonEncode({
            'days': [
              {
                'date': '2026-09-01',
                'total_slots': 3,
                'completed_slots': 3,
                'completed': true,
              },
            ],
            'streak_days': 5,
            'last_studied_on': '2026-09-01',
          }),
          200,
        );
      }),
    );

    final activity = await repository.fetchActivity(
      from: DateTime(2026, 9, 1),
      to: DateTime(2026, 9, 30),
    );
    expect(activity.days.single.completed, isTrue);
    expect(activity.streakDays, 5);
  });

  test('calendarのエラーエンベロープをApiExceptionへ変換する', () async {
    final repository = ApiCalendarRepository(
      _client((request) async => http.Response(
            jsonEncode({
              'error': {
                'status': 400,
                'code': 'VALIDATION_ERROR',
                'message': '期間が不正です',
              },
            }),
            400,
          )),
    );
    expect(
      () => repository.fetchActivity(
        from: DateTime(2026, 9, 30),
        to: DateTime(2026, 9, 1),
      ),
      throwsA(isA<ApiException>()),
    );
  });
}
