import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:planner_app/main.dart';

import 'nock.dart';

void main() {
  setUp(() {
    nock.init();
  });
  setUpAll(() {
    nock.cleanAll();
  });
  //const String apiUrl = "https://planner-app.duckdns.org/api/v1";
  const String apiUrl = 'http://127.0.0.1:8000/api/v1';

  testWidgets('Test Password Length Validation', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PlannerApp());

    // Enter fake details to "create" fake account
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'), 'test_account');
    await tester.pump();
    // Test if it checks for
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'testp');
    await tester.pump();

    // Press the register button.
    await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
    await tester.pump();
    expect(find.text('Password must be at least 8 characters long.'),
        findsOneWidget);
  });

  testWidgets('Test Password Number Validation', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PlannerApp());

    // Enter fake details to "create" fake account
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'), 'test_account');
    await tester.pump();
    // Test if it checks for
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'testpassword');
    await tester.pump();

    // Press the register button.
    await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
    await tester.pump();
    expect(find.text('Password must contain a number.'), findsOneWidget);
  });

  testWidgets('Test Registration', (WidgetTester tester) async {
    nock(apiUrl)
        .post(
          '/auth/register',
        )
        .reply(
          200,
          json.encode(
            {
              'status': 'success',
              'data': {'access_token': 'fake_token', 'token_type': 'Bearer'}
            },
          ),
        );
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PlannerApp());

    // Enter fake details to "create" fake account
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'), 'test_account');
    await tester.pump();
    // Test if it checks for
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'testpassword123');
    await tester.pump();

    // Press the register button.
    await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
    await tester.pump();

    // Use no registration code.
    await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
    await tester.pump();

    expect(find.byType(MainPage), findsOneWidget);
  });

  /*testWidgets('Login', (WidgetTester tester) async {
    nock(apiUrl)
        .post(
          "/auth/login",
        )
        .reply(
          200,
          json.encode({"access_token": "fake_token", "token_type": "Bearer"}),
        );
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PlannerApp());

    expect(find.text('Login or Register'), findsOneWidget);

    // Enter in fake details
    await tester.enterText(
        find.widgetWithText(TextFormField, "Username"), "test_account");
    await tester.pump();
    await tester.enterText(
        find.widgetWithText(TextFormField, "Password"), "test_password");
    await tester.pump();

    await tester.tap(find.widgetWithText(ElevatedButton, "Login"));
    await tester.pump();

    // Verify that we have changed page.
    expect(find.byType(MainPage), findsOneWidget);
  });*/
}
