import '../domain/home_dashboard.dart';
import '../domain/home_dashboard_repository.dart';
import 'home_remote_data_source.dart';

class ApiHomeDashboardRepository implements HomeDashboardRepository {
  const ApiHomeDashboardRepository(this._dataSource);

  final HomeRemoteDataSource _dataSource;

  @override
  Future<HomeDashboard> fetchDashboard() async =>
      (await _dataSource.fetchHome()).toDomain();
}
