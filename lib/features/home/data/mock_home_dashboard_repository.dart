import '../domain/home_dashboard.dart';
import '../domain/home_dashboard_repository.dart';

class MockHomeDashboardRepository implements HomeDashboardRepository {
  const MockHomeDashboardRepository();

  static HomeDashboard dashboardFor(DateTime now) {
    return HomeDashboard(
      activityDate: DateTime(now.year, now.month, now.day),
      streakDays: 18,
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
      taskProgress: const HomeTaskProgress(
        completedTasks: 3,
        totalTasks: 5,
      ),
      monthlyProgress: HomeMonthlyProgress(
        studiedDays: 16,
        maxDays: DateTime(now.year, now.month + 1, 0).day.clamp(1, 30).toInt(),
      ),
    );
  }

  @override
  Future<HomeDashboard> fetchDashboard() async => dashboardFor(DateTime.now());
}
