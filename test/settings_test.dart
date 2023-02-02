import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planner_app/login.dart';

import 'package:planner_app/main.dart';
import 'package:planner_app/settings.dart';

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
    testWidgets('Settings page opens', (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlannerApp());

      // Logs into the app.
      await login(tester);
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('Logging out takes the user back to the login page',
        (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlannerApp());

      // Logs into the app.
      await login(tester);
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('Resetting data then cancelling', (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlannerApp());

      // Logs into the app.
      await login(tester);
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);

      await tester.tap(find.text('Reset Data'));
      await tester.pumpAndSettle();
      expect(find.text("Don't do it! Take me back!"), findsOneWidget);

      await tester.tap(find.text("Don't do it! Take me back!"));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsPage), findsOneWidget);
    });

    testWidgets('Resetting account', (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlannerApp());

      // Logs into the app.
      await login(tester);
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);

      await tester.tap(find.text('Reset Data'));
      await tester.pumpAndSettle();
      expect(find.text("Yes, I know what I'm doing."), findsOneWidget);

      await tester.tap(find.text("Yes, I know what I'm doing."));
      await tester.pumpAndSettle();

      expect(find.byType(MainPage), findsOneWidget);
      expect(find.byType(SettingsPage), findsNothing);
    });

    testWidgets('Deleting account then cancelling',
        (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlannerApp());

      // Logs into the app.
      await login(tester);
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);

      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();
      expect(find.text("Don't do it! Take me back!"), findsOneWidget);

      await tester.tap(find.text("Don't do it! Take me back!"));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsPage), findsOneWidget);
    });

    testWidgets('Deleting account', (WidgetTester tester) async {
      mockApis(apiUrl);
      mockSharedPrefs();
      await tester.pumpWidget(const PlannerApp());

      // Logs into the app.
      await login(tester);
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);

      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();
      expect(find.text("Yes, I know what I'm doing."), findsOneWidget);

      await tester.tap(find.text("Yes, I know what I'm doing."));
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
    });
  });
  group('Erroneous Data', () {
    testWidgets('Bad response from server during account resetting',
        (WidgetTester tester) async {
      mockApis(apiUrl, reset: false);
      nock(apiUrl).post('/users/reset').reply(
          200,
          json.encode({
            'status': 'fail',
            'message': 'This is a test failure.',
          }));
      mockSharedPrefs();
      await tester.pumpWidget(const PlannerApp());

      // Logs into the app.
      await login(tester);
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);

      await tester.tap(find.text('Reset Data'));
      await tester.pumpAndSettle();
      expect(find.text("Yes, I know what I'm doing."), findsOneWidget);

      await tester.tap(find.text("Yes, I know what I'm doing."));
      await tester.pumpAndSettle();

      expect(find.byType(MainPage), findsNothing);
      expect(find.byType(SettingsPage), findsOneWidget);
    });

    testWidgets('Bad response from server during account deletion',
        (WidgetTester tester) async {
      mockApis(apiUrl, delete: false);
      nock(apiUrl).delete('/users/@me').reply(
          200,
          json.encode({
            'status': 'fail',
            'message': 'This is a test failure.',
          }));
      mockSharedPrefs();
      await tester.pumpWidget(const PlannerApp());

      // Logs into the app.
      await login(tester);
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);

      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();
      expect(find.text("Yes, I know what I'm doing."), findsOneWidget);

      await tester.tap(find.text("Yes, I know what I'm doing."));
      await tester.pumpAndSettle();

      expect(find.byType(MainPage), findsNothing);
      expect(find.byType(SettingsPage), findsOneWidget);
    });
  });
}
