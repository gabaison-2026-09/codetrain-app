import '../domain/top_navigation_repository.dart';
import '../domain/top_navigation_status.dart';
import 'home_remote_data_source.dart';

class ApiTopNavigationRepository implements TopNavigationRepository {
  const ApiTopNavigationRepository(
    this._dataSource, {
    this.fallbackExperienceProgress = 0,
    this.fallbackMaxHearts = 5,
  });

  final HomeRemoteDataSource _dataSource;

  /// API設計に `experience_progress` が追加されるまで使用する暫定値。
  final double fallbackExperienceProgress;

  /// API設計に `max_hearts` が追加されるまで使用する暫定値。
  final int fallbackMaxHearts;

  @override
  Future<TopNavigationStatus> fetchStatus() async {
    final response = await _dataSource.fetchMe();
    return response.progress.toTopNavigationStatus(
      experienceProgress: fallbackExperienceProgress,
      maxHearts: fallbackMaxHearts,
    );
  }
}
