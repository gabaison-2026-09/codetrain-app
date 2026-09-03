import '../domain/task_configuration.dart';

class TaskSlotDto {
  const TaskSlotDto({
    required this.slotNo,
    required this.questionType,
    required this.language,
    required this.difficulty,
  });

  factory TaskSlotDto.fromJson(Map<String, Object?> json) {
    return TaskSlotDto(
      slotNo: json['slot_no']! as int,
      questionType: json['question_type'] as String?,
      language: json['language'] as String? ?? '',
      difficulty: json['difficulty'] as int?,
    );
  }

  final int slotNo;
  final String? questionType;
  final String language;
  final int? difficulty;

  TaskSlot toDomain() => TaskSlot(
        slotNo: slotNo,
        questionType: questionType == null
            ? null
            : _questionTypeFromApiValue(questionType!),
        language: language,
        difficulty: difficulty,
      );
}

class LearningTaskDto {
  const LearningTaskDto({
    required this.id,
    required this.name,
    required this.slots,
    required this.isHomeTask,
  });

  factory LearningTaskDto.fromJson(Map<String, Object?> json) {
    return LearningTaskDto(
      id: json['id']! as String,
      name: json['name']! as String,
      isHomeTask: json['is_home_task'] as bool? ?? false,
      slots: (json['slots']! as List<Object?>)
          .cast<Map<String, Object?>>()
          .map(TaskSlotDto.fromJson)
          .toList(),
    );
  }

  final String id;
  final String name;
  final bool isHomeTask;
  final List<TaskSlotDto> slots;

  LearningTask toDomain() => LearningTask(
        id: id,
        name: name,
        isHomeTask: isHomeTask,
        slots: slots.map((slot) => slot.toDomain()).toList(),
      );
}

class TaskOptionDto {
  const TaskOptionDto({
    required this.questionType,
    required this.language,
    required this.difficulty,
  });

  factory TaskOptionDto.fromJson(Map<String, Object?> json) {
    return TaskOptionDto(
      questionType: json['question_type']! as String,
      language: json['language']! as String,
      difficulty: json['difficulty']! as int,
    );
  }

  final String questionType;
  final String language;
  final int difficulty;

  TaskOption toDomain() => TaskOption(
        questionType: _questionTypeFromApiValue(questionType),
        language: language,
        difficulty: difficulty,
      );
}

TaskQuestionType _questionTypeFromApiValue(String value) {
  return switch (value) {
    'code_reading' => TaskQuestionType.codeReading,
    'output_prediction' => TaskQuestionType.outputPrediction,
    _ => throw FormatException('Unsupported question_type: $value'),
  };
}
