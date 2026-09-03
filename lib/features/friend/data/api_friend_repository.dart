import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../domain/friend_repository.dart';
import '../domain/friend_user.dart';
import 'friend_user_dto.dart';

/// バックエンド未実装のフレンドAPI暫定契約に基づく実装。
///
/// 公開範囲、ブロック、申請・解除後の保持期間が確定したら、
/// `docs/API_DESIGN.md` とこの境界を同時に更新する。
class ApiFriendRepository implements FriendRepository {
  const ApiFriendRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<FriendUser>> fetchUsers({required FriendFilter filter}) async {
    final users = <FriendUser>[];
    String? cursor;
    do {
      final json = expectJsonObject(
        await _client.get(
          '/v1/friends',
          query: {
            'relationship': _filterToApiValue(filter),
            'cursor': cursor,
          },
        ),
      );
      users.addAll(
        parseApiResponse(
          () => expectJsonObjectList(json, 'users')
              .map(FriendUserDto.fromJson)
              .map((user) => user.toDomain())
              .toList(growable: false),
        ),
      );
      cursor = parseApiResponse(() => json['next_cursor'] as String?);
    } while (cursor != null);
    return List.unmodifiable(users);
  }

  @override
  Future<FriendUser?> searchUserByCode(String userCode) async {
    final normalizedUserCode = userCode.trim();
    if (normalizedUserCode.isEmpty) return null;
    try {
      final json = expectJsonObject(
        await _client.get('/v1/users/by-code/$normalizedUserCode'),
      );
      final user = json['user'];
      return parseApiResponse(
        () => FriendUserDto.fromJson(
          user is Map<String, dynamic> ? user : json,
        ).toDomain(),
      );
    } on ApiException catch (error) {
      if (error.code == 'PUBLIC_USER_NOT_FOUND') return null;
      rethrow;
    }
  }

  @override
  Future<void> sendRequest(String userId) async {
    await _client.post(
      '/v1/friend-requests',
      body: {'target_user_id': userId},
    );
  }

  @override
  Future<void> cancelRequest(String userId) => _client
      .delete('/v1/friend-requests/$userId')
      .then((_) {});

  @override
  Future<void> acceptRequest(String userId) => _postAction(userId, 'accept');

  @override
  Future<void> declineRequest(String userId) => _postAction(userId, 'decline');

  @override
  Future<void> removeFriend(String userId) => _client
      .delete('/v1/friends/$userId')
      .then((_) {});

  Future<void> _postAction(String userId, String action) async {
    await _client.post(
      '/v1/friend-requests/$userId/$action',
    );
  }
}

String _filterToApiValue(FriendFilter filter) => switch (filter) {
  FriendFilter.friends => 'friend',
  FriendFilter.outgoing => 'outgoing_request',
  FriendFilter.incoming => 'incoming_request',
};
