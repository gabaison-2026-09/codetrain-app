import 'dart:convert';

import 'package:codetrain_app/core/env/app_config.dart';
import 'package:codetrain_app/core/network/api_client.dart';
import 'package:codetrain_app/core/network/api_exception.dart';
import 'package:codetrain_app/core/network/auth_header_provider.dart';
import 'package:codetrain_app/features/learn/data/api_learn_repository.dart';
import 'package:codetrain_app/features/learn/data/learn_remote_data_source.dart';
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

const _summary = <String, Object?>{
  'id': 'question-1',
  'type': 'code_reading',
  'difficulty': 2,
  'title': '配列メソッドの挙動',
  'code_language': 'typescript',
  'tags': ['array'],
  'skill_node_id': 'node-1',
  'answered': false,
};

const _detail = <String, Object?>{
  'id': 'question-1',
  'skill_node_id': 'node-1',
  'type': 'code_reading',
  'difficulty': 2,
  'title': '配列メソッドの挙動',
  'body': '正しいものを選べ',
  'code': 'const values = [1, 2];',
  'code_language': 'typescript',
  'choices': [
    {'key': 'a', 'text': '[1, 2]'},
    {'key': 'b', 'text': '[2, 4]'},
  ],
  'tags': ['array'],
  'answered': false,
  'correct_keys': null,
  'explanation': null,
};

void main() {
  test('skills、questions、detailを既存ドメインへマッピングする', () async {
    final source = LearnRemoteDataSource(
      _client((request) async {
        if (request.url.path == '/v1/skills') {
          return http.Response(
            jsonEncode({
              'skills': [
                {
                  'id': 'skill-1',
                  'slug': 'ts',
                  'name': 'TypeScript',
                  'description': '基礎',
                  'display_order': 1,
                  'nodes': [
                    {
                      'id': 'node-1',
                      'skill_id': 'skill-1',
                      'prerequisite_node_ids': <String>[],
                      'slug': 'arrays',
                      'name': '配列',
                      'difficulty': 2,
                      'display_order': 1,
                    },
                  ],
                },
              ],
            }),
            200,
          );
        }
        if (request.url.path == '/v1/questions') {
          expect(request.url.queryParameters['skill_node_id'], 'node-1');
          return http.Response(
            jsonEncode({'questions': [_summary], 'next_cursor': null}),
            200,
          );
        }
        return http.Response(jsonEncode(_detail), 200);
      }),
    );
    final repository = ApiLearnRepository(source);

    final catalog = await repository.fetchCatalog();
    final questions = await repository.fetchQuestionsForSkillNode('node-1');

    expect(catalog.skills.single.nodes.single.name, '配列');
    expect(questions.single.title, '配列メソッドの挙動');
    expect(questions.single.choices.last.key, 'b');
  });

  test('questionsの全検索条件、attempt、SRS dueを送受信する', () async {
    final requests = <http.Request>[];
    final source = LearnRemoteDataSource(
      _client((request) async {
        requests.add(request);
        if (request.url.path == '/v1/questions') {
          return http.Response(
            jsonEncode({'questions': [_summary], 'next_cursor': 'next'}),
            200,
          );
        }
        if (request.url.path.endsWith('/attempts')) {
          return http.Response(
            jsonEncode({
              'attempt_id': 'attempt-1',
              'is_correct': true,
              'correct_keys': ['b'],
              'explanation': 'mapの説明',
              'xp_gained': 10,
              'progress': {
                'xp': 130,
                'level': 3,
                'streak_days': 5,
                'last_studied_on': '2026-09-02',
                'hearts': 4,
                'current_skill_node_id': 'node-1',
              },
              'daily_task_completed': null,
            }),
            201,
          );
        }
        return http.Response(
          jsonEncode({
            'questions': [
              {..._summary, 'due_on': '2026-09-01'},
            ],
          }),
          200,
        );
      }),
    );

    final page = await source.fetchQuestions(
      skillNodeId: 'node-1',
      type: 'code_reading',
      language: 'typescript',
      difficulty: 2,
      tags: ['array', 'es2020'],
      searchQuery: '配列',
      unansweredOnly: true,
      cursor: 'cursor-1',
      limit: 20,
    );
    final attempt = await source.submitAttempt(
      questionId: 'question-1',
      selectedKeys: ['b'],
      durationMs: 8200,
    );
    final due = await source.fetchDueQuestions(limit: 10);

    expect(page.nextCursor, 'next');
    expect(requests[0].url.queryParametersAll['tag'], ['array', 'es2020']);
    expect(jsonDecode(requests[1].body), {
      'selected_keys': ['b'],
      'duration_ms': 8200,
    });
    expect(attempt.toDomain().xpGained, 10);
    expect(due.single.dueOn, DateTime(2026, 9, 1));
    expect(requests[2].url.path, '/v1/srs/due');
  });

  test('問題取得エラーをApiExceptionの業務コードで通知する', () async {
    final source = LearnRemoteDataSource(
      _client((request) async => http.Response(
            jsonEncode({
              'error': {
                'status': 404,
                'code': 'QUESTION_NOT_FOUND',
                'message': '問題が見つかりません',
              },
            }),
            404,
          )),
    );

    expect(
      () => source.fetchQuestion('missing'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.code,
          'code',
          'QUESTION_NOT_FOUND',
        ),
      ),
    );
  });
}
