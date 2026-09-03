import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../domain/calendar_activity.dart';
import '../domain/calendar_repository.dart';
import 'calendar_response_dto.dart';

class ApiCalendarRepository implements CalendarRepository {
  const ApiCalendarRepository(this._client);

  final ApiClient _client;

  @override
  Future<CalendarActivity> fetchActivity({
    required DateTime from,
    required DateTime to,
  }) async {
    final json = expectJsonObject(
      await _client.get(
        '/v1/calendar',
        query: {'from': _dateOnly(from), 'to': _dateOnly(to)},
      ),
    );
    return parseApiResponse(
      () => CalendarResponseDto.fromJson(json).toDomain(),
    );
  }
}

String _dateOnly(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
