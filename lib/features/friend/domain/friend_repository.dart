import 'friend_user.dart';

abstract interface class FriendRepository {
  Future<List<FriendUser>> fetchUsers({required FriendFilter filter});

  Future<FriendUser?> searchUserByCode(String userCode);

  Future<void> sendRequest(String userId);

  Future<void> cancelRequest(String userId);

  Future<void> acceptRequest(String userId);

  Future<void> declineRequest(String userId);

  Future<void> removeFriend(String userId);
}
