enum HomeLanguage { csharp, typescript, ruby }

class HomeStudyTask {
  const HomeStudyTask({required this.languages});

  final List<HomeLanguage> languages;
}

class HomeMonthlyProgress {
  const HomeMonthlyProgress({
    required this.studiedDays,
    required this.maxDays,
  });

  final int studiedDays;
  final int maxDays;
}

class HomeDashboard {
  const HomeDashboard({
    required this.activityDate,
    required this.streakDays,
    required this.studyTasks,
    required this.monthlyProgress,
  });

  final DateTime activityDate;
  final int streakDays;
  final List<HomeStudyTask> studyTasks;
  final HomeMonthlyProgress monthlyProgress;
}
