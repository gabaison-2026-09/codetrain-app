import '../domain/learn_content.dart';
import '../domain/learn_repository.dart';
import 'learn_response_dto.dart';

class MockLearnRepository implements LearnRepository {
  const MockLearnRepository();

  static final LearnCatalog mockCatalog = LearnSkillsResponseDto.fromJson(
    _skillsResponse,
  ).toDomain();

  static const _skillsResponse = <String, Object?>{
    'skills': [
      {
        'id': 'skill-javascript',
        'slug': 'js-basics',
        'name': 'JavaScript 基礎',
        'description': 'コードを読みながら、値・配列・関数の基本を身につけます。',
        'display_order': 1,
        'nodes': [
          {
            'id': 'node-values',
            'skill_id': 'skill-javascript',
            'prerequisite_node_ids': <String>[],
            'slug': 'values-and-types',
            'name': '値と型',
            'difficulty': 1,
            'display_order': 1,
          },
          {
            'id': 'node-arrays',
            'skill_id': 'skill-javascript',
            'prerequisite_node_ids': ['node-values'],
            'slug': 'arrays',
            'name': '配列メソッド',
            'difficulty': 2,
            'display_order': 2,
          },
        ],
      },
      {
        'id': 'skill-typescript',
        'slug': 'typescript-types',
        'name': 'TypeScript 入門',
        'description': '型注釈と推論を使って、安全なコードの読み方を学びます。',
        'display_order': 2,
        'nodes': [
          {
            'id': 'node-type-inference',
            'skill_id': 'skill-typescript',
            'prerequisite_node_ids': <String>[],
            'slug': 'type-inference',
            'name': '型推論',
            'difficulty': 2,
            'display_order': 1,
          },
          {
            'id': 'node-unions',
            'skill_id': 'skill-typescript',
            'prerequisite_node_ids': ['node-type-inference'],
            'slug': 'union-types',
            'name': 'Union 型',
            'difficulty': 3,
            'display_order': 2,
          },
        ],
      },
      {
        'id': 'skill-csharp',
        'slug': 'csharp-basics',
        'name': 'C# 基礎',
        'description': '条件分岐やコレクションの動作を四択問題で確認します。',
        'display_order': 3,
        'nodes': [
          {
            'id': 'node-csharp-flow',
            'skill_id': 'skill-csharp',
            'prerequisite_node_ids': <String>[],
            'slug': 'control-flow',
            'name': '条件分岐',
            'difficulty': 1,
            'display_order': 1,
          },
        ],
      },
    ],
  };

