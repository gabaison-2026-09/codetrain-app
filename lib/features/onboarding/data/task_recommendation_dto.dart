import '../../task/domain/task_configuration.dart';
import '../domain/task_recommendation.dart';

class TaskRecommendationRequestDto {
  const TaskRecommendationRequestDto({
    required this.goal,
    required this.language,
    required this.purpose,
    required this.experience,
  });

  factory TaskRecommendationRequestDto.fromDomain(
    TaskRecommendationAnswers answers,
  ) {
    return TaskRecommendationRequestDto(
      goal: answers.goal.apiValue,
      language: answers.language.apiValue,
      purpose: answers.purpose.apiValue,
      experience: answers.experience.apiValue,
    );
  }

  final String goal;
  final String language;
  final String purpose;
  final String experience;

  Map<String, Object?> toJson() => {
    'goal': goal,
    'language': language,
    'purpose': purpose,
    'experience': experience,
  };
}

class TaskRecommendationResponseDto {
  const TaskRecommendationResponseDto({required this.task});

  factory TaskRecommendationResponseDto.fromJson(
    Map<String, Object?> json,
  ) {
    return TaskRecommendationResponseDto(
      task: RecommendedTaskDto.fromJson(
        json['task']! as Map<String, Object?>,
      ),
    );
  }

  final RecommendedTaskDto task;

  LearningTask toDomain() => task.toDomain();
}

class RecommendedTaskDto {
  const RecommendedTaskDto({
    required this.name,
    required this.isHomeTask,
    required this.slots,
  });

  factory RecommendedTaskDto.fromJson(Map<String, Object?> json) {
    return RecommendedTaskDto(
      name: json['name']! as String,
      isHomeTask: json['is_home_task'] as bool? ?? false,
      slots: (json['slots']! as List<Object?>)
          .cast<Map<String, Object?>>()
          .map(RecommendedTaskSlotDto.fromJson)
          .toList(),
    );
  }

  final String name;
  final bool isHomeTask;
  final List<RecommendedTaskSlotDto> slots;

  LearningTask toDomain() => LearningTask(
    id: '',
    name: name,
    isHomeTask: isHomeTask,
    slots: slots.map((slot) => slot.toDomain()).toList(),
  );
}

class RecommendedTaskSlotDto {
  const RecommendedTaskSlotDto({
    required this.slotNo,
    required this.questionType,
    required this.language,
    required this.minimumDifficulty,
    required this.maximumDifficulty,
  });

  factory RecommendedTaskSlotDto.fromJson(Map<String, Object?> json) {
    return RecommendedTaskSlotDto(
      slotNo: json['slot_no']! as int,
      questionType: json['question_type']! as String,
      language: json['language'] as String? ?? '',
      minimumDifficulty: json['minimum_difficulty'] as int?,
      maximumDifficulty: json['maximum_difficulty'] as int?,
    );
  }

  final int slotNo;
  final String questionType;
  final String language;
  final int? minimumDifficulty;
  final int? maximumDifficulty;

  TaskSlot toDomain() => TaskSlot(
    slotNo: slotNo,
    questionType: switch (questionType) {
      'code_reading' => TaskQuestionType.codeReading,
      'output_prediction' => TaskQuestionType.outputPrediction,
      _ => throw FormatException('Unsupported question_type: $questionType'),
    },
    language: language,
    minimumDifficulty: minimumDifficulty,
    maximumDifficulty: maximumDifficulty,
  );
}
