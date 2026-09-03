import '../domain/home_dashboard.dart';

class HomeResponseDto {
  const HomeResponseDto({
    required this.activityDate,
    required this.tasks,
    required this.progress,
    required this.monthlyProgress,
    required this.studyTasks,
  });

  factory HomeResponseDto.fromJson(Map<String, dynamic> json) {
    final activityDate = json['activity_date'] as String;
    return HomeResponseDto(
      activityDate: activityDate,
      tasks: (json['tasks'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(HomeDailyTaskDto.fromJson)
          .toList(growable: false),
      progress: HomeProgressDto.fromJson(
        json['progress'] as Map<String, dynamic>,
      ),
      // Document/API_DESIGN.md の基本契約には月間進捗がないため、
      // フィールドが追加されるまでは0日と暦月上限を変換境界で補う。
      monthlyProgress: json['monthly_progress'] == null
          ? HomeMonthlyProgressDto.fallbackFor(activityDate)
          : HomeMonthlyProgressDto.fromJson(
              json['monthly_progress'] as Map<String, dynamic>,
            ),
      studyTasks: (json['study_tasks'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(HomeStudyTaskDto.fromJson)
          .toList(growable: false),
    );
  }

  final String activityDate;
  final List<HomeDailyTaskDto> tasks;
  final HomeProgressDto progress;
  final HomeMonthlyProgressDto monthlyProgress;
  final List<HomeStudyTaskDto> studyTasks;

  HomeDashboard toDomain() {
    final completedTasks = tasks
        .where((task) => task.completedAt != null)
        .length;
    final mappedStudyTasks = studyTasks.isNotEmpty
        ? studyTasks.map((task) => task.toDomain()).toList(growable: false)
        : tasks.map((task) => task.toStudyTask()).toList(growable: false);
    return HomeDashboard(
      activityDate: DateTime.parse(activityDate),
      streakDays: progress.streakDays,
      studyTasks: mappedStudyTasks,
      taskProgress: HomeTaskProgress(
        completedTasks: completedTasks,
        totalTasks: tasks.length,
      ),
      monthlyProgress: monthlyProgress.toDomain(),
    );
  }
}

class HomeDailyTaskDto {
  const HomeDailyTaskDto({
    required this.id,
    required this.slotNo,
    required this.language,
    required this.title,
    required this.completedAt,
  });

  factory HomeDailyTaskDto.fromJson(Map<String, dynamic> json) {
    final question = json['question'] as Map<String, dynamic>;
    return HomeDailyTaskDto(
      id: json['id'] as String,
      slotNo: json['slot_no'] as int,
      language: json['language'] as String? ?? '',
      title: question['title'] as String,
      completedAt: json['completed_at'] as String?,
    );
  }

  final String id;
  final int slotNo;
  final String language;
  final String title;
  final String? completedAt;

  HomeStudyTask toStudyTask() => HomeStudyTask(
    id: id,
    name: title,
    taskNo: slotNo,
    languages: [_homeLanguageFromApiValue(language)]
        .whereType<HomeLanguage>()
        .toList(growable: false),
  );
}

class HomeProgressDto {
  const HomeProgressDto({required this.streakDays});

  factory HomeProgressDto.fromJson(Map<String, dynamic> json) =>
      HomeProgressDto(streakDays: json['streak_days'] as int);

  final int streakDays;
}

class HomeMonthlyProgressDto {
  const HomeMonthlyProgressDto({
    required this.studiedDays,
    required this.maxDays,
  });

  factory HomeMonthlyProgressDto.fromJson(Map<String, dynamic> json) =>
      HomeMonthlyProgressDto(
        studiedDays: json['studied_days'] as int,
        maxDays: json['max_days'] as int,
      );

  factory HomeMonthlyProgressDto.fallbackFor(String activityDate) {
    final date = DateTime.parse(activityDate);
    return HomeMonthlyProgressDto(
      studiedDays: 0,
      maxDays: DateTime(date.year, date.month + 1, 0).day.clamp(1, 30).toInt(),
    );
  }

  final int studiedDays;
  final int maxDays;

  HomeMonthlyProgress toDomain() =>
      HomeMonthlyProgress(studiedDays: studiedDays, maxDays: maxDays);
}

class HomeStudyTaskDto {
  const HomeStudyTaskDto({
    required this.id,
    required this.name,
    required this.taskNo,
    required this.languages,
  });

  factory HomeStudyTaskDto.fromJson(Map<String, dynamic> json) =>
      HomeStudyTaskDto(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        taskNo: json['task_no'] as int?,
        languages: (json['languages'] as List<dynamic>? ?? const [])
            .cast<String>(),
      );

  final String id;
  final String name;
  final int? taskNo;
  final List<String> languages;

  HomeStudyTask toDomain() => HomeStudyTask(
    id: id,
    name: name,
    taskNo: taskNo,
    languages: languages
        .map(_homeLanguageFromApiValue)
        .whereType<HomeLanguage>()
        .toList(growable: false),
  );
}

HomeLanguage? _homeLanguageFromApiValue(String value) => switch (value) {
  'csharp' => HomeLanguage.csharp,
  'typescript' => HomeLanguage.typescript,
  'ruby' => HomeLanguage.ruby,
  _ => null,
};
