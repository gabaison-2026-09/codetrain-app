import '../domain/learn_content.dart';
import '../domain/learn_repository.dart';
import 'learn_remote_data_source.dart';

class ApiLearnRepository implements LearnRepository {
  const ApiLearnRepository(this._dataSource);

  final LearnRemoteDataSource _dataSource;

  @override
  Future<LearnCatalog> fetchCatalog() async =>
      (await _dataSource.fetchSkills()).toDomain();

  @override
  Future<List<LearnQuestion>> fetchQuestionsForSkillNode(
    String skillNodeId,
  ) async {
    final ids = await _fetchAllQuestionIds(skillNodeId: skillNodeId);
    return _fetchDetails(ids);
  }

  @override
  Future<List<LearnQuestion>> fetchQuestionsForTask({
    required List<LearnQuestionFilter> filters,
  }) async {
    final ids = <String>{};
    for (final filter in filters) {
      ids.addAll(
        await _fetchAllQuestionIds(
          type: _questionTypeToApiValue(filter.type),
          language: filter.language.isEmpty ? null : filter.language,
          difficulty: filter.difficulty,
          unansweredOnly: true,
        ),
      );
    }
    return _fetchDetails(ids);
  }

  @override
  Future<LearnAttemptResult> submitAttempt({
    required String questionId,
    required List<String> selectedKeys,
    required int durationMs,
  }) async =>
      (await _dataSource.submitAttempt(
        questionId: questionId,
        selectedKeys: selectedKeys,
        durationMs: durationMs,
      )).toDomain();

  Future<List<LearnQuestion>> _fetchDetails(Iterable<String> ids) async =>
      Future.wait(
        ids.map(
          (id) async => (await _dataSource.fetchQuestion(id)).toDomain(),
        ),
      );

  Future<List<String>> _fetchAllQuestionIds({
    String? skillNodeId,
    String? type,
    String? language,
    int? difficulty,
    bool unansweredOnly = false,
  }) async {
    final ids = <String>[];
    String? cursor;
    do {
      final page = await _dataSource.fetchQuestions(
        skillNodeId: skillNodeId,
        type: type,
        language: language,
        difficulty: difficulty,
        unansweredOnly: unansweredOnly,
        cursor: cursor,
      );
      ids.addAll(page.items.map((question) => question.id));
      cursor = page.nextCursor;
    } while (cursor != null);
    return ids;
  }
}

String _questionTypeToApiValue(LearnQuestionType type) => switch (type) {
  LearnQuestionType.codeReading => 'code_reading',
  LearnQuestionType.outputPrediction => 'output_prediction',
};
