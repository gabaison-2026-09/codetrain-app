import '../domain/home_dashboard.dart';
import '../domain/home_dashboard_repository.dart';

class MockHomeDashboardRepository implements HomeDashboardRepository {
  const MockHomeDashboardRepository();

  static HomeDashboard dashboardFor(DateTime now) {
    return HomeDashboard(
      activityDate: DateTime(now.year, now.month, now.day),
      streakDays: 18,
      dayStatuses: const [
        HomeDayStatus.completed,
        HomeDayStatus.missed,
        HomeDayStatus.completed,
        HomeDayStatus.active,
        HomeDayStatus.upcoming,
        HomeDayStatus.upcoming,
        HomeDayStatus.upcoming,
      ],
      highlightedDayIndex: 3,
      studyTasks: const [
        HomeStudyTask(
          languages: [
            HomeLanguage.csharp,
            HomeLanguage.typescript,
            HomeLanguage.ruby,
          ],
        ),
        HomeStudyTask(
          languages: [HomeLanguage.typescript, HomeLanguage.ruby],
        ),
        HomeStudyTask(
          languages: [HomeLanguage.csharp],
        ),
      ],
      recentXp: List.generate(
        30,
        (index) => HomeXpPoint(
          date: DateTime(now.year, now.month, now.day).subtract(
            Duration(days: 29 - index),
          ),
          xp: const [4, 8, 0, 11, 7, 12, 9, 6, 10, 3][index % 10],
        ),
      ),
    );
  }

  @override
  Future<HomeDashboard> fetchDashboard() async => dashboardFor(DateTime.now());
}