  static const _questionResponses = <String, List<Map<String, Object?>>>{
    'node-values': [
      {
        'id': 'question-values-1',
        'skill_node_id': 'node-values',
        'type': 'output_prediction',
        'difficulty': 1,
        'title': 'const と値の更新',
        'body': '次のコードを実行したとき、コンソールに表示される値を選んでください。',
        'code':
            'const score = 8;\nconst bonus = 2;\nconsole.log(score + bonus);',
        'code_language': 'javascript',
        'choices': [
          {'key': 'a', 'text': '6'},
          {'key': 'b', 'text': '8'},
          {'key': 'c', 'text': '10'},
          {'key': 'd', 'text': '82'},
        ],
        'tags': ['variable', 'operator'],
      },
      {
        'id': 'question-values-2',
        'skill_node_id': 'node-values',
        'type': 'code_reading',
        'difficulty': 1,
        'title': '文字列への変換',
        'body': 'テンプレートリテラルで作られる文字列として正しいものを選んでください。',
        'code':
            'const level = 3;\nconst label = `Lv.\${level}`;\nconsole.log(label);',
        'code_language': 'javascript',
        'choices': [
          {'key': 'a', 'text': 'Lv.level'},
          {'key': 'b', 'text': 'Lv.3'},
          {'key': 'c', 'text': '3'},
          {'key': 'd', 'text': 'エラーになる'},
        ],
        'tags': ['string', 'template-literal'],
      },
      {
        'id': 'question-values-3',
        'skill_node_id': 'node-values',
        'type': 'output_prediction',
        'difficulty': 1,
        'title': '真偽値の判定',
        'body': '条件式の結果として表示される値を選んでください。',
        'code': 'const age = 20;\nconsole.log(age >= 18);',
        'code_language': 'javascript',
        'choices': [
          {'key': 'a', 'text': 'true'},
          {'key': 'b', 'text': 'false'},
          {'key': 'c', 'text': '18'},
          {'key': 'd', 'text': 'undefined'},
        ],
        'tags': ['boolean', 'comparison'],
      },
    ],
    'node-arrays': [
      {
        'id': 'question-arrays-1',
        'skill_node_id': 'node-arrays',
        'type': 'output_prediction',
        'difficulty': 2,
        'title': 'map の戻り値',
        'body': '次のコードの出力として正しいものを選んでください。',
        'code': 'console.log([1, 2, 3].map((x) => x * 2));',
        'code_language': 'javascript',
        'choices': [
          {'key': 'a', 'text': '[1, 2, 3]'},
          {'key': 'b', 'text': '[2, 4, 6]'},
          {'key': 'c', 'text': '[3, 4, 5]'},
          {'key': 'd', 'text': '6'},
        ],
        'tags': ['array', 'map'],
      },
    ],
    'node-type-inference': [
      {
        'id': 'question-types-1',
        'skill_node_id': 'node-type-inference',
        'type': 'code_reading',
        'difficulty': 2,
        'title': '推論される型',
        'body': '変数 count に推論される型を選んでください。',
        'code': 'const count = [1, 2, 3].length;',
        'code_language': 'typescript',
        'choices': [
          {'key': 'a', 'text': 'string'},
          {'key': 'b', 'text': 'number'},
          {'key': 'c', 'text': 'boolean'},
          {'key': 'd', 'text': 'number[]'},
        ],
        'tags': ['type-inference'],
      },
    ],
    'node-unions': [
      {
        'id': 'question-unions-1',
        'skill_node_id': 'node-unions',
        'type': 'code_reading',
        'difficulty': 3,
        'title': 'Union 型の絞り込み',
        'body': 'toUpperCase を安全に呼び出せる条件を選んでください。',
        'code':
            'function print(value: string | number) {\n  // ここに条件を入れる\n  console.log(value.toUpperCase());\n}',
        'code_language': 'typescript',
        'choices': [
          {'key': 'a', 'text': "typeof value === 'string'"},
          {'key': 'b', 'text': "typeof value === 'number'"},
          {'key': 'c', 'text': 'value > 0'},
          {'key': 'd', 'text': 'value === true'},
        ],
        'tags': ['union', 'narrowing'],
      },
    ],
    'node-csharp-flow': [
      {
        'id': 'question-csharp-1',
        'skill_node_id': 'node-csharp-flow',
        'type': 'output_prediction',
        'difficulty': 1,
        'title': 'if 文の分岐',
        'body': 'コンソールに表示される文字列を選んでください。',
        'code':
            'var score = 75;\nif (score >= 70) {\n  Console.WriteLine("PASS");\n} else {\n  Console.WriteLine("TRY");\n}',
        'code_language': 'csharp',
        'choices': [
          {'key': 'a', 'text': 'PASS'},
          {'key': 'b', 'text': 'TRY'},
          {'key': 'c', 'text': '75'},
          {'key': 'd', 'text': '何も表示されない'},
        ],
        'tags': ['if', 'comparison'],
      },
    ],
  };

  static const _answers = <String, ({String key, String explanation})>{
    'question-values-1': (
      key: 'c',
      explanation: '数値同士の加算なので、8 + 2 の結果である 10 が表示されます。',
    ),
    'question-values-2': (
      key: 'b',
      explanation: r'${level} の部分に変数 level の値 3 が埋め込まれます。',
    ),
    'question-values-3': (
      key: 'a',
      explanation: '20 は 18 以上なので、比較式の結果は true です。',
    ),
    'question-arrays-1': (
      key: 'b',
      explanation: 'map は各要素を2倍した新しい配列 [2, 4, 6] を返します。',
    ),
    'question-types-1': (
      key: 'b',
      explanation: '配列の length は要素数を表す number 型として推論されます。',
    ),
    'question-unions-1': (
      key: 'a',
      explanation: 'typeof で string に絞り込むと、文字列の toUpperCase を安全に呼び出せます。',
    ),
    'question-csharp-1': (
      key: 'a',
      explanation: '75 は 70 以上なので最初の分岐に入り、PASS が表示されます。',
    ),
  };

  @override
  Future<LearnCatalog> fetchCatalog() async => mockCatalog;

  @override
  Future<List<LearnQuestion>> fetchQuestionsForSkillNode(
    String skillNodeId,
  ) async {
    final responses = _questionResponses[skillNodeId] ?? const [];
    return responses
        .map((json) => LearnQuestionDetailDto.fromJson(json).toDomain())
        .toList(growable: false);
  }

  @override
  Future<LearnAttemptResult> submitAttempt({
    required String questionId,
    required List<String> selectedKeys,
    required int durationMs,
  }) async {
    final answer = _answers[questionId];
    if (answer == null) {
      throw StateError('Question not found: $questionId');
    }
    final isCorrect =
        selectedKeys.length == 1 && selectedKeys.single == answer.key;
    return LearnAttemptResponseDto.fromJson({
      'attempt_id': 'attempt-$questionId',
      'is_correct': isCorrect,
      'correct_keys': [answer.key],
      'explanation': answer.explanation,
      'xp_gained': isCorrect ? 10 : 0,
    }).toDomain();
  }
}
