abstract interface class TaskLauncher {
  Future<void> start(TaskLaunchTarget target);
}

class TaskLaunchTarget {
  const TaskLaunchTarget({
    required this.name,
    this.taskId = '',
    this.taskNo,
  });

  final String name;
  final String taskId;
  final int? taskNo;
}
