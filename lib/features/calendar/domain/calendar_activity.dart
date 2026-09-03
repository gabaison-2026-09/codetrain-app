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
  });

  final DateTime date;
  final int totalSlots;
  final int completedSlots;
  final bool completed;

  bool get studied => completedSlots > 0;
}
