import '../domain/top_navigation_repository.dart';
import '../domain/top_navigation_status.dart';

class MockTopNavigationRepository implements TopNavigationRepository {
  const MockTopNavigationRepository();

  static const mockStatus = TopNavigationStatus(
    level: 12,
    experienceProgress: 0.62,
    filledHeartCount: 3,
    heartCount: 5,
  );

  @override
  Future<TopNavigationStatus> fetchStatus() async => mockStatus;
}
