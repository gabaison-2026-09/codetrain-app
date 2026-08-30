import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codetrain_app/main.dart';

void main() {
  testWidgets('bottom navigation is rendered', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(CodeTrainBottomNavigation), findsOneWidget);
    expect(find.byType(CustomPaint), findsOneWidget);
  });
}
