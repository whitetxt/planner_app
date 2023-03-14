import 'dart:convert';
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

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
    testWidgets('Calendar page displays correctly',
        (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlanAway());

      // Logs into the app.
      await login(tester);
      await tester.tap(find.byIcon(Icons.calendar_month));
      await tester.pumpAndSettle();

      expect(find.text('Calendar'), findsWidgets);
    });

    testWidgets('Creating a private event', (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlanAway());

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

    testWidgets('Creating a private event by using enter key on name field',
        (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlanAway());

      // Logs into the app.
      await login(tester);
      await tester.tap(find.byIcon(Icons.calendar_month));
      await tester.pumpAndSettle();

      expect(find.text('Calendar'), findsWidgets);

      await tester.tap(find.text('New'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'Description'),
          'test private event');
      await tester.tap(find.widgetWithText(InkWell, 'Date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Name'), 'private event');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('Create an Event'), findsNothing);
    });

    testWidgets(
        'Creating a private event by using enter key on description field',
        (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlanAway());

      // Logs into the app.
      await login(tester);
      await tester.tap(find.byIcon(Icons.calendar_month));
      await tester.pumpAndSettle();

      expect(find.text('Calendar'), findsWidgets);

      await tester.tap(find.text('New'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Name'), 'private event');
      await tester.tap(find.widgetWithText(InkWell, 'Date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'Description'),
          'test private event');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('Create an Event'), findsNothing);
    });

    testWidgets('Public event button hides if a user is not a teacher',
        (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlanAway());

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
      await withClock(Clock.fixed(DateTime(2022, 11, 26, 12, 12)), () async {
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
        await tester.pumpWidget(const PlanAway());

        // Logs into the app.
        await login(tester);
        await tester.tap(find.byIcon(Icons.calendar_month));
        await tester.pumpAndSettle();

        expect(find.text('Calendar'), findsWidgets);

        await tester.tap(find.text('New'));
        await tester.pumpAndSettle();
        await tester.enterText(
            find.widgetWithText(TextFormField, 'Name'), 'public event');
        await tester.enterText(
            find.widgetWithText(TextFormField, 'Description'),
            'test public event');
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

    testWidgets('Events display correctly for the selected day',
        (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlanAway());

      // Logs into the app.
      await login(tester);
      await tester.tap(find.byIcon(Icons.calendar_month));
      await tester.pumpAndSettle();

      expect(find.text('Calendar'), findsWidgets);
      expect(
        find.text(
          "event today - ${DateFormat('HH:mm').format(clock.now())}",
        ),
        findsOneWidget,
      );
    });

    testWidgets(
        "Delete button doesn't show if the event is not the current user's",
        (WidgetTester tester) async {
      await withClock(Clock.fixed(DateTime(2022, 11, 26, 12, 12)), () async {
        mockApis(apiUrl);
        mockSharedPrefs();
        await tester.pumpWidget(const PlanAway());

        // Logs into the app.
        await login(tester);
        await tester.tap(find.byIcon(Icons.calendar_month));
        await tester.pumpAndSettle();

        expect(find.text('Calendar'), findsWidgets);
        expect(
          find.text(
            "not yours - ${DateFormat('HH:mm').format(clock.now())}",
            skipOffstage: false,
          ),
          findsOneWidget,
        );
        await tester.dragUntilVisible(
          find.text(
            "not yours - ${DateFormat('HH:mm').format(clock.now())}",
            skipOffstage: false,
          ),
          find.byType(ListView),
          Offset.fromDirection(3 * pi / 2),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.text(
            "not yours - ${DateFormat('HH:mm').format(clock.now())}",
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Delete'), findsNothing);
      });
    });

    testWidgets('Deleting events works', (WidgetTester tester) async {
      await withClock(Clock.fixed(DateTime(2022, 11, 26, 12, 12)), () async {
        mockApis(apiUrl);
        mockSharedPrefs();
        await tester.pumpWidget(const PlanAway());

        // Logs into the app.
        await login(tester);
        await tester.tap(find.byIcon(Icons.calendar_month));
        await tester.pumpAndSettle();

        expect(find.text('Calendar'), findsWidgets);
        expect(
          find.text("event today - ${DateFormat('HH:mm').format(clock.now())}"),
          findsOneWidget,
        );
        await tester.tap(
          find.text("event today - ${DateFormat('HH:mm').format(clock.now())}"),
        );
        await tester.pumpAndSettle();

        expect(find.text('Delete'), findsOneWidget);
        await tester.dragUntilVisible(
          find.widgetWithText(ElevatedButton, 'Delete'),
          find.byType(ListView),
          Offset.fromDirection(3 * pi / 2, 250),
        );
        await tester.tap(
          find.widgetWithText(ElevatedButton, 'Delete'),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();
      });
    });
  });
}
