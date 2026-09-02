import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codetrain_app/app/app.dart';
import 'package:codetrain_app/features/home/domain/home_dashboard.dart';
import 'package:codetrain_app/features/home/domain/home_dashboard_repository.dart';
import 'package:codetrain_app/features/home/data/me_response_dto.dart';
import 'package:codetrain_app/features/home/data/mock_top_navigation_repository.dart';
import 'package:codetrain_app/features/home/presentation/home_page.dart';
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
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('5'), findsOneWidget);
    expect(find.text('/'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.byIcon(Icons.local_fire_department_outlined), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('連続日数'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    expect(find.text('TS'), findsOneWidget);
    expect(find.text('今月の勉強量'), findsOneWidget);
  });

  testWidgets('swiping the play area switches the whole study task', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          topNavigationRepository: const MockTopNavigationRepository(),
          homeRepository: _FakeHomeDashboardRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('home-programs-task-0')), findsOneWidget);
    expect(find.text('TS'), findsOneWidget);

    await tester.drag(
      find.byIcon(Icons.play_arrow_rounded),
      const Offset(-160, 0),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('home-programs-task-1')), findsOneWidget);
    expect(find.text('TS'), findsNothing);
  });

  testWidgets('profile selection animation can be completed', (
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
      (index: 4, label: 'Profile'),
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
      await tester.pumpAndSettle();

      if (tab.index == 2) {
        expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
        expect(find.text('Home screen'), findsNothing);
      } else {
        expect(find.text(tab.label), findsOneWidget);
        expect(find.text('${tab.label} screen'), findsOneWidget);
      }
    }
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
      taskProgress: const HomeTaskProgress(
        completedTasks: 2,
        totalTasks: 5,
      ),
      monthlyProgress: const HomeMonthlyProgress(
        studiedDays: 16,
        maxDays: 30,
      ),
    );
  }
}
