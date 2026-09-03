import 'calendar_activity.dart';

abstract interface class CalendarRepository {
  Future<CalendarActivity> fetchActivity({
    required DateTime from,
    required DateTime to,
  });
}
