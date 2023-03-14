import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:planaway/main.dart';
import 'package:planaway/globals.dart';

import 'helpers.dart';
import 'nock.dart';

void main() {
  setUp(() {
    nock.cleanAll();
    nock.init();
  });

  group('Normal Data', () {
    testWidgets('Homework page displays correctly',
        (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlanAway());

      // Logs into the app.
      await login(tester);
      await tester.tap(find.byIcon(Icons.book));
      await tester.pumpAndSettle();

      expect(find.text('Homework'), findsWidgets);
    });

    testWidgets('Homework page displays homework', (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlanAway());

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
      await tester.pumpWidget(const PlanAway());

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
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlanAway());

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
      await tester.pumpWidget(const PlanAway());

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
      await tester.pumpWidget(const PlanAway());

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
      await tester.pumpWidget(const PlanAway());

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
      await tester.pumpAndSettle();

      expect(find.text('Add homework'), findsNothing);
    });

    testWidgets('Adding homework with a default date',
        (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlanAway());

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
      await tester.tap(find.widgetWithText(InkWell, 'Date Due'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      expect(find.text('Add homework'), findsNothing);
    });

    testWidgets('Adding homework by pressing enter on name field',
        (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlanAway());

      // Logs into the app.
      await login(tester);
      await tester.tap(find.byIcon(Icons.book));
      await tester.pumpAndSettle();
      expect(find.text('New'), findsOneWidget);

      await tester.tap(find.text('New'));
      await tester.pumpAndSettle();
      expect(find.text('Add homework'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Description (Optional)'),
        'Test Homework Description',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Homework Name'),
        'Test Homework',
      );
      await tester.pumpAndSettle();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Add homework'), findsNothing);
    });

    testWidgets('Adding homework by pressing enter on description field',
        (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlanAway());

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
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Add homework'), findsNothing);
    });

    testWidgets('Adding homework without a description',
        (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlanAway());

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
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      expect(find.text('Add homework'), findsNothing);
    });

    testWidgets('Homework without description shows message',
        (WidgetTester tester) async {
      mockApis(apiUrl, homework: false);
      mockSharedPrefs(homework: false);
      nock(apiUrl)
          .get(
            '/api/v1/homework',
          )
          .reply(
            200,
            json.encode({
              'status': 'success',
              'data': [
                {
                  'homework_id': 1,
                  'name': 'no description homework',
                  'class_id': null,
                  'completed_by': null,
                  'user_id': 0,
                  'due_date': clock
                      .now()
                      .add(const Duration(days: 1))
                      .millisecondsSinceEpoch,
                  'description': null,
                  'completed': false
                },
              ],
            }),
          );
      await tester.pumpWidget(const PlanAway());

      // Logs into the app.
      await login(tester);
      await tester.tap(find.byIcon(Icons.book));
      await tester.pumpAndSettle();

      await tester.tap(find.text('no description homework'));
      await tester.pumpAndSettle();
      expect(find.text('No Description'), findsOneWidget);
    });
  });
}
