class HomeStudyTask {
  const HomeStudyTask({
    this.id = '',
    this.name = '',
    this.taskNo,
    required this.languages,
  });

  final String id;
  final String name;
  final int? taskNo;
  final List<String> languages;
}

class HomeMonthlyProgress {
  const HomeMonthlyProgress({
    required this.studiedDays,
    required this.maxDays,
  });

  final int studiedDays;
  final int maxDays;
}

class HomeTaskProgress {
  const HomeTaskProgress({
    required this.completedTasks,
    required this.totalTasks,
  });

  final int completedTasks;
  final int totalTasks;
}

class HomeDashboard {
  const HomeDashboard({
    required this.activityDate,
    required this.streakDays,
    required this.studyTasks,
    required this.taskProgress,
    required this.monthlyProgress,
  });

  final DateTime activityDate;
  final int streakDays;
  final List<HomeStudyTask> studyTasks;
  final HomeTaskProgress taskProgress;
  final HomeMonthlyProgress monthlyProgress;
}
