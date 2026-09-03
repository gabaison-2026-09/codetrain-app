import 'dart:convert';

import 'package:codetrain_app/core/env/app_config.dart';
import 'package:codetrain_app/core/network/api_client.dart';
import 'package:codetrain_app/core/network/api_exception.dart';
import 'package:codetrain_app/core/network/auth_header_provider.dart';
import 'package:codetrain_app/features/home/data/api_home_dashboard_repository.dart';
import 'package:codetrain_app/features/home/data/api_top_navigation_repository.dart';
import 'package:codetrain_app/features/home/data/home_remote_data_source.dart';
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

const _meResponse = <String, Object?>{
  'user': {
    'id': 'user-1',
    'external_id': 'sub-1',
    'user_code': 'taro',
    'display_name': '太郎',
    'email': 'taro@example.com',
    'created_at': '2026-09-02T03:04:05Z',
  },
  'progress': {
    'xp': 120,
    'level': 3,
    'streak_days': 5,
    'last_studied_on': '2026-09-01',
    'hearts': 4,
    'current_skill_node_id': 'node-1',
  },
};

void main() {
  test('GET /v1/me をTopNavigationStatusへ暫定値付きで変換する', () async {
    final repository = ApiTopNavigationRepository(
      HomeRemoteDataSource(
        _client((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/v1/me');
          return http.Response(jsonEncode(_meResponse), 200);
        }),
      ),
      fallbackExperienceProgress: 0.25,
      fallbackMaxHearts: 5,
    );

    final status = await repository.fetchStatus();
    expect(status.level, 3);
    expect(status.xp, 120);
    expect(status.hearts, 4);
    expect(status.maxHearts, 5);
    expect(status.experienceProgress, 0.25);
  });

  test('POST/PATCH /v1/me と GET /v1/me/stats をマッピングする', () async {
    final requests = <http.Request>[];
    final source = HomeRemoteDataSource(
      _client((request) async {
        requests.add(request);
        if (request.method == 'POST') {
          return http.Response(jsonEncode(_meResponse), 201);
        }
        if (request.method == 'PATCH') {
          return http.Response(jsonEncode(_meResponse['user']), 200);
        }
        return http.Response(
          jsonEncode({
            'stats': [
              {
                'question_type': 'code_reading',
                'language': 'typescript',
                'attempts': 42,
                'corrects': 35,
                'accuracy': 0.83,
                'last_difficulty': 3,
              },
            ],
          }),
          200,
        );
      }),
    );

    final provisioned = await source.provisionMe(
      displayName: '太郎',
      avatarUrl: 'https://example.com/a.png',
    );
    final updated = await source.updateMe(displayName: '次郎');
    final stats = await source.fetchStats();

    expect(provisioned.user?.userCode, 'taro');
    expect(updated.displayName, '太郎');
    expect(stats.stats.single.accuracy, 0.83);
    expect(jsonDecode(requests[0].body), {
      'display_name': '太郎',
      'avatar_url': 'https://example.com/a.png',
    });
    expect(jsonDecode(requests[1].body), {'display_name': '次郎'});
    expect(
      requests.map((request) => '${request.method} ${request.url.path}'),
      ['POST /v1/me', 'PATCH /v1/me', 'GET /v1/me/stats'],
    );
    expect(requests[2].url.path, '/v1/me/stats');
  });

  test('GET /v1/home をHomeDashboardへ変換する', () async {
    final repository = ApiHomeDashboardRepository(
      HomeRemoteDataSource(
        _client((request) async => http.Response(
              jsonEncode({
                'activity_date': '2026-09-02',
                'tasks': [
                  {
                    'id': 'daily-1',
                    'slot_no': 1,
                    'question_type': 'code_reading',
                    'language': 'typescript',
                    'difficulty': 2,
                    'question': {
                      'id': 'question-1',
                      'title': '配列メソッドの挙動',
                      'type': 'code_reading',
                      'difficulty': 2,
                    },
                    'completed_at': '2026-09-02T03:04:05Z',
                  },
                ],
                'progress': {
                  'xp': 120,
                  'level': 3,
                  'streak_days': 5,
                  'hearts': 4,
                },
              }),
              200,
            )),
      ),
    );

    final dashboard = await repository.fetchDashboard();
    expect(dashboard.streakDays, 5);
    expect(dashboard.taskProgress.completedTasks, 1);
    expect(dashboard.studyTasks.single.languages.single.name, 'typescript');
    expect(dashboard.monthlyProgress.studiedDays, 0);
    expect(dashboard.monthlyProgress.maxDays, 30);
  });

  test('エラーエンベロープをApiExceptionへ変換する', () async {
    final source = HomeRemoteDataSource(
      _client((request) async => http.Response(
            jsonEncode({
              'error': {
                'status': 404,
                'code': 'USER_NOT_FOUND',
                'message': 'ユーザーが見つかりません',
              },
            }),
            404,
          )),
    );

    expect(
      source.fetchMe,
      throwsA(
        isA<ApiException>().having((error) => error.code, 'code', 'USER_NOT_FOUND'),
      ),
    );
  });

  test('不正な2xxレスポンスをINVALID_RESPONSEへ変換する', () async {
    final source = HomeRemoteDataSource(
      _client((request) async => http.Response('[]', 200)),
    );
    expect(
      source.fetchMe,
      throwsA(
        isA<ApiException>().having(
          (error) => error.code,
          'code',
          ApiException.codeInvalidResponse,
        ),
      ),
    );
  });
}
