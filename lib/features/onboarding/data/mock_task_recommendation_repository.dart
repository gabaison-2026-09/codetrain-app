import '../../task/domain/task_configuration.dart';
import '../domain/task_recommendation.dart';
import 'task_recommendation_dto.dart';

class MockTaskRecommendationRepository
    implements TaskRecommendationRepository {
  const MockTaskRecommendationRepository();

  @override
  Future<LearningTask> recommend(TaskRecommendationAnswers answers) async {
    final experienceDifficulty = switch (answers.experience) {
      ProgrammingExperience.none => 1,
      ProgrammingExperience.lessThanSixMonths => 1,
      ProgrammingExperience.sixMonthsToOneYear => 2,
      ProgrammingExperience.oneToThreeYears => 3,
      ProgrammingExperience.overThreeYears => 4,
    };
    final difficulty = answers.purpose == LearningPurpose.review &&
            experienceDifficulty < 5
        ? experienceDifficulty + 1
        : experienceDifficulty;
    final readingCount = answers.purpose == LearningPurpose.review
        ? 4
        : switch (answers.goal) {
            CreationGoal.mobileApp => 2,
            CreationGoal.game => 2,
            CreationGoal.webService => 3,
            CreationGoal.automation => 3,
            CreationGoal.dataAnalysis => 3,
          };

    final response = <String, Object?>{
      'task': <String, Object?>{
        'name': '${answers.language.label} ${answers.goal.label}',
        'is_home_task': true,
        'slots': <Object?>[
          for (var index = 0; index < 5; index++)
            <String, Object?>{
              'slot_no': index + 1,
              'question_type': index < readingCount
                  ? 'code_reading'
                  : 'output_prediction',
              'language': index < readingCount
                  ? answers.language.apiValue
                  : '',
              'minimum_difficulty': difficulty,
              'maximum_difficulty': difficulty == 5 ? 5 : difficulty + 1,
            },
        ],
      },
    };
    return TaskRecommendationResponseDto.fromJson(response).toDomain();
  }
}
