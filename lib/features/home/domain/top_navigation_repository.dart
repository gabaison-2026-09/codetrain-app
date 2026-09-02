import 'top_navigation_status.dart';

abstract interface class TopNavigationRepository {
  Future<TopNavigationStatus> fetchStatus();
}
