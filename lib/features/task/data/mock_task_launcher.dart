import '../domain/task_launcher.dart';

class MockTaskLauncher implements TaskLauncher {
  const MockTaskLauncher();

  @override
  Future<void> start(TaskLaunchTarget target) async {}
}
