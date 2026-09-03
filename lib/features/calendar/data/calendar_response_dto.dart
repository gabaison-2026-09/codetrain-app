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
  });

  factory CalendarDayActivityDto.fromJson(Map<String, dynamic> json) {
    return CalendarDayActivityDto(
      date: json['date'] as String,
      totalSlots: json['total_slots'] as int,
      completedSlots: json['completed_slots'] as int,
      completed: json['completed'] as bool,
    );
  }

  final String date;
  final int totalSlots;
  final int completedSlots;
  final bool completed;

  CalendarDayActivity toDomain() => CalendarDayActivity(
    date: DateTime.parse(date),
    totalSlots: totalSlots,
    completedSlots: completedSlots,
    completed: completed,
  );
}
