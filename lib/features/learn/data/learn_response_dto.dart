import '../domain/learn_content.dart';

class LearnSkillsResponseDto {
  const LearnSkillsResponseDto({required this.skills});

  factory LearnSkillsResponseDto.fromJson(Map<String, Object?> json) {
    final skills = json['skills'] as List<Object?>? ?? const [];
    return LearnSkillsResponseDto(
      skills: skills
          .map(
            (skill) => LearnSkillDto.fromJson(skill! as Map<String, Object?>),
          )
          .toList(growable: false),
    );
  }

  final List<LearnSkillDto> skills;

  LearnCatalog toDomain() => LearnCatalog(
    skills: skills.map((skill) => skill.toDomain()).toList(growable: false),
  );
}

class LearnSkillDto {
  const LearnSkillDto({
    required this.id,
    required this.name,
    required this.description,
    required this.nodes,
  });

  factory LearnSkillDto.fromJson(Map<String, Object?> json) {
    final nodes = json['nodes'] as List<Object?>? ?? const [];
    return LearnSkillDto(
      id: json['id']! as String,
      name: json['name']! as String,
      description: json['description'] as String? ?? '',
      nodes: nodes
          .map(
            (node) => LearnSkillNodeDto.fromJson(node! as Map<String, Object?>),
          )
          .toList(growable: false),
    );
  }

  final String id;
  final String name;
  final String description;
  final List<LearnSkillNodeDto> nodes;

  LearnSkill toDomain() => LearnSkill(
    id: id,
    name: name,
    description: description,
    nodes: nodes.map((node) => node.toDomain()).toList(growable: false),
  );
}

class LearnSkillNodeDto {
  const LearnSkillNodeDto({
    required this.id,
    required this.name,
    required this.difficulty,
  });

  factory LearnSkillNodeDto.fromJson(Map<String, Object?> json) {
    return LearnSkillNodeDto(
      id: json['id']! as String,
      name: json['name']! as String,
      difficulty: json['difficulty']! as int,
    );
  }

  final String id;
  final String name;
  final int difficulty;

  LearnSkillNode toDomain() =>
      LearnSkillNode(id: id, name: name, difficulty: difficulty);
}

class LearnQuestionDetailDto {
  const LearnQuestionDetailDto({
    required this.id,
    required this.skillNodeId,
    required this.type,
    required this.difficulty,
    required this.title,
    required this.body,
    required this.code,
    required this.codeLanguage,
    required this.choices,
    required this.tags,
  });

  factory LearnQuestionDetailDto.fromJson(Map<String, Object?> json) {
    final choices = json['choices'] as List<Object?>? ?? const [];
    return LearnQuestionDetailDto(
      id: json['id']! as String,
      skillNodeId: json['skill_node_id']! as String,
      type: json['type']! as String,
      difficulty: json['difficulty']! as int,
      title: json['title']! as String,
      body: json['body']! as String,
      code: json['code'] as String? ?? '',
      codeLanguage: json['code_language'] as String? ?? '',
      choices: choices
          .map(
            (choice) =>
                LearnChoiceDto.fromJson(choice! as Map<String, Object?>),
          )
          .toList(growable: false),
      tags: (json['tags'] as List<Object?>? ?? const []).cast<String>().toList(
        growable: false,
      ),
    );
  }

  final String id;
  final String skillNodeId;
  final String type;
  final int difficulty;
  final String title;
  final String body;
  final String code;
  final String codeLanguage;
  final List<LearnChoiceDto> choices;
  final List<String> tags;

  LearnQuestion toDomain() => LearnQuestion(
    id: id,
    skillNodeId: skillNodeId,
    type: type == 'output_prediction'
        ? LearnQuestionType.outputPrediction
        : LearnQuestionType.codeReading,
    difficulty: difficulty,
    title: title,
    body: body,
    code: code,
    codeLanguage: codeLanguage,
    choices: choices.map((choice) => choice.toDomain()).toList(growable: false),
    tags: tags,
  );
}

class LearnChoiceDto {
  const LearnChoiceDto({required this.key, required this.text});

  factory LearnChoiceDto.fromJson(Map<String, Object?> json) {
    return LearnChoiceDto(
      key: json['key']! as String,
      text: json['text']! as String,
    );
  }

  final String key;
  final String text;

  LearnChoice toDomain() => LearnChoice(key: key, text: text);
}

class LearnAttemptResponseDto {
  const LearnAttemptResponseDto({
    required this.isCorrect,
    required this.correctKeys,
    required this.explanation,
    required this.xpGained,
  });

  factory LearnAttemptResponseDto.fromJson(Map<String, Object?> json) {
    return LearnAttemptResponseDto(
      isCorrect: json['is_correct']! as bool,
      correctKeys: (json['correct_keys']! as List<Object?>)
          .cast<String>()
          .toList(growable: false),
      explanation: json['explanation']! as String,
      xpGained: json['xp_gained']! as int,
    );
  }

  final bool isCorrect;
  final List<String> correctKeys;
  final String explanation;
  final int xpGained;

  LearnAttemptResult toDomain() => LearnAttemptResult(
    isCorrect: isCorrect,
    correctKeys: correctKeys,
    explanation: explanation,
    xpGained: xpGained,
  );
}
