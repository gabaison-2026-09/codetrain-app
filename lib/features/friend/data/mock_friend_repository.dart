import '../domain/friend_repository.dart';
import '../domain/friend_user.dart';
import 'friend_user_dto.dart';

class MockFriendRepository implements FriendRepository {
  MockFriendRepository()
      : _users = _response
            .map(FriendUserDto.fromJson)
            .map((user) => user.toDomain())
            .toList();

  static const _response = <Map<String, Object?>>[
    {
      'id': 'user-aoi',
      'user_code': 'aoi_dev',
      'display_name': 'あおい',
      'relationship': 'friend',
      'streak_days': 18,
    },
    {
      'id': 'user-ren',
      'user_code': 'ren_codes',
      'display_name': 'Ren',
      'relationship': 'friend',
      'streak_days': 7,
    },
    {
      'id': 'user-mio',
      'user_code': 'mio_works',
      'display_name': 'みお',
      'relationship': 'outgoing_request',
    },
    {
      'id': 'user-sora',
      'user_code': 'sora_js',
      'display_name': 'Sora',
      'relationship': 'incoming_request',
    },
    {
      'id': 'user-yui',
      'user_code': 'yui_flutter',
      'display_name': 'ゆい',
      'relationship': 'incoming_request',
    },
    {
      'id': 'user-kai',
      'user_code': 'kai_backend',
      'display_name': 'Kai',
      'relationship': 'none',
    },
    {
      'id': 'user-haru',
      'user_code': 'haru_ruby',
      'display_name': 'はる',
      'relationship': 'none',
    },
  ];

  final List<FriendUser> _users;

  @override
  Future<List<FriendUser>> fetchUsers({required FriendFilter filter}) async {
    final users = _users.where((user) => switch (filter) {
          FriendFilter.friends =>
            user.relationship == FriendRelationship.friend,
          FriendFilter.outgoing =>
            user.relationship == FriendRelationship.outgoingRequest,
          FriendFilter.incoming =>
            user.relationship == FriendRelationship.incomingRequest,
        });
    return List.unmodifiable(users);
  }

  @override
  Future<FriendUser?> searchUserByCode(String userCode) async {
    final targetCode = userCode.trim();
    if (targetCode.isEmpty) return null;
    for (final user in _users) {
      if (user.userCode == targetCode) return user;
    }
    return null;
  }

  @override
  Future<void> sendRequest(String userId) async {
    _transition(
      userId,
      from: FriendRelationship.none,
      to: FriendRelationship.outgoingRequest,
    );
  }

  @override
  Future<void> cancelRequest(String userId) async {
    _transition(
      userId,
      from: FriendRelationship.outgoingRequest,
      to: FriendRelationship.none,
    );
  }

  @override
  Future<void> acceptRequest(String userId) async {
    _transition(
      userId,
      from: FriendRelationship.incomingRequest,
      to: FriendRelationship.friend,
      streakDays: 4,
    );
  }

  @override
  Future<void> declineRequest(String userId) async {
    _transition(
      userId,
      from: FriendRelationship.incomingRequest,
      to: FriendRelationship.none,
    );
  }

  @override
  Future<void> removeFriend(String userId) async {
    _transition(
      userId,
      from: FriendRelationship.friend,
      to: FriendRelationship.none,
      streakDays: 0,
    );
  }

  void _transition(
    String userId, {
    required FriendRelationship from,
    required FriendRelationship to,
    int? streakDays,
  }) {
    final index = _users.indexWhere((user) => user.id == userId);
    if (index == -1 || _users[index].relationship != from) {
      throw StateError('Invalid friend relationship transition');
    }
    _users[index] = _users[index].copyWith(
      relationship: to,
      streakDays: streakDays,
    );
  }
}
