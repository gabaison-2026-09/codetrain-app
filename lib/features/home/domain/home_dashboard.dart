enum HomeDayStatus { completed, missed, active, upcoming }

enum HomeLanguage { csharp, typescript, ruby }

class HomeStudyTask {
  const HomeStudyTask({required this.languages});

  final List<HomeLanguage> languages;
}

class HomeXpPoint {
  const HomeXpPoint({required this.date, required this.xp});

  final DateTime date;
  final int xp;
}

class HomeDashboard {
  const HomeDashboard({
    required this.activityDate,
    required this.streakDays,
    required this.dayStatuses,
    required this.studyTasks,
    required this.recentXp,
    this.highlightedDayIndex = 3,
  });

  final DateTime activityDate;
  final int streakDays;
  final List<HomeDayStatus> dayStatuses;
  final List<HomeStudyTask> studyTasks;
  final List<HomeXpPoint> recentXp;
  final int highlightedDayIndex;
}
