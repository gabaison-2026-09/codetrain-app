import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codetrain_app/app/app.dart';
import 'package:codetrain_app/features/calendar/data/calendar_response_dto.dart';
import 'package:codetrain_app/features/calendar/data/mock_calendar_repository.dart';
import 'package:codetrain_app/features/calendar/presentation/calendar_page.dart';
import 'package:codetrain_app/features/friend/data/friend_user_dto.dart';
import 'package:codetrain_app/features/friend/data/mock_friend_repository.dart';
import 'package:codetrain_app/features/friend/domain/friend_user.dart';
import 'package:codetrain_app/features/home/domain/home_dashboard.dart';
import 'package:codetrain_app/features/home/domain/home_dashboard_repository.dart';
import 'package:codetrain_app/features/home/data/me_response_dto.dart';
import 'package:codetrain_app/features/home/data/mock_top_navigation_repository.dart';
import 'package:codetrain_app/features/home/presentation/home_page.dart';
import 'package:codetrain_app/features/learn/data/learn_response_dto.dart';
import 'package:codetrain_app/features/learn/data/mock_learn_repository.dart';
import 'package:codetrain_app/features/task/data/mock_task_repository.dart';
import 'package:codetrain_app/features/task/data/mock_task_launcher.dart';
import 'package:codetrain_app/features/task/data/task_slots_response_dto.dart';
import 'package:codetrain_app/shared/widgets/code_train_bottom_navigation.dart';
import 'package:codetrain_app/shared/widgets/code_train_top_navigation.dart';

