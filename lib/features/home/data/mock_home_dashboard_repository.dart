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
    );
  }

  @override
  Future<HomeDashboard> fetchDashboard() async => dashboardFor(DateTime.now());
}
