import '../domain/calendar_activity.dart';
import '../domain/calendar_repository.dart';

class MockCalendarRepository implements CalendarRepository {
  const MockCalendarRepository();

  @override
  Future<CalendarActivity> fetchActivity({
    required DateTime from,
    required DateTime to,
  }) async {
    final monthLength = DateTime(from.year, from.month + 1, 0).day;
    const activityDays = <int>{
      2,
      3,
      5,
      8,
      9,
      12,
      13,
      14,
      17,
      18,
      19,
      20,
      21,
      22,
      25,
      27,
    };
    const partialDays = <int>{5, 12, 19, 25};
    return CalendarActivity(
      days: [
        for (final day in activityDays)
          if (day <= monthLength)
            CalendarDayActivity(
              date: DateTime(from.year, from.month, day),
              totalSlots: 3,
              completedSlots: partialDays.contains(day) ? 1 : 3,
              completed: !partialDays.contains(day),
              tasks: [
                CalendarTaskActivity(
                  id: 'task-typescript-basics',
                  name: 'TypeScript 基礎',
                  totalQuestions: 3,
                  completedQuestions: partialDays.contains(day) ? 1 : 3,
                  contents: const [
                    CalendarTaskContent(
                      questionType: CalendarQuestionType.codeReading,
                      language: 'typescript',
                      difficulty: 1,
                      questionCount: 2,
                    ),
                    CalendarTaskContent(
                      questionType: CalendarQuestionType.outputPrediction,
                      language: '',
                      difficulty: 2,
                      questionCount: 1,
                    ),
                  ],
                ),
              ],
            ),
      ],
      streakDays: 5,
      lastStudiedOn: DateTime(from.year, from.month, 27),
    );
  }
}