void main() {
  test('GET /v1/me progress DTO maps to the display model', () {
    final response = MeResponseDto.fromJson({
      'progress': {
        'xp': 120,
        'level': 12,
        'streak_days': 5,
        'last_studied_on': '2026-09-01',
        'hearts': 3,
        'current_skill_node_id': null,
      },
    });

    final status = response.progress.toTopNavigationStatus(
      experienceProgress: 0.62,
      maxHearts: 5,
    );

    expect(status.xp, 120);
    expect(status.level, 12);
    expect(status.hearts, 3);
    expect(status.maxHearts, 5);
    expect(status.experienceProgress, 0.62);
  });

  testWidgets('top navigation shows level, progress, and hearts', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CodeTrainApp());

    expect(find.byType(CodeTrainTopNavigation), findsOneWidget);
    expect(find.text('Lv.12'), findsOneWidget);
    expect(
      find.byIcon(Icons.favorite),
      findsNWidgets(MockTopNavigationRepository.mockStatus.maxHearts),
    );
    expect(find.byIcon(Icons.favorite_border), findsNothing);

    final heartIcons = tester
        .widgetList<Icon>(
          find.descendant(
            of: find.byType(CodeTrainTopNavigation),
            matching: find.byType(Icon),
          ),
        )
        .toList();
    final firstFilledHeartIndex =
        MockTopNavigationRepository.mockStatus.maxHearts -
        MockTopNavigationRepository.mockStatus.hearts;
    for (var index = 0; index < heartIcons.length; index++) {
      expect(heartIcons[index].icon, Icons.favorite);
      expect(
        heartIcons[index].color,
        index >= firstFilledHeartIndex
            ? const Color(0xfff2b2b2)
            : const Color(0xffd9d9d9),
      );
    }
  });

  testWidgets('bottom navigation is rendered', (WidgetTester tester) async {
    await tester.pumpWidget(const CodeTrainApp());

    expect(find.byType(CodeTrainBottomNavigation), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(CodeTrainBottomNavigation),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
  });

  testWidgets('home dashboard renders repository data', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          topNavigationRepository: const MockTopNavigationRepository(),
          homeRepository: _FakeHomeDashboardRepository(),
          friendRepository: MockFriendRepository(),
          taskLauncher: const MockTaskLauncher(),
          learnRepository: const MockLearnRepository(),
          taskRepository: MockTaskRepository(),
          calendarRepository: const MockCalendarRepository(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('5'), findsOneWidget);
    expect(find.text('/'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.byIcon(Icons.local_fire_department_outlined), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('連続日数'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    expect(find.text('TS'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('home-play-task-0')));
    await tester.pump();
    expect(find.text('TypeScript 基礎 を開始します。'), findsOneWidget);
    expect(find.text('今月の勉強量'), findsOneWidget);
  });

  testWidgets('swiping the play area switches the whole study task', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          topNavigationRepository: const MockTopNavigationRepository(),
          homeRepository: _FakeHomeDashboardRepository(),
          friendRepository: MockFriendRepository(),
          taskLauncher: const MockTaskLauncher(),
          learnRepository: const MockLearnRepository(),
          taskRepository: MockTaskRepository(),
          calendarRepository: const MockCalendarRepository(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byKey(const ValueKey('home-programs-task-0')), findsOneWidget);
    expect(find.text('TS'), findsOneWidget);

    await tester.fling(
      find.byIcon(Icons.play_arrow_rounded),
      const Offset(-160, 0),
      1200,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byKey(const ValueKey('home-programs-task-1')), findsOneWidget);
    expect(find.text('TS'), findsNothing);
  });

  testWidgets('friend selection animation can be completed', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CodeTrainApp());

    final navigation = find.byType(CodeTrainBottomNavigation);
    final navigationRect = tester.getRect(navigation);
    await tester.tapAt(
      Offset(
        navigationRect.left + navigationRect.width * 851 / 973,
        navigationRect.center.dy,
      ),
    );
    await tester.pump(const Duration(milliseconds: 260));
    await tester.pumpAndSettle();

    expect(find.byType(CodeTrainBottomNavigation), findsOneWidget);
  });

  testWidgets('each bottom navigation tab switches the visible screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CodeTrainApp());

    const tabs = <({int index, String label})>[
      (index: 0, label: 'Calendar'),
      (index: 1, label: 'Learn'),
      (index: 2, label: 'Home'),
      (index: 3, label: 'Task'),
      (index: 4, label: 'Friend'),
    ];
    const tabCenterXs = <double>[118, 302, 483, 668, 851];

    for (final tab in tabs) {
      final navigation = find.byType(CodeTrainBottomNavigation);
      final navigationRect = tester.getRect(navigation);
      await tester.tapAt(
        Offset(
          navigationRect.left +
              navigationRect.width * tabCenterXs[tab.index] / 973,
          navigationRect.center.dy,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      if (tab.index == 2) {
        expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
        expect(find.text('Home screen'), findsNothing);
      } else if (tab.index == 1) {
        expect(find.text('何を学習する？'), findsOneWidget);
        expect(find.text('Learn screen'), findsNothing);
      } else if (tab.index == 3) {
        expect(find.text('タスク'), findsOneWidget);
        expect(find.byKey(const ValueKey('task-search-field')), findsNothing);
        expect(find.text('すべて'), findsNothing);
        expect(find.text('コード読解'), findsNothing);
        expect(find.text('出力予測'), findsNothing);
      } else if (tab.index == 4) {
        expect(find.text('フレンド'), findsWidgets);
        expect(find.byKey(const ValueKey('friend-open-search')), findsOneWidget);
        expect(find.byKey(const ValueKey('friend-search-field')), findsNothing);
      } else {
        expect(find.byKey(const ValueKey('calendar-month-grid')), findsOneWidget);
        expect(find.text('Calendar screen'), findsNothing);
      }
    }
  });

  test('calendar DTO maps API fields to the domain model', () {
    final activity = CalendarResponseDto.fromJson({
      'days': [
        {
          'date': '2026-08-19',
          'total_slots': 3,
          'completed_slots': 1,
          'completed': false,
        },
      ],
      'streak_days': 5,
      'last_studied_on': '2026-08-19',
    }).toDomain();

    expect(activity.days.single.date, DateTime(2026, 8, 19));
    expect(activity.days.single.studied, isTrue);
    expect(activity.days.single.completed, isFalse);
    expect(activity.streakDays, 5);
  });

  testWidgets('calendar moves between months and shows selected day progress', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarPage(
            repository: const MockCalendarRepository(),
            initialMonth: DateTime(2026, 8),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2026年8月'), findsOneWidget);
    expect(find.byKey(const ValueKey('calendar-month-grid')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('calendar-day-19')));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('calendar-selected-day-detail')),
      findsOneWidget,
    );
    expect(find.text('1 / 3'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('calendar-next-month')));
    await tester.pumpAndSettle();
    expect(find.text('2026年9月'), findsOneWidget);
  });

  test('task slot DTO maps API fields to the domain model', () {
    final slot = TaskSlotDto.fromJson({
      'slot_no': 2,
      'question_type': 'output_prediction',
      'language': '',
      'difficulty': 3,
    }).toDomain();

    expect(slot.slotNo, 2);
    expect(slot.questionType!.label, '出力予測');
    expect(slot.language, isEmpty);
    expect(slot.difficulty, 3);

    final task = LearningTaskDto.fromJson({
      'id': 'task-1',
      'name': 'ホーム用タスク',
      'is_home_task': true,
      'slots': [
        {
          'slot_no': 1,
          'question_type': 'code_reading',
          'language': 'typescript',
          'difficulty': 1,
        },
      ],
    }).toDomain();
    expect(task.isHomeTask, isTrue);
  });

  test('friend DTO maps the public user fields and relationship', () {
    final user = FriendUserDto.fromJson({
      'id': 'user-1',
      'user_code': 'sora_js',
      'display_name': 'Sora',
      'avatar_url': null,
      'relationship': 'incoming_request',
    }).toDomain();

    expect(user.userCode, 'sora_js');
    expect(user.displayName, 'Sora');
    expect(user.relationship, FriendRelationship.incomingRequest);
    expect(user.streakDays, 0);
  });

  test('friend repository applies request and relationship actions', () async {
    final repository = MockFriendRepository();

    await repository.cancelRequest('user-mio');
    expect(
      await repository.fetchUsers(filter: FriendFilter.outgoing),
      isEmpty,
    );

    await repository.declineRequest('user-yui');
    final incoming = await repository.fetchUsers(filter: FriendFilter.incoming);
    expect(incoming.map((user) => user.id), isNot(contains('user-yui')));

    await repository.removeFriend('user-aoi');
    final friends = await repository.fetchUsers(filter: FriendFilter.friends);
    expect(friends.map((user) => user.id), isNot(contains('user-aoi')));

    await repository.sendRequest('user-haru');
    final outgoing = await repository.fetchUsers(filter: FriendFilter.outgoing);
    expect(outgoing.map((user) => user.id), contains('user-haru'));

    expect((await repository.searchUserByCode('kai_backend'))?.id, 'user-kai');
    expect(await repository.searchUserByCode('KAI_BACKEND'), isNull);
  });

  testWidgets('friend screen filters, accepts, searches, and sends requests', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const CodeTrainApp());

    final navigation = find.byType(CodeTrainBottomNavigation);
    final navigationRect = tester.getRect(navigation);
    await tester.tapAt(
      Offset(
        navigationRect.left + navigationRect.width * 851 / 973,
        navigationRect.center.dy,
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byKey(const ValueKey('friend-user-user-aoi')), findsOneWidget);
    expect(find.byKey(const ValueKey('friend-user-user-sora')), findsNothing);
    expect(find.text('18日'), findsOneWidget);
    expect(find.byKey(const ValueKey('friend-menu-user-aoi')), findsOneWidget);
    expect(find.text('解除'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('friend-menu-user-aoi')));
    await tester.pumpAndSettle();
    expect(find.text('フレンド解除'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('friend-filter-incoming')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('friend-user-user-sora')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('friend-accept-user-sora')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('friend-user-user-sora')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('friend-open-search')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('friend-search-field')), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('friend-search-field')),
      'kai_backend',
    );
    await tester.tap(find.byKey(const ValueKey('friend-search-button')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('friend-search-result-user-kai')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('friend-send-user-kai')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('friend-send-user-kai')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('friend-search-result-user-kai')),
        matching: find.text('申請中'),
      ),
      findsOneWidget,
    );
  });

  test('updating a task keeps its position in the catalog', () async {
    final repository = MockTaskRepository();
    final initial = await repository.fetchCatalog();
    final task = initial.tasks[1];

    await repository.saveTask(task.copyWith(isHomeTask: !task.isHomeTask));
    final updated = await repository.fetchCatalog();

    expect(
      updated.tasks.map((task) => task.id),
      equals(initial.tasks.map((task) => task.id)),
    );
  });

  testWidgets('task screen shows tasks and opens the creation modal', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CodeTrainApp());
    final navigation = find.byType(CodeTrainBottomNavigation);
    final navigationRect = tester.getRect(navigation);
    await tester.tapAt(
      Offset(
        navigationRect.left + navigationRect.width * 668 / 973,
        navigationRect.center.dy,
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));

    expect(
      find.byKey(const ValueKey('task-task-typescript-basics')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('task-task-ruby-reading')), findsOneWidget);
    expect(find.text('ホームで開始するタスク  3 / 3'), findsOneWidget);
    expect(find.byKey(const ValueKey('task-task-csharp-basics')), findsOneWidget);
    expect(find.byKey(const ValueKey('task-task-ruby-advanced')), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('task-home-toggle-task-ruby-advanced')),
    );
    await tester.pump();
    expect(find.text('ホームで開始できるタスクは3つまでです。'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(
          const ValueKey('task-home-toggle-task-ruby-advanced'),
        ),
        matching: find.byIcon(Icons.add_circle_outline_rounded),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('task-start-button-task-typescript-basics')),
    );
    await tester.pump();
    expect(find.text('TypeScript 基礎 を開始します。'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('task-task-typescript-basics')));
    await tester.pumpAndSettle();

    expect(find.text('タスクを編集'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('task-editor-typescript-basics')),
      findsOneWidget,
    );
    expect(find.byType(ModalBarrier), findsNothing);

    await tester.tap(find.byKey(const ValueKey('task-task-typescript-basics')));
    await tester.pumpAndSettle();
    expect(find.text('タスクを編集'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('task-add-button')));
    await tester.pumpAndSettle();

    expect(find.text('タスクを作成'), findsOneWidget);
    expect(find.byKey(const ValueKey('task-editor-slot-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('task-editor-slot-5')), findsOneWidget);
    expect(find.byKey(const ValueKey('task-save-button')), findsOneWidget);
  });

  test('learning API DTOs map to domain models', () {
    final catalog = LearnSkillsResponseDto.fromJson({
      'skills': [
        {
          'id': 'skill-1',
          'name': 'JavaScript 基礎',
          'description': '基本を学ぶ',
          'nodes': [
            {'id': 'node-1', 'name': '値と型', 'difficulty': 1},
          ],
        },
      ],
    }).toDomain();
    final question = LearnQuestionDetailDto.fromJson({
      'id': 'question-1',
      'skill_node_id': 'node-1',
      'type': 'output_prediction',
      'difficulty': 1,
      'title': '出力を選ぶ',
      'body': '正しい出力は？',
      'code': 'print(1)',
      'code_language': 'dart',
      'choices': [
        {'key': 'a', 'text': '1'},
      ],
      'tags': ['output'],
    }).toDomain();

    expect(catalog.skills.single.nodes.single.name, '値と型');
    expect(question.codeLanguage, 'dart');
    expect(question.choices.single.key, 'a');
  });

  testWidgets('learner selects a topic and answers a four-choice question', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const CodeTrainApp());

    final navigation = find.byType(CodeTrainBottomNavigation);
    final navigationRect = tester.getRect(navigation);
    await tester.tapAt(
      Offset(
        navigationRect.left + navigationRect.width * 302 / 973,
        navigationRect.center.dy,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('何を学習する？'), findsOneWidget);
    expect(find.text('JavaScript 基礎'), findsOneWidget);

    final arrayNode = find.byKey(const ValueKey('learn-node-node-arrays'));
    await tester.ensureVisible(arrayNode);
    await tester.tap(arrayNode);
    final startButton = find.byKey(const ValueKey('learn-start-button'));
    await tester.ensureVisible(startButton);
    await tester.tap(startButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('map の戻り値'), findsOneWidget);
    expect(find.text('出力予測'), findsNothing);
    expect(find.text('JAVASCRIPT'), findsNothing);
    expect(find.text('Lv.2'), findsNothing);
    expect(find.byType(CodeTrainBottomNavigation), findsNothing);
    expect(find.byKey(const ValueKey('learn-choice-a')), findsOneWidget);
    expect(find.byKey(const ValueKey('learn-choice-b')), findsOneWidget);
    expect(find.byKey(const ValueKey('learn-choice-c')), findsOneWidget);
    expect(find.byKey(const ValueKey('learn-choice-d')), findsOneWidget);

    final correctChoice = find.byKey(const ValueKey('learn-choice-b'));
    await tester.ensureVisible(correctChoice);
    await tester.tap(correctChoice);
    await tester.pump();
    final answerButton = find.byKey(const ValueKey('learn-answer-button'));
    await tester.ensureVisible(answerButton);
    await tester.tap(answerButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byKey(const ValueKey('learn-answer-result')), findsOneWidget);
    expect(find.text('正解！'), findsOneWidget);
    expect(find.text('+10 XP'), findsOneWidget);
  });

  testWidgets('learning continues with feedback after every five questions', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const CodeTrainApp());

    final navigation = find.byType(CodeTrainBottomNavigation);
    final navigationRect = tester.getRect(navigation);
    await tester.tapAt(
      Offset(
        navigationRect.left + navigationRect.width * 302 / 973,
        navigationRect.center.dy,
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));

    final arrayNode = find.byKey(const ValueKey('learn-node-node-arrays'));
    await tester.ensureVisible(arrayNode);
    await tester.tap(arrayNode);
    final startButton = find.byKey(const ValueKey('learn-start-button'));
    await tester.ensureVisible(startButton);
    await tester.tap(startButton);
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byKey(const ValueKey('learn-question-back')), findsNothing);
    expect(find.byType(CodeTrainBottomNavigation), findsNothing);
    expect(find.text('1 / 5'), findsOneWidget);

    for (var questionNumber = 1; questionNumber <= 5; questionNumber++) {
      final correctChoice = find.byKey(const ValueKey('learn-choice-b'));
      await tester.ensureVisible(correctChoice);
      await tester.tap(correctChoice);
      await tester.pump();

      final answerButton = find.byKey(const ValueKey('learn-answer-button'));
      await tester.ensureVisible(answerButton);
      await tester.tap(answerButton);
      await tester.pump();

      expect(find.text('$questionNumber / 5'), findsOneWidget);
      if (questionNumber == 5) {
        expect(find.text('フィードバックを見る'), findsOneWidget);
      }

      await tester.ensureVisible(answerButton);
      await tester.tap(answerButton);
      await tester.pump();
    }

    expect(find.byKey(const ValueKey('learn-feedback')), findsOneWidget);
    expect(find.byKey(const ValueKey('learn-feedback-message')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('learn-review-question-arrays-1')),
      findsOneWidget,
    );
    expect(find.text('map の戻り値'), findsOneWidget);
    expect(find.text('[2, 4, 6]'), findsOneWidget);
    expect(find.text('5 / 5'), findsOneWidget);
    expect(find.text('+50 XP'), findsNothing);
    expect(find.byType(CodeTrainBottomNavigation), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('learn-feedback-continue')));
    await tester.pump();

    expect(find.byKey(const ValueKey('learn-feedback')), findsNothing);
    expect(find.byType(CodeTrainBottomNavigation), findsNothing);
    expect(find.text('1 / 5'), findsOneWidget);
    expect(find.text('map の戻り値'), findsOneWidget);
  });
}

class _FakeHomeDashboardRepository implements HomeDashboardRepository {
  @override
  Future<HomeDashboard> fetchDashboard() async {
    return HomeDashboard(
      activityDate: DateTime(2026, 8, 5),
      streakDays: 7,
      studyTasks: const [
        HomeStudyTask(languages: [HomeLanguage.typescript]),
        HomeStudyTask(languages: [HomeLanguage.csharp, HomeLanguage.ruby]),
      ],
      taskProgress: const HomeTaskProgress(completedTasks: 2, totalTasks: 5),
      monthlyProgress: const HomeMonthlyProgress(studiedDays: 16, maxDays: 30),
    );
  }
}
