import 'dart:convert';

import 'package:codetrain_app/core/env/app_config.dart';
import 'package:codetrain_app/core/network/api_client.dart';
import 'package:codetrain_app/core/network/api_exception.dart';
import 'package:codetrain_app/core/network/auth_header_provider.dart';
import 'package:codetrain_app/features/task/data/api_task_repository.dart';
import 'package:codetrain_app/features/task/data/task_remote_data_source.dart';
import 'package:codetrain_app/features/task/domain/task_configuration.dart';
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
  test('slotsとoptionsを単一の暫定LearningTaskへ変換する', () async {
    final repository = ApiTaskRepository(
      TaskRemoteDataSource(
        _client((request) async {
          if (request.url.path == '/v1/task-slots/options') {
            return http.Response(
              jsonEncode({
                'options': [
                  {
                    'question_type': 'code_reading',
                    'language': 'typescript',
                    'difficulty': 2,
                  },
                ],
              }),
              200,
            );
          }
          return http.Response(
            jsonEncode({
              'slots': [
                {
                  'slot_no': 1,
                  'question_type': 'code_reading',
                  'language': 'typescript',
                  'difficulty': null,
                },
              ],
            }),
            200,
          );
        }),
      ),
    );

    final catalog = await repository.fetchCatalog();
    expect(catalog.tasks.single.id, ApiTaskRepository.provisionalTaskId);
    expect(catalog.tasks.single.slots, hasLength(5));
    expect(catalog.tasks.single.slots.first.isConfigured, isTrue);
    expect(catalog.tasks.single.slots.last.isConfigured, isFalse);
    expect(catalog.options.single.difficulty, 2);
  });

  test('saveTaskがPUTとDELETEで5スロットを同期する', () async {
    final requests = <http.Request>[];
    final repository = ApiTaskRepository(
      TaskRemoteDataSource(
        _client((request) async {
          requests.add(request);
          if (request.method == 'GET') {
            return http.Response(
              jsonEncode({
                'slots': [
                  {
                    'slot_no': 2,
                    'question_type': 'output_prediction',
                    'language': '',
                    'difficulty': 3,
                  },
                ],
              }),
              200,
            );
          }
          if (request.method == 'PUT') {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            return http.Response(
              jsonEncode({
                'slot_no': 1,
                ...body,
              }),
              200,
            );
          }
          return http.Response('', 204);
        }),
      ),
    );

    final saved = await repository.saveTask(
      const LearningTask(
        id: '',
        name: 'ignored until API update',
        slots: [
          TaskSlot(
            slotNo: 1,
            questionType: TaskQuestionType.codeReading,
            language: 'typescript',
            difficulty: 2,
          ),
          TaskSlot(slotNo: 2),
        ],
      ),
    );

    expect(requests.map((request) => request.method), ['GET', 'PUT', 'DELETE']);
    expect(requests[1].url.path, '/v1/task-slots/1');
    expect(jsonDecode(requests[1].body), {
      'question_type': 'code_reading',
      'language': 'typescript',
      'difficulty': 2,
    });
    expect(requests[2].url.path, '/v1/task-slots/2');
    expect(saved.slots, hasLength(5));
  });

  test('deleteTaskが設定済みスロットだけをDELETEする', () async {
    final deleted = <String>[];
    final repository = ApiTaskRepository(
      TaskRemoteDataSource(
        _client((request) async {
          if (request.method == 'GET') {
            return http.Response(
              jsonEncode({
                'slots': [
                  {
                    'slot_no': 1,
                    'question_type': 'code_reading',
                    'language': 'ruby',
                    'difficulty': 1,
                  },
                  {
                    'slot_no': 3,
                    'question_type': 'code_reading',
                    'language': 'ruby',
                    'difficulty': 2,
                  },
                ],
              }),
              200,
            );
          }
          deleted.add(request.url.path);
          return http.Response('', 204);
        }),
      ),
    );

    await repository.deleteTask(ApiTaskRepository.provisionalTaskId);
    expect(deleted, ['/v1/task-slots/1', '/v1/task-slots/3']);
  });

  test('不正なslot optionをApiExceptionで通知する', () async {
    final source = TaskRemoteDataSource(
      _client((request) async => http.Response(
            jsonEncode({
              'error': {
                'status': 422,
                'code': 'TASK_SLOT_OPTION_INVALID',
                'message': '候補が不正です',
              },
            }),
            422,
          )),
    );

    expect(
      () => source.saveSlot(
        const TaskSlot(
          slotNo: 1,
          questionType: TaskQuestionType.codeReading,
          language: 'typescript',
        ),
      ),
      throwsA(
        isA<ApiException>().having(
          (error) => error.code,
          'code',
          'TASK_SLOT_OPTION_INVALID',
        ),
      ),
    );
  });
}
