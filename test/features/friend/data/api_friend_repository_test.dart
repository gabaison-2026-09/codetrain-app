import 'dart:convert';

import 'package:codetrain_app/core/env/app_config.dart';
import 'package:codetrain_app/core/network/api_client.dart';
import 'package:codetrain_app/core/network/api_exception.dart';
import 'package:codetrain_app/core/network/auth_header_provider.dart';
import 'package:codetrain_app/features/friend/data/api_friend_repository.dart';
import 'package:codetrain_app/features/friend/domain/friend_user.dart';
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

const _user = <String, Object?>{
  'id': 'user-1',
  'user_code': 'sora_js',
  'display_name': 'Sora',
  'avatar_url': 'https://example.com/sora.png',
  'relationship': 'friend',
  'streak_days': 7,
};

void main() {
  test('検索と関係別一覧をFriendUserへ変換する', () async {
    final repository = ApiFriendRepository(
      _client((request) async {
        if (request.url.path == '/v1/friends') {
          expect(request.url.queryParameters['relationship'], 'friend');
          return http.Response(
            jsonEncode({'users': [_user], 'next_cursor': null}),
            200,
          );
        }
        expect(request.url.path, '/v1/users/by-code/sora_js');
        return http.Response(jsonEncode({'user': _user}), 200);
      }),
    );

    final friends = await repository.fetchUsers(filter: FriendFilter.friends);
    final found = await repository.searchUserByCode('sora_js');
    expect(friends.single.relationship, FriendRelationship.friend);
    expect(friends.single.streakDays, 7);
    expect(found?.userCode, 'sora_js');
  });

  test('全フレンド操作が暫定契約のmethod/path/bodyを使う', () async {
    final requests = <http.Request>[];
    final repository = ApiFriendRepository(
      _client((request) async {
        requests.add(request);
        return http.Response('', request.method == 'DELETE' ? 204 : 201);
      }),
    );

    await repository.sendRequest('user-2');
    await repository.cancelRequest('user-2');
    await repository.acceptRequest('user-2');
    await repository.declineRequest('user-2');
    await repository.removeFriend('user-2');

    expect(
      requests.map((request) => '${request.method} ${request.url.path}'),
      [
        'POST /v1/friend-requests',
        'DELETE /v1/friend-requests/user-2',
        'POST /v1/friend-requests/user-2/accept',
        'POST /v1/friend-requests/user-2/decline',
        'DELETE /v1/friends/user-2',
      ],
    );
    expect(jsonDecode(requests.first.body), {'target_user_id': 'user-2'});
  });

  test('PUBLIC_USER_NOT_FOUNDだけを検索結果なしへ変換する', () async {
    final repository = ApiFriendRepository(
      _client((request) async => http.Response(
            jsonEncode({
              'error': {
                'status': 404,
                'code': 'PUBLIC_USER_NOT_FOUND',
                'message': 'ユーザーが見つかりません',
              },
            }),
            404,
          )),
    );
    expect(await repository.searchUserByCode('missing'), isNull);
  });

  test('フレンド操作の業務エラーはApiExceptionのまま通知する', () async {
    final repository = ApiFriendRepository(
      _client((request) async => http.Response(
            jsonEncode({
              'error': {
                'status': 409,
                'code': 'FRIEND_REQUEST_CONFLICT',
                'message': '申請が競合しています',
              },
            }),
            409,
          )),
    );
    expect(
      () => repository.sendRequest('user-2'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.code,
          'code',
          'FRIEND_REQUEST_CONFLICT',
        ),
      ),
    );
  });
}
