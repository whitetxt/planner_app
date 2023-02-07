import 'dart:convert';

import 'package:clock/clock.dart';
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
    testWidgets('Calendar page displays correctly',
        (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlannerApp());

      // Logs into the app.
      await login(tester);
      await tester.tap(find.byIcon(Icons.calendar_month));
      await tester.pumpAndSettle();

      expect(find.text('Calendar'), findsWidgets);
    });

    testWidgets('Creating a private event', (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlannerApp());

      // Logs into the app.
      await login(tester);
      await tester.tap(find.byIcon(Icons.calendar_month));
      await tester.pumpAndSettle();

      expect(find.text('Calendar'), findsWidgets);

      await tester.tap(find.text('New'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Name'), 'private event');
      await tester.enterText(find.widgetWithText(TextFormField, 'Description'),
          'test private event');
      await tester.tap(find.widgetWithText(InkWell, 'Date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create Private Event'));
      await tester.pumpAndSettle();
      expect(find.text('Create an Event'), findsNothing);
    });

    testWidgets('Public event button hides if a user is not a teacher',
        (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlannerApp());

      // Logs into the app.
      await login(tester);
      await tester.tap(find.byIcon(Icons.calendar_month));
      await tester.pumpAndSettle();

      expect(find.text('Calendar'), findsWidgets);

      await tester.tap(find.text('New'));
      await tester.pumpAndSettle();
      expect(find.text('Create Public Event'), findsNothing);
    });

    testWidgets('Create public event', (WidgetTester tester) async {
      nock(apiUrl)
          .get(
            '/api/v1/users/@me',
          )
          .reply(
            200,
            json.encode(
              {
                'status': 'success',
                'data': {
                  'uid': 0,
                  'username': 'test_account',
                  'created_at': 0,
                  'permissions': 1,
                }
              },
            ),
          );
      mockApis(apiUrl, usersme: false);
      mockSharedPrefs();
      await tester.pumpWidget(const PlannerApp());

      // Logs into the app.
      await login(tester);
      await tester.tap(find.byIcon(Icons.calendar_month));
      await tester.pumpAndSettle();

      expect(find.text('Calendar'), findsWidgets);

      await tester.tap(find.text('New'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Name'), 'private event');
      await tester.enterText(find.widgetWithText(TextFormField, 'Description'),
          'test private event');
      await tester.tap(find.widgetWithText(InkWell, 'Date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create Public Event'));
      await tester.pumpAndSettle();
      expect(find.text('Create an Event'), findsNothing);
    });
  });

  group('Erroneous Data', () {});
}
