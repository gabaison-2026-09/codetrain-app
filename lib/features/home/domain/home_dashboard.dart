enum HomeDayStatus { completed, missed, active, upcoming }

enum HomeLanguage { csharp, typescript, ruby }

class HomeStudyTask {
  const HomeStudyTask({required this.languages});

  final List<HomeLanguage> languages;
}

class HomeDashboard {
  const HomeDashboard({
    required this.activityDate,
    required this.streakDays,
    required this.dayStatuses,
    required this.studyTasks,
    this.highlightedDayIndex = 3,
  });

  final DateTime activityDate;
  final int streakDays;
  final List<HomeDayStatus> dayStatuses;
  final List<HomeStudyTask> studyTasks;
  final int highlightedDayIndex;
}
