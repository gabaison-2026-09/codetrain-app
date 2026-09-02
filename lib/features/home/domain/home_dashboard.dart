enum HomeDayStatus { completed, missed, active, upcoming }

enum HomeProgram { csharp, typescript, ruby }

class HomeDashboard {
  const HomeDashboard({
    required this.activityDate,
    required this.streakDays,
    required this.dayStatuses,
    required this.programs,
    this.highlightedDayIndex = 3,
  });

  final DateTime activityDate;
  final int streakDays;
  final List<HomeDayStatus> dayStatuses;
  final List<HomeProgram> programs;
  final int highlightedDayIndex;
}
