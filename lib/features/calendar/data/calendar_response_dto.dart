import '../domain/calendar_activity.dart';

class CalendarResponseDto {
  const CalendarResponseDto({
    required this.days,
    required this.streakDays,
    required this.lastStudiedOn,
  });

  factory CalendarResponseDto.fromJson(Map<String, dynamic> json) {
    return CalendarResponseDto(
      days: (json['days'] as List<dynamic>)
          .map(
            (day) => CalendarDayActivityDto.fromJson(
              day as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
      streakDays: json['streak_days'] as int,
      lastStudiedOn: json['last_studied_on'] as String?,
    );
  }

  final List<CalendarDayActivityDto> days;
  final int streakDays;
  final String? lastStudiedOn;

  CalendarActivity toDomain() => CalendarActivity(
    days: days.map((day) => day.toDomain()).toList(growable: false),
    streakDays: streakDays,
    lastStudiedOn: lastStudiedOn == null
        ? null
        : DateTime.parse(lastStudiedOn!),
  );
}

class CalendarDayActivityDto {
  const CalendarDayActivityDto({
    required this.date,
    required this.totalSlots,
    required this.completedSlots,
    required this.completed,
    required this.tasks,
  });

  factory CalendarDayActivityDto.fromJson(Map<String, dynamic> json) {
    return CalendarDayActivityDto(
      date: json['date'] as String,
      totalSlots: json['total_slots'] as int,
      completedSlots: json['completed_slots'] as int,
      completed: json['completed'] as bool,
      tasks: (json['tasks'] as List<dynamic>? ?? const [])
          .map(
            (task) => CalendarTaskActivityDto.fromJson(
              task as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
    );
  }

  final String date;
  final int totalSlots;
  final int completedSlots;
  final bool completed;
  final List<CalendarTaskActivityDto> tasks;

  CalendarDayActivity toDomain() => CalendarDayActivity(
    date: DateTime.parse(date),
    totalSlots: totalSlots,
    completedSlots: completedSlots,
    completed: completed,
    tasks: tasks.map((task) => task.toDomain()).toList(growable: false),
  );
}

class CalendarTaskActivityDto {
  const CalendarTaskActivityDto({
    required this.id,
    required this.name,
    required this.totalQuestions,
    required this.completedQuestions,
    required this.contents,
  });

  factory CalendarTaskActivityDto.fromJson(Map<String, dynamic> json) {
    return CalendarTaskActivityDto(
      id: json['task_id'] as String,
      name: json['name'] as String,
      totalQuestions: json['total_questions'] as int,
      completedQuestions: json['completed_questions'] as int,
      contents: (json['contents'] as List<dynamic>)
          .map(
            (content) => CalendarTaskContentDto.fromJson(
              content as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
    );
  }

  final String id;
  final String name;
  final int totalQuestions;
  final int completedQuestions;
  final List<CalendarTaskContentDto> contents;

  CalendarTaskActivity toDomain() => CalendarTaskActivity(
    id: id,
    name: name,
    totalQuestions: totalQuestions,
    completedQuestions: completedQuestions,
    contents: contents.map((content) => content.toDomain()).toList(
      growable: false,
    ),
  );
}

class CalendarTaskContentDto {
  const CalendarTaskContentDto({
    required this.questionType,
    required this.language,
    required this.difficulty,
    required this.questionCount,
  });

  factory CalendarTaskContentDto.fromJson(Map<String, dynamic> json) {
    return CalendarTaskContentDto(
      questionType: json['question_type'] as String,
      language: json['language'] as String,
      difficulty: json['difficulty'] as int?,
      questionCount: json['question_count'] as int,
    );
  }

  final String questionType;
  final String language;
  final int? difficulty;
  final int questionCount;

  CalendarTaskContent toDomain() => CalendarTaskContent(
    questionType: switch (questionType) {
      'code_reading' => CalendarQuestionType.codeReading,
      'output_prediction' => CalendarQuestionType.outputPrediction,
      _ => throw FormatException('Unsupported question type: $questionType'),
    },
    language: language,
    difficulty: difficulty,
    questionCount: questionCount,
  );
}
