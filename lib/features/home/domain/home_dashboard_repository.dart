import 'home_dashboard.dart';

abstract interface class HomeDashboardRepository {
  Future<HomeDashboard> fetchDashboard();
}
