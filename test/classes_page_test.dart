import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:planner_app/main.dart';
import 'package:planner_app/globals.dart';
import 'package:planner_app/pl_appbar.dart';

import 'helpers.dart';
import 'nock.dart';

void main() {
  setUp(() {
    nock.cleanAll();
    nock.init();
  });

  group('Normal Data', () {
    testWidgets("Classes tab doesn't show if the user is not a teacher",
        (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();

      await tester.pumpWidget(const PlanAway());

      // Logs into the app.
      await login(tester);
      expect(find.byIcon(Icons.school), findsNothing);
    });

    testWidgets('Classes tab is displayed if the user is a teacher',
        (WidgetTester tester) async {
      mockApis(apiUrl, teacher: true);
      mockSharedPrefs();

      await tester.pumpWidget(const PlanAway());

      // Logs into the app.
      await login(tester);
      expect(find.byIcon(Icons.school), findsOneWidget);
    });

    testWidgets('Classes page displays correctly', (WidgetTester tester) async {
      mockApis(apiUrl, teacher: true);
      mockSharedPrefs();

      await tester.pumpWidget(const PlanAway());

      // Logs into the app.
      await login(tester);
      expect(find.byIcon(Icons.school), findsOneWidget);

      await tester.tap(find.byIcon(Icons.school));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(PLAppBar, 'Classes'), findsOneWidget);
    });

    testWidgets('Classes page displays classes', (WidgetTester tester) async {
      mockApis(apiUrl, teacher: true);
      mockSharedPrefs();
      await tester.pumpWidget(const PlanAway());

      // Logs into the app.
      await login(tester);
      expect(find.byIcon(Icons.school), findsOneWidget);

      await tester.tap(find.byIcon(Icons.school));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(PLAppBar, 'Classes'), findsOneWidget);
      expect(find.text('test class - 1 Student'), findsOneWidget);
    });

    testWidgets(
        'Classes page classes with 1 student display as "student" not "students"',
        (WidgetTester tester) async {
      mockApis(apiUrl, teacher: true);
      mockSharedPrefs();
      await tester.pumpWidget(const PlanAway());

      // Logs into the app.
      await login(tester);
      expect(find.byIcon(Icons.school), findsOneWidget);

      await tester.tap(find.byIcon(Icons.school));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(PLAppBar, 'Classes'), findsOneWidget);
      expect(find.text('test class - 1 Student'), findsOneWidget);
    });

    testWidgets(
        'Classes page classes with more or less than 1 student display as "students"',
        (WidgetTester tester) async {
      mockApis(apiUrl, teacher: true, classes: false);
      mockSharedPrefs();
      nock(apiUrl)
          .get(
            '/api/v1/classes',
          )
          .reply(
            200,
            json.encode(
              {
                'status': 'success',
                'data': [
                  {
                    'class_id': 0,
                    'teacher_id': 0,
                    'class_name': 'test class2',
                    'homework': [
                      {
                        'homework_id': 10,
                        'name': 'test class homework',
                        'class_id': 0,
                        'completed_by': null,
                        'user_id': 0,
                        'due_date': clock
                            .now()
                            .add(const Duration(days: 1))
                            .millisecondsSinceEpoch,
                        'description': 'test description',
                        'completed': false
                      },
                    ],
                    'students': [
                      {
                        'uid': 1,
                        'username': 'test_student',
                        'created_at': 0,
                        'permissions': 0,
                      },
                      {
                        'uid': 2,
                        'username': 'test_student2',
                        'created_at': 0,
                        'permissions': 0,
                      },
                    ],
                  },
                  {
                    'class_id': 1,
                    'teacher_id': 0,
                    'class_name': 'test class',
                    'homework': [
                      {
                        'homework_id': 11,
                        'name': 'test class homework',
                        'class_id': 0,
                        'completed_by': null,
                        'user_id': 0,
                        'due_date': clock
                            .now()
                            .add(const Duration(days: 1))
                            .millisecondsSinceEpoch,
                        'description': 'test description',
                        'completed': false
                      },
                    ],
                    'students': [],
                  },
                ],
              },
            ),
          );
      await tester.pumpWidget(const PlanAway());

      // Logs into the app.
      await login(tester);
      expect(find.byIcon(Icons.school), findsOneWidget);

      await tester.tap(find.byIcon(Icons.school));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(PLAppBar, 'Classes'), findsOneWidget);
      expect(find.text('test class - 0 Students'), findsOneWidget);
      expect(find.text('test class2 - 2 Students'), findsOneWidget);
    });

    testWidgets('Classes can be created', (WidgetTester tester) async {
      mockApis(apiUrl, teacher: true);
      mockSharedPrefs();
      await tester.pumpWidget(const PlanAway());

      // Logs into the app.
      await login(tester);
      expect(find.byIcon(Icons.school), findsOneWidget);

      await tester.tap(find.byIcon(Icons.school));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create Class'));
      await tester.pumpAndSettle();
      expect(find.text('Create a class'), findsOneWidget);

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Class Name'), 'test class');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create Class!'));
      await tester.pumpAndSettle();

      expect(find.text('Create a class'), findsNothing);
    });

    testWidgets(
        'Classes can be created by pressing enter on the Class Name field',
        (WidgetTester tester) async {
      mockApis(apiUrl, teacher: true);
      mockSharedPrefs();
      await tester.pumpWidget(const PlanAway());

      // Logs into the app.
      await login(tester);
      expect(find.byIcon(Icons.school), findsOneWidget);

      await tester.tap(find.byIcon(Icons.school));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create Class'));
      await tester.pumpAndSettle();
      expect(find.text('Create a class'), findsOneWidget);

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Class Name'), 'test class');
      await tester.pumpAndSettle();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Create a class'), findsNothing);
    });

    testWidgets('Classes can be expanded', (WidgetTester tester) async {
      mockApis(apiUrl, teacher: true);
      mockSharedPrefs();
      await tester.pumpWidget(const PlanAway());

      // Logs into the app.
      await login(tester);
      expect(find.byIcon(Icons.school), findsOneWidget);

      await tester.tap(find.byIcon(Icons.school));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(PLAppBar, 'Classes'), findsOneWidget);
      expect(find.text('test class - 1 Student'), findsOneWidget);

      await tester.tap(find.text('test class - 1 Student'));
      await tester.pumpAndSettle();

      expect(find.text('Students'), findsWidgets);
      expect(find.text('Homework'), findsWidgets);
    });

    testWidgets('Autocomplete works for adding students',
        (WidgetTester tester) async {
      mockApis(apiUrl, teacher: true);
      mockSharedPrefs();
      await tester.pumpWidget(const PlanAway());

      // Logs into the app.
      await login(tester);
      expect(find.byIcon(Icons.school), findsOneWidget);

      await tester.tap(find.byIcon(Icons.school));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(PLAppBar, 'Classes'), findsOneWidget);
      expect(find.text('test class - 1 Student'), findsOneWidget);

      await tester.tap(find.text('test class - 1 Student'));
      await tester.pumpAndSettle();

      expect(find.text('Students'), findsWidgets);
      expect(find.text('Homework'), findsWidgets);

      await tester.tap(find.text('Add Student'));
      await tester.pumpAndSettle();

      expect(find.text('Add a Student'), findsOneWidget);
      await tester.enterText(find.byType(Autocomplete<User>), 'test');
      await tester.pumpAndSettle();
      expect(find.text('test_student'), findsOneWidget);
      expect(find.text('test_student2'), findsOneWidget);
    });

    testWidgets('Students can be added to classes',
        (WidgetTester tester) async {
      mockApis(apiUrl, teacher: true);
      mockSharedPrefs();
      await tester.pumpWidget(const PlanAway());

      // Logs into the app.
      await login(tester);
      expect(find.byIcon(Icons.school), findsOneWidget);

      await tester.tap(find.byIcon(Icons.school));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(PLAppBar, 'Classes'), findsOneWidget);
      expect(find.text('test class - 1 Student'), findsOneWidget);

      await tester.tap(find.text('test class - 1 Student'));
      await tester.pumpAndSettle();

      expect(find.text('Students'), findsWidgets);
      expect(find.text('Homework'), findsWidgets);

      await tester.tap(find.text('Add Student'));
      await tester.pumpAndSettle();

      expect(find.text('Add a Student'), findsOneWidget);
      await tester.enterText(find.byType(Autocomplete<User>), 'test');
      await tester.pumpAndSettle();
      await tester.tap(find.text('test_student2'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Student'));
      await tester.pumpAndSettle();

      expect(find.text('Add a Student'), findsNothing);
    });

    testWidgets('Homework can be created for students',
        (WidgetTester tester) async {
      mockApis(apiUrl, teacher: true);
      mockSharedPrefs();
      await tester.pumpWidget(const PlanAway());

      // Logs into the app.
      await login(tester);
      expect(find.byIcon(Icons.school), findsOneWidget);

      await tester.tap(find.byIcon(Icons.school));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(PLAppBar, 'Classes'), findsOneWidget);
      expect(find.text('test class - 1 Student'), findsOneWidget);

      await tester.tap(find.text('test class - 1 Student'));
      await tester.pumpAndSettle();

      expect(find.text('Students'), findsWidgets);
      expect(find.text('Homework'), findsWidgets);

      await tester.tap(find.text('Create Homework'));
      await tester.pumpAndSettle();

      expect(find.text('Assign Homework'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Homework Name'),
        'test class homework',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Description (Optional)'),
        'test description',
      );
      await tester.tap(find.widgetWithText(InkWell, 'Date Due'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Homework'));
      await tester.pumpAndSettle();

      expect(find.text('Assign Homework'), findsNothing);
    });

    testWidgets(
        'Homework can be created for students by pressing enter on the Homework Name field',
        (WidgetTester tester) async {
      mockApis(apiUrl, teacher: true);
      mockSharedPrefs();
      await tester.pumpWidget(const PlanAway());

      // Logs into the app.
      await login(tester);
      expect(find.byIcon(Icons.school), findsOneWidget);

      await tester.tap(find.byIcon(Icons.school));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(PLAppBar, 'Classes'), findsOneWidget);
      expect(find.text('test class - 1 Student'), findsOneWidget);

      await tester.tap(find.text('test class - 1 Student'));
      await tester.pumpAndSettle();

      expect(find.text('Students'), findsWidgets);
      expect(find.text('Homework'), findsWidgets);

      await tester.tap(find.text('Create Homework'));
      await tester.pumpAndSettle();

      expect(find.text('Assign Homework'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Description (Optional)'),
        'test description',
      );
      await tester.tap(find.widgetWithText(InkWell, 'Date Due'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Homework Name'),
        'test class homework',
      );
      await tester.pumpAndSettle();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Assign Homework'), findsNothing);
    });

    testWidgets(
        'Homework can be created for students by pressing enter on the Description field',
        (WidgetTester tester) async {
      mockApis(apiUrl, teacher: true);
      mockSharedPrefs();
      await tester.pumpWidget(const PlanAway());

      // Logs into the app.
      await login(tester);
      expect(find.byIcon(Icons.school), findsOneWidget);

      await tester.tap(find.byIcon(Icons.school));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(PLAppBar, 'Classes'), findsOneWidget);
      expect(find.text('test class - 1 Student'), findsOneWidget);

      await tester.tap(find.text('test class - 1 Student'));
      await tester.pumpAndSettle();

      expect(find.text('Students'), findsWidgets);
      expect(find.text('Homework'), findsWidgets);

      await tester.tap(find.text('Create Homework'));
      await tester.pumpAndSettle();

      expect(find.text('Assign Homework'), findsOneWidget);
      await tester.tap(find.widgetWithText(InkWell, 'Date Due'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Homework Name'),
        'test class homework',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Description (Optional)'),
        'test description',
      );
      await tester.pumpAndSettle();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Assign Homework'), findsNothing);
    });

    testWidgets('Homework can be created for students without a description',
        (WidgetTester tester) async {
      mockApis(apiUrl, teacher: true);
      mockSharedPrefs();
      await tester.pumpWidget(const PlanAway());

      // Logs into the app.
      await login(tester);
      expect(find.byIcon(Icons.school), findsOneWidget);

      await tester.tap(find.byIcon(Icons.school));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(PLAppBar, 'Classes'), findsOneWidget);
      expect(find.text('test class - 1 Student'), findsOneWidget);

      await tester.tap(find.text('test class - 1 Student'));
      await tester.pumpAndSettle();

      expect(find.text('Students'), findsWidgets);
      expect(find.text('Homework'), findsWidgets);

      await tester.tap(find.text('Create Homework'));
      await tester.pumpAndSettle();

      expect(find.text('Assign Homework'), findsOneWidget);
      await tester.tap(find.widgetWithText(InkWell, 'Date Due'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Homework Name'),
        'test class homework',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Homework'));
      await tester.pumpAndSettle();

      expect(find.text('Assign Homework'), findsNothing);
    });

    testWidgets(
        'Homework has a tooltip that displays the number of completed homeworks',
        (WidgetTester tester) async {
      mockApis(apiUrl, teacher: true);
      mockSharedPrefs();
      await tester.pumpWidget(const PlanAway());

      // Logs into the app.
      await login(tester);
      expect(find.byIcon(Icons.school), findsOneWidget);

      await tester.tap(find.byIcon(Icons.school));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(PLAppBar, 'Classes'), findsOneWidget);
      expect(find.text('test class - 1 Student'), findsOneWidget);

      await tester.tap(find.text('test class - 1 Student'));
      await tester.pumpAndSettle();

      expect(find.text('Students'), findsWidgets);
      expect(find.text('Homework'), findsWidgets);

      expect(find.byTooltip('Completed by 0/1'), findsOneWidget);
    });

    testWidgets("Homework can be clicked to view who hasn't completed it",
        (WidgetTester tester) async {
      mockApis(apiUrl, teacher: true);
      mockSharedPrefs();
      await tester.pumpWidget(const PlanAway());

      // Logs into the app.
      await login(tester);
      expect(find.byIcon(Icons.school), findsOneWidget);

      await tester.tap(find.byIcon(Icons.school));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(PLAppBar, 'Classes'), findsOneWidget);
      expect(find.text('test class - 1 Student'), findsOneWidget);

      await tester.tap(find.text('test class - 1 Student'));
      await tester.pumpAndSettle();

      expect(find.text('Students'), findsWidgets);
      expect(find.text('Homework'), findsWidgets);

      await tester.tap(find.text('test class homework'));
      await tester.pumpAndSettle();
      expect(find.text('test class homework'), findsWidgets);
      expect(find.text('test_student'), findsWidgets);
    });
  });

  group('Erroneous Data', () {
    testWidgets("Classes can't be created without a name",
        (WidgetTester tester) async {
      mockApis(apiUrl, teacher: true);
      mockSharedPrefs();
      await tester.pumpWidget(const PlanAway());

      // Logs into the app.
      await login(tester);
      expect(find.byIcon(Icons.school), findsOneWidget);

      await tester.tap(find.byIcon(Icons.school));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create Class'));
      await tester.pumpAndSettle();
      expect(find.text('Create a class'), findsOneWidget);

      await tester.tap(find.text('Create Class!'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a name'), findsOneWidget);
    });

    testWidgets('Homework cannot be created without a name',
        (WidgetTester tester) async {
      mockApis(apiUrl, teacher: true);
      mockSharedPrefs();
      await tester.pumpWidget(const PlanAway());

      // Logs into the app.
      await login(tester);
      expect(find.byIcon(Icons.school), findsOneWidget);

      await tester.tap(find.byIcon(Icons.school));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(PLAppBar, 'Classes'), findsOneWidget);
      expect(find.text('test class - 1 Student'), findsOneWidget);

      await tester.tap(find.text('test class - 1 Student'));
      await tester.pumpAndSettle();

      expect(find.text('Students'), findsWidgets);
      expect(find.text('Homework'), findsWidgets);

      await tester.tap(find.text('Create Homework'));
      await tester.pumpAndSettle();

      expect(find.text('Assign Homework'), findsOneWidget);
      await tester.tap(find.widgetWithText(InkWell, 'Date Due'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Description (Optional)'),
        'test description',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Homework'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a name'), findsOneWidget);
    });
  });
}
