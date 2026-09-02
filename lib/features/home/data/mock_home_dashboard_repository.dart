import '../domain/home_dashboard.dart';
import '../domain/home_dashboard_repository.dart';

class MockHomeDashboardRepository implements HomeDashboardRepository {
  const MockHomeDashboardRepository();

  static HomeDashboard dashboardFor(DateTime now) {
    return HomeDashboard(
      activityDate: DateTime(now.year, now.month, now.day),
      streakDays: 18,
      dayStatuses: const [
        HomeDayStatus.active,
        HomeDayStatus.upcoming,
        HomeDayStatus.active,
        HomeDayStatus.active,
        HomeDayStatus.upcoming,
        HomeDayStatus.upcoming,
        HomeDayStatus.upcoming,
      ],
      highlightedDayIndex: 3,
      programs: const [
        HomeProgram.csharp,
        HomeProgram.typescript,
        HomeProgram.ruby,
      ],
    );
  }

  @override
  Future<HomeDashboard> fetchDashboard() async => dashboardFor(DateTime.now());
}
