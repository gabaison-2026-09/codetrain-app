import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/paginated_response.dart';
import 'learn_response_dto.dart';

class LearnRemoteDataSource {
  const LearnRemoteDataSource(this._client);

  final ApiClient _client;

  Future<LearnSkillsResponseDto> fetchSkills() async {
    final json = expectJsonObject(await _client.get('/v1/skills'));
    return parseApiResponse(() => LearnSkillsResponseDto.fromJson(json));
  }

  Future<PaginatedResponse<LearnQuestionSummaryDto>> fetchQuestions({
    String? skillNodeId,
    String? type,
    String? language,
    int? difficulty,
    List<String> tags = const [],
    String? searchQuery,
    bool unansweredOnly = false,
    String? cursor,
    int? limit,
  }) async {
    final json = expectJsonObject(
      await _client.get(
        '/v1/questions',
        query: {
          'skill_node_id': skillNodeId,
          'type': type,
          'language': language,
          'difficulty': difficulty,
          if (tags.isNotEmpty) 'tag': tags,
          'q': searchQuery,
          if (unansweredOnly) 'unanswered_only': true,
          'cursor': cursor,
          'limit': limit,
        },
      ),
    );
    return parseApiResponse(() {
      final questions = expectJsonObjectList(json, 'questions')
          .map(LearnQuestionSummaryDto.fromJson)
          .toList(growable: false);
      return PaginatedResponse(
        items: questions,
        nextCursor: json['next_cursor'] as String?,
      );
    });
  }

  Future<LearnQuestionDetailDto> fetchQuestion(String questionId) async {
    final json = expectJsonObject(
      await _client.get('/v1/questions/$questionId'),
    );
    return parseApiResponse(() => LearnQuestionDetailDto.fromJson(json));
  }

  Future<LearnAttemptResponseDto> submitAttempt({
    required String questionId,
    required List<String> selectedKeys,
    required int durationMs,
  }) async {
    final json = expectJsonObject(
      await _client.post(
        '/v1/questions/$questionId/attempts',
        body: {'selected_keys': selectedKeys, 'duration_ms': durationMs},
      ),
    );
    return parseApiResponse(() => LearnAttemptResponseDto.fromJson(json));
  }

  Future<List<LearnDueQuestionDto>> fetchDueQuestions({int? limit}) async {
    final json = expectJsonObject(
      await _client.get('/v1/srs/due', query: {'limit': limit}),
    );
    return parseApiResponse(
      () => expectJsonObjectList(json, 'questions')
          .map(LearnDueQuestionDto.fromJson)
          .toList(growable: false),
    );
  }
}
