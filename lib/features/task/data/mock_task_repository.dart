import '../domain/task_configuration.dart';
import '../domain/task_repository.dart';
import 'task_slots_response_dto.dart';

class MockTaskRepository implements TaskRepository {
  MockTaskRepository()
      : _tasks = _taskResponse
            .map(LearningTaskDto.fromJson)
            .map((task) => task.toDomain())
            .toList(),
        _options = _optionResponse
            .map(TaskOptionDto.fromJson)
            .map((option) => option.toDomain())
            .toList();

  static const _taskResponse = <Map<String, Object?>>[
    {
      'id': 'task-typescript-basics',
      'name': 'TypeScript 基礎',
      'is_home_task': true,
      'slots': [
        {'slot_no': 1, 'question_type': 'code_reading', 'language': 'typescript', 'difficulty': null},
        {'slot_no': 2, 'question_type': 'output_prediction', 'language': '', 'difficulty': 2},
        {'slot_no': 3, 'question_type': 'code_reading', 'language': 'typescript', 'difficulty': 2},
        {'slot_no': 4},
        {'slot_no': 5},
      ],
    },
    {
      'id': 'task-ruby-reading',
      'name': 'Ruby 読解',
      'is_home_task': true,
      'slots': [
        {'slot_no': 1, 'question_type': 'code_reading', 'language': 'ruby', 'difficulty': 1},
        {'slot_no': 2, 'question_type': 'code_reading', 'language': 'ruby', 'difficulty': 2},
        {'slot_no': 3},
        {'slot_no': 4},
        {'slot_no': 5},
      ],
    },
    {
      'id': 'task-csharp-basics',
      'name': 'C# 基礎',
      'is_home_task': true,
      'slots': [
        {'slot_no': 1, 'question_type': 'code_reading', 'language': 'csharp', 'difficulty': 1},
        {'slot_no': 2, 'question_type': 'output_prediction', 'language': '', 'difficulty': 2},
        {'slot_no': 3},
        {'slot_no': 4},
        {'slot_no': 5},
      ],
    },
    {
      'id': 'task-ruby-advanced',
      'name': 'Ruby 応用',
      'slots': [
        {'slot_no': 1, 'question_type': 'code_reading', 'language': 'ruby', 'difficulty': 3},
        {'slot_no': 2},
        {'slot_no': 3},
        {'slot_no': 4},
        {'slot_no': 5},
      ],
    },
  ];

  static const _optionResponse = <Map<String, Object?>>[
    {'question_type': 'code_reading', 'language': 'typescript', 'difficulty': 1},
    {'question_type': 'code_reading', 'language': 'typescript', 'difficulty': 2},
    {'question_type': 'code_reading', 'language': 'typescript', 'difficulty': 3},
    {'question_type': 'code_reading', 'language': 'typescript', 'difficulty': 4},
    {'question_type': 'code_reading', 'language': 'typescript', 'difficulty': 5},
    {'question_type': 'code_reading', 'language': 'ruby', 'difficulty': 1},
    {'question_type': 'code_reading', 'language': 'ruby', 'difficulty': 2},
    {'question_type': 'code_reading', 'language': 'ruby', 'difficulty': 3},
    {'question_type': 'code_reading', 'language': 'ruby', 'difficulty': 4},
    {'question_type': 'code_reading', 'language': 'ruby', 'difficulty': 5},
    {'question_type': 'output_prediction', 'language': '', 'difficulty': 1},
    {'question_type': 'output_prediction', 'language': '', 'difficulty': 2},
    {'question_type': 'output_prediction', 'language': '', 'difficulty': 3},
    {'question_type': 'output_prediction', 'language': '', 'difficulty': 4},
    {'question_type': 'output_prediction', 'language': '', 'difficulty': 5},
  ];

  final List<LearningTask> _tasks;
  final List<TaskOption> _options;

  @override
  Future<TaskCatalog> fetchCatalog() async => TaskCatalog(
        tasks: List.unmodifiable(_tasks),
        options: List.unmodifiable(_options),
      );

  @override
  Future<LearningTask> saveTask(LearningTask task) async {
    final savedTask = task.id.isEmpty
        ? LearningTask(
            id: 'task-${_tasks.length + 1}',
            name: task.name,
            slots: task.slots,
            isHomeTask: task.isHomeTask,
          )
        : task;
    if (task.id.isEmpty) {
      _tasks.add(savedTask);
    } else {
      final index = _tasks.indexWhere((current) => current.id == savedTask.id);
      if (index == -1) {
        _tasks.add(savedTask);
      } else {
        _tasks[index] = savedTask;
      }
    }
    return savedTask;
  }

  @override
  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((task) => task.id == taskId);
  }
}
