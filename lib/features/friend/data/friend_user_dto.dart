import '../domain/friend_user.dart';

class FriendUserDto {
  const FriendUserDto({
    required this.id,
    required this.userCode,
    required this.displayName,
    required this.relationship,
    required this.streakDays,
    this.avatarUrl,
  });

  factory FriendUserDto.fromJson(Map<String, Object?> json) {
    return FriendUserDto(
      id: json['id']! as String,
      userCode: json['user_code']! as String,
      displayName: json['display_name']! as String,
      avatarUrl: json['avatar_url'] as String?,
      relationship: json['relationship']! as String,
      streakDays: json['streak_days'] as int? ?? 0,
    );
  }

  final String id;
  final String userCode;
  final String displayName;
  final String? avatarUrl;
  final String relationship;
  final int streakDays;

  FriendUser toDomain() {
    return FriendUser(
      id: id,
      userCode: userCode,
      displayName: displayName,
      avatarUrl: avatarUrl,
      streakDays: streakDays,
      relationship: switch (relationship) {
        'friend' => FriendRelationship.friend,
        'outgoing_request' => FriendRelationship.outgoingRequest,
        'incoming_request' => FriendRelationship.incomingRequest,
        _ => FriendRelationship.none,
      },
    );
  }
}
