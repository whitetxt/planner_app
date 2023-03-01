import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:planner_app/main.dart';
import 'package:planner_app/globals.dart';

import 'helpers.dart';
import 'nock.dart';

void main() {
  setUp(() {
    nock.cleanAll();
    nock.init();
  });

  group('Normal Data', () {
    testWidgets('Exams page displays correctly', (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlannerApp());

      // Logs into the app.
      await login(tester);
      await tester.tap(find.byIcon(Icons.check_circle_outline));
      await tester.pumpAndSettle();

      expect(find.text('Exam Marks'), findsOneWidget);
    });

    testWidgets('Exams displays no marks correctly',
        (WidgetTester tester) async {
      mockApis(apiUrl, marks: false);
      mockSharedPrefs(marks: false);
      await tester.pumpWidget(const PlannerApp());

      // Logs into the app.
      await login(tester);
      await tester.tap(find.byIcon(Icons.check_circle_outline));
      await tester.pumpAndSettle();

      expect(find.text('Exam Marks'), findsOneWidget);
      expect(find.text('No marks'), findsOneWidget);
    });

    testWidgets('Exam marks can be added', (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlannerApp());

      // Logs into the app.
      await login(tester);
      await tester.tap(find.byIcon(Icons.check_circle_outline));
      await tester.pumpAndSettle();

      expect(find.text('Exam Marks'), findsOneWidget);

      await tester.tap(find.text('New'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Test Name'),
        'test name',
      );
      await tester.enterText(find.widgetWithText(TextFormField, 'Mark'), '100');
      await tester.enterText(find.widgetWithText(TextFormField, 'Grade'), 'A*');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      expect(find.text('test mark'), findsOneWidget);
    });

    testWidgets(
        'Exam marks can be added by pressing enter on the Test Name field',
        (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlannerApp());

      // Logs into the app.
      await login(tester);
      await tester.tap(find.byIcon(Icons.check_circle_outline));
      await tester.pumpAndSettle();

      expect(find.text('Exam Marks'), findsOneWidget);

      await tester.tap(find.text('New'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'Mark'), '100');
      await tester.enterText(find.widgetWithText(TextFormField, 'Grade'), 'A*');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Test Name'),
        'test name',
      );
      await tester.pumpAndSettle();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('test mark'), findsOneWidget);
    });

    testWidgets('Exam marks can be added by pressing enter on the Mark field',
        (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlannerApp());

      // Logs into the app.
      await login(tester);
      await tester.tap(find.byIcon(Icons.check_circle_outline));
      await tester.pumpAndSettle();

      expect(find.text('Exam Marks'), findsOneWidget);

      await tester.tap(find.text('New'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'Grade'), 'A*');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Test Name'),
        'test name',
      );
      await tester.enterText(find.widgetWithText(TextFormField, 'Mark'), '100');
      await tester.pumpAndSettle();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('test mark'), findsOneWidget);
    });

    testWidgets('Exam marks can be added by pressing enter on the Grade field',
        (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlannerApp());

      // Logs into the app.
      await login(tester);
      await tester.tap(find.byIcon(Icons.check_circle_outline));
      await tester.pumpAndSettle();

      expect(find.text('Exam Marks'), findsOneWidget);

      await tester.tap(find.text('New'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Test Name'),
        'test name',
      );
      await tester.enterText(find.widgetWithText(TextFormField, 'Mark'), '100');
      await tester.enterText(find.widgetWithText(TextFormField, 'Grade'), 'A*');
      await tester.pumpAndSettle();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('test mark'), findsOneWidget);
    });

    testWidgets('Dropdown menu for each mark displays correctly',
        (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlannerApp());

      // Logs into the app.
      await login(tester);
      await tester.tap(find.byIcon(Icons.check_circle_outline));
      await tester.pumpAndSettle();

      expect(find.text('Exam Marks'), findsOneWidget);

      await tester.tap(find.byTooltip('Show menu'));
      await tester.pumpAndSettle();

      expect(find.text('Modify Mark'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('Marks can have their details modified',
        (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlannerApp());

      // Logs into the app.
      await login(tester);
      await tester.tap(find.byIcon(Icons.check_circle_outline));
      await tester.pumpAndSettle();

      expect(find.text('Exam Marks'), findsOneWidget);

      await tester.tap(find.byTooltip('Show menu'));
      await tester.pumpAndSettle();

      expect(find.text('Modify Mark'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      await tester.tap(find.text('Modify Mark'));
      await tester.pumpAndSettle();

      expect(find.text('Changing Mark'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'),
        'test2',
      );
      await tester.enterText(find.widgetWithText(TextFormField, 'Mark'), '90');
      await tester.enterText(find.widgetWithText(TextFormField, 'Grade'), 'A');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Update Mark'));
      await tester.pumpAndSettle();

      expect(find.text('Changing Mark'), findsNothing);
    });

    testWidgets('Marks can be changed without updating the fields',
        (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlannerApp());

      // Logs into the app.
      await login(tester);
      await tester.tap(find.byIcon(Icons.check_circle_outline));
      await tester.pumpAndSettle();

      expect(find.text('Exam Marks'), findsOneWidget);

      await tester.tap(find.byTooltip('Show menu'));
      await tester.pumpAndSettle();

      expect(find.text('Modify Mark'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      await tester.tap(find.text('Modify Mark'));
      await tester.pumpAndSettle();

      expect(find.text('Changing Mark'), findsOneWidget);

      await tester.tap(find.text('Update Mark'));
      await tester.pumpAndSettle();

      expect(find.text('Changing Mark'), findsNothing);
    });

    testWidgets('Marks can be changed by pressing enter on the Test Name field',
        (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlannerApp());

      // Logs into the app.
      await login(tester);
      await tester.tap(find.byIcon(Icons.check_circle_outline));
      await tester.pumpAndSettle();

      expect(find.text('Exam Marks'), findsOneWidget);

      await tester.tap(find.byTooltip('Show menu'));
      await tester.pumpAndSettle();

      expect(find.text('Modify Mark'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      await tester.tap(find.text('Modify Mark'));
      await tester.pumpAndSettle();

      expect(find.text('Changing Mark'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextFormField, 'Mark'), '90');
      await tester.enterText(find.widgetWithText(TextFormField, 'Grade'), 'A');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'),
        'test2',
      );
      await tester.pumpAndSettle();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Changing Mark'), findsNothing);
    });

    testWidgets('Marks can be changed by pressing enter on the Mark field',
        (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlannerApp());

      // Logs into the app.
      await login(tester);
      await tester.tap(find.byIcon(Icons.check_circle_outline));
      await tester.pumpAndSettle();

      expect(find.text('Exam Marks'), findsOneWidget);

      await tester.tap(find.byTooltip('Show menu'));
      await tester.pumpAndSettle();

      expect(find.text('Modify Mark'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      await tester.tap(find.text('Modify Mark'));
      await tester.pumpAndSettle();

      expect(find.text('Changing Mark'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextFormField, 'Grade'), 'A');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'),
        'test2',
      );
      await tester.enterText(find.widgetWithText(TextFormField, 'Mark'), '90');
      await tester.pumpAndSettle();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Changing Mark'), findsNothing);
    });

    testWidgets('Marks can be changed by pressing enter on the Grade field',
        (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlannerApp());

      // Logs into the app.
      await login(tester);
      await tester.tap(find.byIcon(Icons.check_circle_outline));
      await tester.pumpAndSettle();

      expect(find.text('Exam Marks'), findsOneWidget);

      await tester.tap(find.byTooltip('Show menu'));
      await tester.pumpAndSettle();

      expect(find.text('Modify Mark'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      await tester.tap(find.text('Modify Mark'));
      await tester.pumpAndSettle();

      expect(find.text('Changing Mark'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'),
        'test2',
      );
      await tester.enterText(find.widgetWithText(TextFormField, 'Mark'), '90');
      await tester.enterText(find.widgetWithText(TextFormField, 'Grade'), 'A');
      await tester.pumpAndSettle();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Changing Mark'), findsNothing);
    });

    testWidgets('Marks can be deleted', (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlannerApp());

      // Logs into the app.
      await login(tester);
      await tester.tap(find.byIcon(Icons.check_circle_outline));
      await tester.pumpAndSettle();

      expect(find.text('Exam Marks'), findsOneWidget);

      await tester.tap(find.byTooltip('Show menu'));
      await tester.pumpAndSettle();

      expect(find.text('Modify Mark'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
    });
  });

  group('Erroneous Data', () {
    testWidgets('Attempting to create a new mark with a non-integer mark value',
        (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlannerApp());

      // Logs into the app.
      await login(tester);
      await tester.tap(find.byIcon(Icons.check_circle_outline));
      await tester.pumpAndSettle();

      expect(find.text('Exam Marks'), findsOneWidget);

      await tester.tap(find.text('New'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Test Name'),
        'test name',
      );
      await tester.enterText(find.widgetWithText(TextFormField, 'Mark'), 'ABC');
      await tester.enterText(find.widgetWithText(TextFormField, 'Grade'), 'A*');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid mark'), findsOneWidget);
    });

    testWidgets('Attempting to create a new mark without a name',
        (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlannerApp());

      // Logs into the app.
      await login(tester);
      await tester.tap(find.byIcon(Icons.check_circle_outline));
      await tester.pumpAndSettle();

      expect(find.text('Exam Marks'), findsOneWidget);

      await tester.tap(find.text('New'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'Mark'), '100');
      await tester.enterText(find.widgetWithText(TextFormField, 'Grade'), 'A*');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a name'), findsOneWidget);
    });

    testWidgets('Attempting to create a new mark without a mark',
        (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlannerApp());

      // Logs into the app.
      await login(tester);
      await tester.tap(find.byIcon(Icons.check_circle_outline));
      await tester.pumpAndSettle();

      expect(find.text('Exam Marks'), findsOneWidget);

      await tester.tap(find.text('New'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Test Name'),
        'test name',
      );
      await tester.enterText(find.widgetWithText(TextFormField, 'Grade'), 'A*');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid mark'), findsOneWidget);
    });

    testWidgets('Attempting to create a new mark without a grade',
        (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlannerApp());

      // Logs into the app.
      await login(tester);
      await tester.tap(find.byIcon(Icons.check_circle_outline));
      await tester.pumpAndSettle();

      expect(find.text('Exam Marks'), findsOneWidget);

      await tester.tap(find.text('New'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Test Name'),
        'test name',
      );
      await tester.enterText(find.widgetWithText(TextFormField, 'Mark'), '100');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a grade'), findsOneWidget);
    });
  });
}
