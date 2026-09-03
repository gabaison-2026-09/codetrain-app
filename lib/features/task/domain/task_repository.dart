import 'task_configuration.dart';

abstract interface class TaskRepository {
  Future<TaskCatalog> fetchCatalog();

  Future<LearningTask> saveTask(LearningTask task);

  Future<void> deleteTask(String taskId);
}
