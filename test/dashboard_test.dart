import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:clock/clock.dart';

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
    testWidgets('Dashboard displays subjects on weekdays',
        (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      // Set fixed time, so that it is constant whenever it is run.
      await withClock(Clock.fixed(DateTime(2022, 11, 28)), () async {
        await tester.pumpWidget(const PlannerApp());

        // Logs into the app.
        await login(tester);
        expect(find.text("Today's Timetable"), findsOneWidget);
        expect(find.text('test subject 0 0'), findsWidgets);
      });
    });

    testWidgets('Dashboard displays no subjects on a weekend',
        (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      // Set fixed time, so that it is constant whenever it is run.
      await withClock(Clock.fixed(DateTime(2022, 11, 26)), () async {
        await tester.pumpWidget(const PlannerApp());

        // Logs into the app.
        await login(tester);
        expect(find.text('No lessons today!'), findsOneWidget);
      });
    });

    testWidgets('Dashboard displays homework correctly',
        (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlannerApp());
      // Logs into the app.
      await login(tester);
      expect(find.text('test homework'), findsOneWidget);
      expect(find.text('Due Homework'), findsOneWidget);
    });

    testWidgets('Dashboard displays no homework correctly',
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
              'data': [],
            }),
          );
      await tester.pumpWidget(const PlannerApp());
      // Logs into the app.
      await login(tester);
      expect(find.text('test homework'), findsNothing);
      expect(find.text('No due homework!'), findsOneWidget);
    });

    testWidgets('Dashboard displays events correctly',
        (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlannerApp());

      await login(tester);
      expect(find.text('Upcoming Events'), findsOneWidget);
    });

    testWidgets('Dashboard displays no events correctly',
        (WidgetTester tester) async {
      mockApis(apiUrl, events: false);
      mockSharedPrefs();
      await tester.pumpWidget(const PlannerApp());

      await login(tester);
      expect(find.text('No upcoming events!'), findsOneWidget);
    });
  });
}
