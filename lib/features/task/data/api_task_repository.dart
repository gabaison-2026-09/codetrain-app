import '../domain/task_configuration.dart';
import '../domain/task_repository.dart';
import 'task_remote_data_source.dart';

/// 現行APIを既存のタスク単位Repositoryへ接続する暫定アダプター。
///
/// `/v1/task-slots` はユーザー単位の5スロットだけを表し、実要件の
/// 「複数タスク × 各5スロット」に必要な task_id/name/is_home_task がない。
/// 現時点ではサーバー上の全スロットを単一の仮想タスクとして扱う。
/// 複数タスクの作成・選択は、バックエンド設計更新後に置き換える。
class ApiTaskRepository implements TaskRepository {
  const ApiTaskRepository(this._dataSource);

  final TaskRemoteDataSource _dataSource;

  static const String provisionalTaskId = 'server-task-slots';
  static const String provisionalTaskName = '学習タスク';

  @override
  Future<TaskCatalog> fetchCatalog() async {
    final slotsResponse = await _dataSource.fetchSlots();
    final optionsResponse = await _dataSource.fetchOptions();
    return TaskCatalog(
      tasks: [
        LearningTask(
          id: provisionalTaskId,
          name: provisionalTaskName,
          isHomeTask: true,
          slots: _fillEmptySlots(
            slotsResponse.slots.map((slot) => slot.toDomain()),
          ),
        ),
      ],
      options: optionsResponse.options
          .map((option) => option.toDomain())
          .toList(growable: false),
    );
  }

  @override
  Future<LearningTask> saveTask(LearningTask task) async {
    if (task.id.isNotEmpty && task.id != provisionalTaskId) {
      throw UnsupportedError(
        '現行APIではこのtask_idを保存できません（複数タスク未対応）',
      );
    }
    final current = await _dataSource.fetchSlots();
    final currentSlotNumbers = current.slots.map((slot) => slot.slotNo).toSet();
    final desired = {for (final slot in task.slots) slot.slotNo: slot};
    for (var slotNo = 1; slotNo <= 5; slotNo++) {
      final slot = desired[slotNo];
      if (slot != null && slot.isConfigured) {
        await _dataSource.saveSlot(slot);
      } else if (currentSlotNumbers.contains(slotNo)) {
        await _dataSource.deleteSlot(slotNo);
      }
    }
    return LearningTask(
      id: provisionalTaskId,
      name: provisionalTaskName,
      isHomeTask: true,
      slots: _fillEmptySlots(desired.values),
    );
  }

  @override
  Future<void> deleteTask(String taskId) async {
    if (taskId != provisionalTaskId) {
      throw UnsupportedError(
        '現行APIではこのtask_idを削除できません（複数タスク未対応）',
      );
    }
    final current = await _dataSource.fetchSlots();
    for (final slot in current.slots) {
      await _dataSource.deleteSlot(slot.slotNo);
    }
  }

  static List<TaskSlot> _fillEmptySlots(Iterable<TaskSlot> configured) {
    final byNumber = {for (final slot in configured) slot.slotNo: slot};
    return [
      for (var slotNo = 1; slotNo <= 5; slotNo++)
        byNumber[slotNo] ?? TaskSlot(slotNo: slotNo),
    ];
  }
}
