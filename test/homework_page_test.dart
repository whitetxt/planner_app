import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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

  group('Normal Data', () {
    testWidgets('Homework page displays correctly',
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

    testWidgets('Homework page displays homework', (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlannerApp());

      // Logs into the app.
      await login(tester);
      await tester.tap(find.byIcon(Icons.book));
      await tester.pumpAndSettle();

      expect(find.text('test homework'), findsOneWidget);
    });

    testWidgets('Homework page displays extra information when clicked',
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

    testWidgets('Homework page hides completed homework',
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

    testWidgets('Homework page can reveal completed homework',
        (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlannerApp());

      // Logs into the app.
      await login(tester);
      await tester.tap(find.byIcon(Icons.book));
      await tester.pumpAndSettle();

      expect(find.text('test hidden homework'), findsNothing);

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      expect(
          tester
              .getSemantics(find.byType(Checkbox))
              .getSemanticsData()
              .hasFlag(SemanticsFlag.hasCheckedState),
          true);
      expect(find.text('test hidden homework'), findsOneWidget);
    });

    testWidgets('Marking homework as complete hides it',
        (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlannerApp());

      // Logs into the app.
      await login(tester);
      await tester.tap(find.byIcon(Icons.book));
      await tester.pumpAndSettle();
      expect(find.text('test homework'), findsOneWidget);

      await tester.tap(find.text('test homework'));
      await tester.pumpAndSettle();
      expect(find.text('Mark as Complete'), findsOneWidget);

      await tester.tap(find.text('Mark as Complete'));
      await tester.pumpAndSettle();
    });

    testWidgets('Adding homework works', (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlannerApp());

      // Logs into the app.
      await login(tester);
      await tester.tap(find.byIcon(Icons.book));
      await tester.pumpAndSettle();
      expect(find.text('New'), findsOneWidget);

      await tester.tap(find.text('New'));
      await tester.pumpAndSettle();
      expect(find.text('Add homework'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Homework Name'),
        'Test Homework',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Description (Optional)'),
        'Test Homework Description',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit'));

      expect(find.text('Add homework'), findsNothing);
    });
  });
}
