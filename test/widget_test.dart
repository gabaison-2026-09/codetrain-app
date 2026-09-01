import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codetrain_app/app/app.dart';
import 'package:codetrain_app/features/home/data/mock_top_navigation_repository.dart';
import 'package:codetrain_app/shared/widgets/code_train_bottom_navigation.dart';
import 'package:codetrain_app/shared/widgets/code_train_top_navigation.dart';

void main() {
  testWidgets('top navigation shows level, progress, and hearts', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CodeTrainApp());

    expect(find.byType(CodeTrainTopNavigation), findsOneWidget);
    expect(find.text('Lv.12'), findsOneWidget);
    expect(
      find.byIcon(Icons.favorite),
      findsNWidgets(MockTopNavigationRepository.mockStatus.heartCount),
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
        MockTopNavigationRepository.mockStatus.heartCount -
        MockTopNavigationRepository.mockStatus.filledHeartCount;
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

      expect(find.text(tab.label), findsOneWidget);
      expect(find.text('${tab.label} screen'), findsOneWidget);
    }
  });
}
