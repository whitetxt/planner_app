import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clock/clock.dart';

import 'package:planner_app/main.dart';
import 'package:planner_app/login.dart';

import 'helpers.dart';
import 'nock.dart';

void main() {
  const String apiUrl = 'https://planner-app.duckdns.org/api/v1';
  //const String apiUrl = 'http://127.0.0.1:8000/api/v1';

  setUp(() {
    nock.init();
    mockApis(apiUrl);
  });
  setUpAll(() {
    nock.cleanAll();
  });

  testWidgets('Dashboard displays subject on weekday',
      (WidgetTester tester) async {
    //
    await withClock(Clock.fixed(DateTime(2022, 11, 28)), () async {
      await tester.pumpWidget(const PlannerApp());
    });

    // Logs into the app.
    await login(tester);
    expect(find.text("Today's Timetable"), findsOneWidget);
    expect(find.text('test subject'), findsOneWidget);
  });

  testWidgets('Dashboard displays no subjects on weekend',
      (WidgetTester tester) async {
    //
    await withClock(Clock.fixed(DateTime(2022, 11, 27)), () async {
      await tester.pumpWidget(const PlannerApp());

      // Logs into the app.
      await login(tester);
      expect(find.text('No Lessons Today!'), findsOneWidget);
    });
  });
}
