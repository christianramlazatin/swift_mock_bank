import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gcash/main.dart';

void main() {
  testWidgets('App supports login and logout flow', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SwiftBankApp());

    expect(find.text('GCash Login'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), '001');
    await tester.enterText(find.byType(TextFormField).at(1), 'password');
    await tester.tap(find.widgetWithText(FilledButton, 'Submit'));

    await tester.pumpAndSettle();
    expect(find.text('Accounts'), findsOneWidget);

    await tester.tap(find.byTooltip('Open profile options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();
    expect(find.text('GCash Login'), findsOneWidget);
  });
}
