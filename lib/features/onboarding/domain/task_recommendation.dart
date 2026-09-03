import '../../task/domain/task_configuration.dart';

enum CreationGoal {
  webService('web_service', 'Webサービス'),
  mobileApp('mobile_app', 'スマホアプリ'),
  game('game', 'ゲーム'),
  automation('automation', '業務自動化'),
  dataAnalysis('data_analysis', 'データ分析');

  const CreationGoal(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

enum LearningLanguage {
  typescript('typescript', 'TypeScript'),
  ruby('ruby', 'Ruby'),
  javascript('javascript', 'JavaScript'),
  csharp('csharp', 'C#');

  const LearningLanguage(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

enum LearningPurpose {
  firstDevelopment('first_development', 'はじめての開発'),
  work('work', '仕事で使う'),
  career('career', '転職・就職'),
  personalProject('personal_project', '個人開発'),
  review('review', '基礎の復習');

  const LearningPurpose(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

enum ProgrammingExperience {
  none('none', '未経験'),
  lessThanSixMonths('less_than_six_months', '半年未満'),
  sixMonthsToOneYear('six_months_to_one_year', '半年〜1年'),
  oneToThreeYears('one_to_three_years', '1〜3年'),
  overThreeYears('over_three_years', '3年以上');

  const ProgrammingExperience(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

class TaskRecommendationAnswers {
  const TaskRecommendationAnswers({
    required this.goal,
    required this.language,
    required this.purpose,
    required this.experience,
  });

  final CreationGoal goal;
  final LearningLanguage language;
  final LearningPurpose purpose;
  final ProgrammingExperience experience;
}

abstract interface class TaskRecommendationRepository {
  Future<LearningTask> recommend(TaskRecommendationAnswers answers);
}

class TaskRecommendationFailure implements Exception {
  const TaskRecommendationFailure();
}
