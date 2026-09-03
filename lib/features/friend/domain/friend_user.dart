enum FriendFilter { friends, outgoing, incoming }

enum FriendRelationship { none, friend, outgoingRequest, incomingRequest }

class FriendUser {
  const FriendUser({
    required this.id,
    required this.userCode,
    required this.displayName,
    required this.relationship,
    required this.streakDays,
    this.avatarUrl,
  });

  final String id;
  final String userCode;
  final String displayName;
  final String? avatarUrl;
  final FriendRelationship relationship;
  final int streakDays;

  FriendUser copyWith({FriendRelationship? relationship, int? streakDays}) {
    return FriendUser(
      id: id,
      userCode: userCode,
      displayName: displayName,
      avatarUrl: avatarUrl,
      relationship: relationship ?? this.relationship,
      streakDays: streakDays ?? this.streakDays,
    );
  }
}
