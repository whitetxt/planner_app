import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clock/clock.dart';

import 'package:planner_app/main.dart';
import 'package:planner_app/settings.dart';

import 'helpers.dart';
import 'nock.dart';

void main() {
  const String apiUrl = 'https://planner-app.duckdns.org/api/v1';
  //const String apiUrl = 'http://127.0.0.1:8000/api/v1';

  setUp(() {
    nock.cleanAll();
    nock.init();
  });

  testWidgets('Normal | Dashboard displays subject on weekday',
      (WidgetTester tester) async {
    mockApis(apiUrl);
    mockSharedPrefs();
    await tester.pumpWidget(const PlannerApp());

    // Logs into the app.
    await login(tester);
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
  });
}
