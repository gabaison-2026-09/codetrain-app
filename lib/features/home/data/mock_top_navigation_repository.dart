import '../domain/top_navigation_repository.dart';
import '../domain/top_navigation_status.dart';
import 'me_response_dto.dart';

class MockTopNavigationRepository implements TopNavigationRepository {
  const MockTopNavigationRepository();

  static const mockResponse = MeResponseDto(
    progress: MeProgressDto(
      xp: 120,
      level: 12,
      streakDays: 5,
      lastStudiedOn: '2026-09-01',
      hearts: 3,
      currentSkillNodeId: null,
    ),
  );

  static const mockExperienceProgress = 0.62;
  static const mockMaxHearts = 5;

  static TopNavigationStatus get mockStatus =>
      mockResponse.progress.toTopNavigationStatus(
        experienceProgress: mockExperienceProgress,
        maxHearts: mockMaxHearts,
      );

  @override
  Future<TopNavigationStatus> fetchStatus() async => mockStatus;
}
