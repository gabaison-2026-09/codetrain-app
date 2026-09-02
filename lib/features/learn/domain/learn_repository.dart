import 'learn_content.dart';

abstract interface class LearnRepository {
  Future<LearnCatalog> fetchCatalog();

  Future<List<LearnQuestion>> fetchQuestionsForSkillNode(String skillNodeId);

  Future<LearnAttemptResult> submitAttempt({
    required String questionId,
    required List<String> selectedKeys,
    required int durationMs,
  });
}
