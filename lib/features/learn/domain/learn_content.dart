enum LearnQuestionType { codeReading, outputPrediction }

class LearnQuestionFilter {
  const LearnQuestionFilter({
    required this.type,
    this.language = '',
    this.difficulty,
  });

  final LearnQuestionType type;
  final String language;
  final int? difficulty;
}

class LearnTaskStartRequest {
  const LearnTaskStartRequest({
    required this.filters,
    this.isTaskBased = false,
  });

  final List<LearnQuestionFilter> filters;
  final bool isTaskBased;
}

class LearnCatalog {
  const LearnCatalog({required this.skills});

  final List<LearnSkill> skills;
}

class LearnSkill {
  const LearnSkill({
    required this.id,
    required this.name,
    required this.description,
    required this.nodes,
  });

  final String id;
  final String name;
  final String description;
  final List<LearnSkillNode> nodes;
}

class LearnSkillNode {
  const LearnSkillNode({
    required this.id,
    required this.name,
    required this.difficulty,
  });

  final String id;
  final String name;
  final int difficulty;
}

class LearnChoice {
  const LearnChoice({required this.key, required this.text});

  final String key;
  final String text;
}

class LearnQuestion {
  const LearnQuestion({
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

  final String id;
  final String skillNodeId;
  final LearnQuestionType type;
  final int difficulty;
  final String title;
  final String body;
  final String code;
  final String codeLanguage;
  final List<LearnChoice> choices;
  final List<String> tags;
}

class LearnAttemptResult {
  const LearnAttemptResult({
    required this.isCorrect,
    required this.correctKeys,
    required this.explanation,
    required this.xpGained,
  });

  final bool isCorrect;
  final List<String> correctKeys;
  final String explanation;
  final int xpGained;
}

class LearnQuestionReview {
  const LearnQuestionReview({
    required this.question,
    required this.selectedKey,
    required this.result,
  });

  final LearnQuestion question;
  final String selectedKey;
  final LearnAttemptResult result;
}
