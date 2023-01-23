import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:planner_app/main.dart';

import 'helpers.dart';
import 'nock.dart';

void main() {
  const String apiUrl = 'https://planner-app.duckdns.org/api/v1';
  //const String apiUrl = 'http://127.0.0.1:8000/api/v1';

  setUp(() {
    nock.cleanAll();
    nock.init();
  });

  testWidgets('Normal | Homework page displays correctly',
      (WidgetTester tester) async {
    mockApis(apiUrl);
    mockSharedPrefs();
    await tester.pumpWidget(const PlannerApp());

    // Logs into the app.
    await login(tester);
    await tester.tap(find.byIcon(Icons.book));
    await tester.pumpAndSettle();

    expect(find.text('Homework'), findsWidgets);
  });

  testWidgets('Normal | Homework page displays homework',
      (WidgetTester tester) async {
    mockApis(apiUrl);
    mockSharedPrefs();
    await tester.pumpWidget(const PlannerApp());

    // Logs into the app.
    await login(tester);
    await tester.tap(find.byIcon(Icons.book));
    await tester.pumpAndSettle();

    expect(find.text('test homework'), findsOneWidget);
  });

  testWidgets('Normal | Homework page displays extra information when clicked',
      (WidgetTester tester) async {
    mockApis(apiUrl);
    mockSharedPrefs();
    await tester.pumpWidget(const PlannerApp());

    // Logs into the app.
    await login(tester);
    await tester.tap(find.byIcon(Icons.book));
    await tester.pumpAndSettle();

    await tester.tap(find.text('test homework'));
    await tester.pumpAndSettle();
    expect(find.text('test description'), findsOneWidget);
  });

  testWidgets('Normal | Homework page hides completed homework',
      (WidgetTester tester) async {
    mockApis(apiUrl, homework: false);
    mockSharedPrefs(homework: false);
    await tester.pumpWidget(const PlannerApp());

    // Logs into the app.
    await login(tester);
    await tester.tap(find.byIcon(Icons.book));
    await tester.pumpAndSettle();

    expect(find.text('test hidden homework'), findsNothing);
  });
}
