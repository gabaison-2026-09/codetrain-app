import '../domain/top_navigation_status.dart';

class MeResponseDto {
  const MeResponseDto({required this.progress});

  factory MeResponseDto.fromJson(Map<String, dynamic> json) {
    return MeResponseDto(
      progress: MeProgressDto.fromJson(
        json['progress'] as Map<String, dynamic>,
      ),
    );
  }

  final MeProgressDto progress;
}

class MeProgressDto {
  const MeProgressDto({
    required this.xp,
    required this.level,
    required this.streakDays,
    required this.lastStudiedOn,
    required this.hearts,
    required this.currentSkillNodeId,
  });

  factory MeProgressDto.fromJson(Map<String, dynamic> json) {
    return MeProgressDto(
      xp: json['xp'] as int,
      level: json['level'] as int,
      streakDays: json['streak_days'] as int,
      lastStudiedOn: json['last_studied_on'] as String?,
      hearts: json['hearts'] as int,
      currentSkillNodeId: json['current_skill_node_id'] as String?,
    );
  }

  final int xp;
  final int level;
  final int streakDays;
  final String? lastStudiedOn;
  final int hearts;
  final String? currentSkillNodeId;

  TopNavigationStatus toTopNavigationStatus({
    required double experienceProgress,
    required int maxHearts,
  }) {
    return TopNavigationStatus(
      level: level,
      xp: xp,
      hearts: hearts,
      maxHearts: maxHearts,
      experienceProgress: experienceProgress,
    );
  }
}
