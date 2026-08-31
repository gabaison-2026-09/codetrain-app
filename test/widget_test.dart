import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codetrain_app/app/app.dart';
import 'package:codetrain_app/shared/widgets/code_train_bottom_navigation.dart';

void main() {
  testWidgets('bottom navigation is rendered', (WidgetTester tester) async {
    await tester.pumpWidget(const CodeTrainApp());

    expect(find.byType(CodeTrainBottomNavigation), findsOneWidget);
    expect(find.byType(CustomPaint), findsOneWidget);
  });
}
