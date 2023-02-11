import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:planner_app/main.dart';
import 'package:planner_app/globals.dart';
import 'package:planner_app/timetable.dart';

import 'helpers.dart';
import 'nock.dart';

void main() {
  setUp(() {
    nock.cleanAll();
    nock.init();
  });

  group('Normal Data', () {
    testWidgets('Timetable page displays correctly',
        (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlannerApp());

      // Logs into the app.
      await login(tester);
      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();

      expect(find.text('Timetable'), findsWidgets);
    });

    testWidgets('Subjects display correctly on the timetable',
        (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlannerApp());

      // Logs into the app.
      await login(tester);
      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();

      expect(find.text('Timetable'), findsWidgets);
      expect(find.byType(SubjectWidget), findsWidgets);
      expect(find.text('test subject'), findsWidgets);
    });

    testWidgets("Modifying a subject's colour opens dialog",
        (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlannerApp());

      // Logs into the app.
      await login(tester);
      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();

      expect(find.text('Timetable'), findsWidgets);
      expect(find.byType(SubjectWidget), findsWidgets);
      expect(find.text('test subject'), findsWidgets);

      await tester.tap(find.widgetWithText(SubjectWidget, 'test subject'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Modify'));
      await tester.pumpAndSettle();

      expect(find.text('Change Subject Colour'), findsOneWidget);
    });

    testWidgets("Modifying a subject's colour works",
        (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlannerApp());

      // Logs into the app.
      await login(tester);
      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();

      expect(find.text('Timetable'), findsWidgets);
      expect(find.byType(SubjectWidget), findsWidgets);
      expect(find.text('test subject'), findsWidgets);

      await tester.tap(find.widgetWithText(SubjectWidget, 'test subject'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Modify'));
      await tester.pumpAndSettle();
      expect(find.text('Change Subject Colour'), findsOneWidget);

      await tester.tap(find.text('Update'));
      await tester.pumpAndSettle();
      expect(find.text('Change Subject Colour'), findsNothing);
    });

    testWidgets("Cancelling modifying a subject's colour works",
        (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlannerApp());

      // Logs into the app.
      await login(tester);
      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();

      expect(find.text('Timetable'), findsWidgets);
      expect(find.byType(SubjectWidget), findsWidgets);
      expect(find.text('test subject'), findsWidgets);

      await tester.tap(find.widgetWithText(SubjectWidget, 'test subject'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Modify'));
      await tester.pumpAndSettle();
      expect(find.text('Change Subject Colour'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Change Subject Colour'), findsNothing);
    });

    testWidgets('Viewing extra information about a timetable slot',
        (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlannerApp());

      // Logs into the app.
      await login(tester);
      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();

      expect(find.text('Timetable'), findsWidgets);
      expect(find.byType(SubjectWidget), findsWidgets);
      expect(find.text('test subject'), findsWidgets);

      await tester.tap(find.widgetWithText(TimetableSlot, 'test subject 0 0'));
      await tester.pumpAndSettle();

      expect(find.text('Room: test room'), findsOneWidget);
      expect(find.text('Teacher: test teacher'), findsOneWidget);
    });

    testWidgets('Deleting a subject from a specific timetable slot',
        (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlannerApp());

      // Logs into the app.
      await login(tester);
      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();

      expect(find.text('Timetable'), findsWidgets);
      expect(find.byType(SubjectWidget), findsWidgets);
      expect(find.text('test subject'), findsWidgets);

      await tester.tap(find.widgetWithText(TimetableSlot, 'test subject 0 0'));
      await tester.pumpAndSettle();

      expect(find.text('Room: test room'), findsOneWidget);
      expect(find.text('Teacher: test teacher'), findsOneWidget);

      await tester.tap(find.text('Remove subject'));
      await tester.pumpAndSettle();
      expect(find.text('Room: test room'), findsNothing);
      expect(find.text('Teacher: test teacher'), findsNothing);
    });

    testWidgets('Adding a subject to a specific timetable slot',
        (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlannerApp());

      // Logs into the app.
      await login(tester);
      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();

      expect(find.text('Timetable'), findsWidgets);
      expect(find.byType(SubjectWidget), findsWidgets);
      expect(find.text('test subject'), findsWidgets);

      await tester.tap(find.widgetWithText(SubjectWidget, 'test subject'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Set timetable'));
      await tester.pumpAndSettle();

      expect(find.text('Stop Setting'), findsOneWidget);

      await tester.tap(find.text('test subject 0 0'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stop Setting'));
      await tester.pumpAndSettle();
      expect(find.text('test subject'), findsWidgets);
    });

    testWidgets('Creating a new subject', (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlannerApp());

      // Logs into the app.
      await login(tester);
      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();

      expect(find.text('Timetable'), findsWidgets);
      expect(find.byType(SubjectWidget), findsWidgets);
      expect(find.text('test subject'), findsWidgets);

      await tester.tap(find.text('New'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Subject Name'),
        'test subject',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Teacher'),
        'test teacher',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Room'),
        'test room',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(find.text('test subject'), findsWidgets);
    });

    testWidgets('Creating a new subject by pressing enter on the name field',
        (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlannerApp());

      // Logs into the app.
      await login(tester);
      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();

      expect(find.text('Timetable'), findsWidgets);
      expect(find.byType(SubjectWidget), findsWidgets);
      expect(find.text('test subject'), findsWidgets);

      await tester.tap(find.text('New'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Teacher'),
        'test teacher',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Room'),
        'test room',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Subject Name'),
        'test subject',
      );
      await tester.pumpAndSettle();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('test subject'), findsWidgets);
    });

    testWidgets('Creating a new subject by pressing enter on the teacher field',
        (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlannerApp());

      // Logs into the app.
      await login(tester);
      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();

      expect(find.text('Timetable'), findsWidgets);
      expect(find.byType(SubjectWidget), findsWidgets);
      expect(find.text('test subject'), findsWidgets);

      await tester.tap(find.text('New'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Room'),
        'test room',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Subject Name'),
        'test subject',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Teacher'),
        'test teacher',
      );
      await tester.pumpAndSettle();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('test subject'), findsWidgets);
    });

    testWidgets('Creating a new subject by pressing enter on the room field',
        (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlannerApp());

      // Logs into the app.
      await login(tester);
      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();

      expect(find.text('Timetable'), findsWidgets);
      expect(find.byType(SubjectWidget), findsWidgets);
      expect(find.text('test subject'), findsWidgets);

      await tester.tap(find.text('New'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Subject Name'),
        'test subject',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Teacher'),
        'test teacher',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Room'),
        'test room',
      );
      await tester.pumpAndSettle();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('test subject'), findsWidgets);
    });
  });

  group('Erroneous Data', () {
    testWidgets('Attempting to set weekday to subject',
        (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlannerApp());

      // Logs into the app.
      await login(tester);
      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();

      expect(find.text('Timetable'), findsWidgets);
      expect(find.byType(SubjectWidget), findsWidgets);
      expect(find.text('test subject'), findsWidgets);

      await tester.tap(find.widgetWithText(SubjectWidget, 'test subject'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Set timetable'));
      await tester.pumpAndSettle();

      expect(find.text('Stop Setting'), findsOneWidget);

      await tester.tap(find.text('Monday'));
      await tester.pumpAndSettle();

      expect(find.text('Monday'), findsOneWidget);
    });
  });
}
