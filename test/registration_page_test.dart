import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:planner_app/main.dart';
import 'package:planner_app/login.dart';

import 'nock.dart';

void main() {
  const String apiUrl = 'https://planner-app.duckdns.org/api/v1';
  //const String apiUrl = 'http://127.0.0.1:8000/api/v1';
  setUp(() {
    nock.init();
    nock(apiUrl)
        .get(
          '/onlineCheck',
        )
        .reply(
          200,
          json.encode({'status': 'success'}),
        );
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
    nock(apiUrl)
        .post(
          '/auth/login',
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
    nock(apiUrl)
        .get(
          '/users/@me',
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
                'permissions': 0,
              }
            },
          ),
        );
    nock(apiUrl)
        .get(
          '/events',
        )
        .reply(
          200,
          json.encode({
            'status': 'success',
            'data': [
              {
                'event_id': 0,
                'user_id': 0,
                'name': 'public event',
                'time': 0,
                'description': 'test description',
                'private': false
              },
              {
                'event_id': 0,
                'user_id': 0,
                'name': 'private event',
                'time': 0,
                'description': 'test description',
                'private': true
              },
            ],
          }),
        );
    nock(apiUrl)
        .get(
          '/events/user/@me',
        )
        .reply(
          200,
          json.encode({
            'status': 'success',
            'data': [
              {
                'event_id': 0,
                'user_id': 0,
                'name': 'public event',
                'time': 0,
                'description': 'test description',
                'private': false
              },
              {
                'event_id': 0,
                'user_id': 0,
                'name': 'private event',
                'time': 0,
                'description': 'test description',
                'private': true
              },
            ],
          }),
        );
    List<List<Map<String, Object>?>> fakeTimetable = [
      [],
      [],
      [],
      [],
      [],
    ];
    for (int i = 0; i < 5; i++) {
      for (int j = 0; j < 9; j++) {
        fakeTimetable[i].add(null);
      }
    }
    fakeTimetable[0][0] = {
      'subject_id': 0,
      'user_id': 0,
      'name': 'test subject',
      'teacher': 'test teacher',
      'room': 'test room',
      'colour': '#FFFFFF',
    };
    nock(apiUrl)
        .get(
          '/timetable',
        )
        .reply(
          200,
          json.encode({
            'status': 'success',
            'data': fakeTimetable,
          }),
        );
  });
  setUpAll(() {
    nock.cleanAll();
  });

  testWidgets('Test Password Length Validation', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PlannerApp());

    // Enter fake details to "create" fake account
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'), 'test_account');
    await tester.pumpAndSettle();
    // Test if it checks for
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'testp');
    await tester.pumpAndSettle();

    // Press the register button.
    await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
    await tester.pumpAndSettle();
    expect(find.text('Password must be at least 8 characters long.'),
        findsOneWidget);
  });

  testWidgets('Test Password Number Validation', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PlannerApp());

    // Enter fake details to "create" fake account
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'), 'test_account');
    await tester.pumpAndSettle();
    // Test if it checks for
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'testpassword');
    await tester.pumpAndSettle();

    // Press the register button.
    await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
    await tester.pumpAndSettle();
    expect(find.text('Password must contain a number.'), findsOneWidget);
  });

  testWidgets('Test Registration Cancel', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PlannerApp());

    // Enter fake details to "create" fake account
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'), 'test_account');
    await tester.pumpAndSettle();
    // Test if it checks for
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'testpassword123');
    await tester.pumpAndSettle();

    // Press the register button.
    await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
    await tester.pumpAndSettle();

    // Use no registration code.
    await tester.tap(find.widgetWithText(ElevatedButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('Test Registration', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PlannerApp());

    // Enter fake details to "create" fake account
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'), 'test_account');
    await tester.pumpAndSettle();
    // Test if it checks for
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'testpassword123');
    await tester.pumpAndSettle();

    // Press the register button.
    await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
    await tester.pumpAndSettle();

    // Use no registration code.
    await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
    await tester.pumpAndSettle();

    expect(find.byType(MainPage), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);
  });

  testWidgets('Login', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PlannerApp());

    expect(find.text('Login or Register'), findsOneWidget);

    // Enter in fake details
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'), 'test_account');
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'test_password');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();

    // Verify that we have changed page.
    expect(find.byType(MainPage), findsOneWidget);
  });
}
