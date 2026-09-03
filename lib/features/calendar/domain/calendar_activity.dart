class CalendarActivity {
  const CalendarActivity({
    required this.days,
    required this.streakDays,
    required this.lastStudiedOn,
  });

  final List<CalendarDayActivity> days;
  final int streakDays;
  final DateTime? lastStudiedOn;
}

class CalendarDayActivity {
  const CalendarDayActivity({
    required this.date,
    required this.totalSlots,
    required this.completedSlots,
    required this.completed,
    this.tasks = const [],
  });

  final DateTime date;
  final int totalSlots;
  final int completedSlots;
  final bool completed;
  final List<CalendarTaskActivity> tasks;

  bool get studied => completedSlots > 0;
}

class CalendarTaskActivity {
  const CalendarTaskActivity({
    required this.id,
    required this.name,
    required this.totalQuestions,
    required this.completedQuestions,
    required this.contents,
  });

  final String id;
  final String name;
  final int totalQuestions;
  final int completedQuestions;
  final List<CalendarTaskContent> contents;
}

class CalendarTaskContent {
  const CalendarTaskContent({
    required this.questionType,
    required this.language,
    required this.difficulty,
    required this.questionCount,
  });

  final CalendarQuestionType questionType;
  final String language;
  final int? difficulty;
  final int questionCount;
}

enum CalendarQuestionType {
  codeReading,
  outputPrediction,
}
