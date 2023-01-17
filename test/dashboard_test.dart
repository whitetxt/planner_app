import 'package:flutter_test/flutter_test.dart';
import 'package:clock/clock.dart';

import 'package:planner_app/main.dart';

import 'helpers.dart';
import 'nock.dart';

void main() {
  const String apiUrl = 'https://planner-app.duckdns.org/api/v1';
  //const String apiUrl = 'http://127.0.0.1:8000/api/v1';

  setUp(() {
    nock.init();
  });
  setUpAll(() {
    nock.cleanAll();
  });

  testWidgets('Normal | Dashboard displays subject on weekday',
      (WidgetTester tester) async {
    mockApis(apiUrl);
    mockSharedPrefs();
    // Set fixed time, so that it is constant whenever it is run.
    await withClock(Clock.fixed(DateTime(2022, 11, 28)), () async {
      await tester.pumpWidget(const PlannerApp());

      // Logs into the app.
      await login(tester);
      expect(find.text("Today's Timetable"), findsOneWidget);
      expect(find.text('test subject'), findsOneWidget);
    });
  });

  testWidgets('Normal | Dashboard displays no subjects on weekend',
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

  testWidgets('Normal | Dashboard displays homework correctly',
      (WidgetTester tester) async {
    mockApis(apiUrl);
    mockSharedPrefs();
    await tester.pumpWidget(const PlannerApp());
    // Logs into the app.
    await login(tester);
    expect(find.text('Due Homework'), findsOneWidget);
  });

  testWidgets('Normal | Dashboard displays no homework correctly',
      (WidgetTester tester) async {
    mockApis(apiUrl, homework: false);
    mockSharedPrefs(homework: false);
    await tester.pumpWidget(const PlannerApp());
    // Logs into the app.
    await login(tester);
    expect(find.text('No due homework!'), findsOneWidget);
  });

  testWidgets('Normal | Dashboard displays events correctly',
      (WidgetTester tester) async {
    mockApis(apiUrl);
    mockSharedPrefs();
    await tester.pumpWidget(const PlannerApp());

    await login(tester);
    expect(find.text('Upcoming Events'), findsOneWidget);
  });

  testWidgets('Normal | Dashboard displays no events correctly',
      (WidgetTester tester) async {
    mockApis(apiUrl, events: false);
    mockSharedPrefs();
    await tester.pumpWidget(const PlannerApp());

    await login(tester);
    expect(find.text('No upcoming events!'), findsOneWidget);
  });
}
