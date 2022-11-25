import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planner_app/login.dart';
import 'package:planner_app/main.dart';

import 'nock.dart';
import 'dart:convert';

void mockApis(String apiUrl) {
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
    fakeTimetable[i][0] = {
      'subject_id': 0,
      'user_id': 0,
      'name': 'test subject',
      'teacher': 'test teacher',
      'room': 'test room',
      'colour': '#FFFFFF',
    };
  }
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
}

/// Logs into the PlannerApp for a test
/// Tester must already have PlannerApp() pumped.
Future<void> login(WidgetTester tester) async {
  // Enter fake details to "create" fake account
  await tester.enterText(
      find.widgetWithText(TextFormField, 'Username'), 'test_account');
  await tester.pumpAndSettle();

  await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'), 'testpassword123');
  await tester.pumpAndSettle();

  // Press the login button.
  await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
  await tester.pumpAndSettle();

  expect(find.byType(MainPage), findsOneWidget);
  expect(find.byType(LoginPage), findsNothing);
}
