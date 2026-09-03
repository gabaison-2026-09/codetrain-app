import 'learn_content.dart';

abstract interface class LearnRepository {
  Future<LearnCatalog> fetchCatalog();

  Future<List<LearnQuestion>> fetchQuestionsForSkillNode(String skillNodeId);

  Future<List<LearnQuestion>> fetchQuestionsForTask({
    required List<LearnQuestionFilter> filters,
  });

  Future<LearnAttemptResult> submitAttempt({
    required String questionId,
    required List<String> selectedKeys,
    required int durationMs,
  });
}
