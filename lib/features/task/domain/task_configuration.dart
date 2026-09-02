enum TaskQuestionType {
  codeReading('コード読解'),
  outputPrediction('出力予測');

  const TaskQuestionType(this.label);

  final String label;
}

class TaskSlot {
  const TaskSlot({
    required this.slotNo,
    this.questionType,
    this.language = '',
    this.difficulty,
  });

  final int slotNo;
  final TaskQuestionType? questionType;
  final String language;
  final int? difficulty;

  bool get isConfigured => questionType != null;
}

class TaskOption {
  const TaskOption({
    required this.questionType,
    required this.language,
    required this.difficulty,
  });

  final TaskQuestionType questionType;
  final String language;
  final int difficulty;
}

class LearningTask {
  const LearningTask({
    required this.id,
    required this.name,
    required this.slots,
  });

  final String id;
  final String name;
  final List<TaskSlot> slots;

  int get configuredSlotCount =>
      slots.where((slot) => slot.isConfigured).length;
}

class TaskCatalog {
  const TaskCatalog({required this.tasks, required this.options});

  final List<LearningTask> tasks;
  final List<TaskOption> options;
}
