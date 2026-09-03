import '../domain/top_navigation_status.dart';

class MeResponseDto {
  const MeResponseDto({this.user, required this.progress});

  factory MeResponseDto.fromJson(Map<String, dynamic> json) {
    return MeResponseDto(
      user: json['user'] == null
          ? null
          : MeUserDto.fromJson(json['user'] as Map<String, dynamic>),
      progress: MeProgressDto.fromJson(
        json['progress'] as Map<String, dynamic>,
      ),
    );
  }

  final MeUserDto? user;
  final MeProgressDto progress;
}

class MeUserDto {
  const MeUserDto({
    required this.id,
    required this.externalId,
    required this.displayName,
    required this.email,
    required this.createdAt,
    this.userCode,
    this.avatarUrl,
  });

  factory MeUserDto.fromJson(Map<String, dynamic> json) {
    return MeUserDto(
      id: json['id'] as String,
      externalId: json['external_id'] as String,
      userCode: json['user_code'] as String?,
      displayName: json['display_name'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final String externalId;
  final String? userCode;
  final String displayName;
  final String email;
  final String? avatarUrl;
  final DateTime createdAt;
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

class MeStatsResponseDto {
  const MeStatsResponseDto({required this.stats});

  factory MeStatsResponseDto.fromJson(Map<String, dynamic> json) {
    return MeStatsResponseDto(
      stats: (json['stats'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(MeStatDto.fromJson)
          .toList(growable: false),
    );
  }

  final List<MeStatDto> stats;
}

class MeStatDto {
  const MeStatDto({
    required this.questionType,
    required this.language,
    required this.attempts,
    required this.corrects,
    required this.accuracy,
    required this.lastDifficulty,
  });

  factory MeStatDto.fromJson(Map<String, dynamic> json) {
    return MeStatDto(
      questionType: json['question_type'] as String,
      language: json['language'] as String,
      attempts: json['attempts'] as int,
      corrects: json['corrects'] as int,
      accuracy: (json['accuracy'] as num).toDouble(),
      lastDifficulty: json['last_difficulty'] as int,
    );
  }

  final String questionType;
  final String language;
  final int attempts;
  final int corrects;
  final double accuracy;
  final int lastDifficulty;
}
