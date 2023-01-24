import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planner_app/login.dart';
import 'package:planner_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'nock.dart';
import 'dart:convert';

bool homeworkCompleted = false;

void mockApis(
  String apiUrl, {
  bool onlineCheck = true,
  bool register = true,
  bool login = true,
  bool usersme = true,
  bool events = true,
  bool timetable = true,
  bool homework = true,
}) {
  if (onlineCheck) {
    nock(apiUrl)
        .get(
          '/onlineCheck',
        )
        .reply(
          200,
          json.encode({'status': 'success'}),
        );
  }
  if (register) {
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
  }
  if (login) {
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
  }
  if (usersme) {
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
  } else {
    nock(apiUrl)
        .get(
          '/users/@me',
        )
        .reply(
          200,
          json.encode(
            {
              'status': 'success',
              'data': {},
            },
          ),
        );
  }
  if (events) {
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
                'time': DateTime.now()
                    .add(
                      const Duration(
                        days: 1,
                      ),
                    )
                    .millisecondsSinceEpoch,
                'description': 'test description',
                'private': false
              },
              {
                'event_id': 0,
                'user_id': 0,
                'name': 'private event',
                'time': DateTime.now()
                    .add(
                      const Duration(
                        days: 1,
                      ),
                    )
                    .millisecondsSinceEpoch,
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
                'time': DateTime.now()
                    .add(
                      const Duration(
                        days: 1,
                      ),
                    )
                    .millisecondsSinceEpoch,
                'description': 'test description',
                'private': false
              },
              {
                'event_id': 0,
                'user_id': 0,
                'name': 'private event',
                'time': DateTime.now()
                    .add(
                      const Duration(
                        days: 1,
                      ),
                    )
                    .millisecondsSinceEpoch,
                'description': 'test description',
                'private': true
              },
            ],
          }),
        );
  } else {
    nock(apiUrl)
        .get(
          '/events',
        )
        .reply(
          200,
          json.encode({
            'status': 'success',
            'data': [],
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
            'data': [],
          }),
        );
  }
  if (timetable) {
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
        fakeTimetable[i][j] = {
          'subject_id': 0,
          'user_id': 0,
          'name': 'test subject',
          'teacher': 'test teacher',
          'room': 'test room',
          'colour': '#FFFFFF',
        };
      }
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
  } else {
    nock(apiUrl)
        .get(
          '/timetable',
        )
        .reply(
          200,
          json.encode({
            'status': 'success',
            'data': [],
          }),
        );
  }

  if (homework) {
    nock(apiUrl)
        .get(
          '/homework',
        )
        .reply(
            200,
            json.encode({
              'status': 'success',
              'data': [
                {
                  'homework_id': 1,
                  'name': 'test homework',
                  'class_id': null,
                  'completed_by': null,
                  'user_id': 0,
                  'due_date': DateTime.now()
                      .add(const Duration(days: 1))
                      .millisecondsSinceEpoch,
                  'description': 'test description',
                  'completed': false
                },
                {
                  'homework_id': 2,
                  'name': 'test hidden homework',
                  'class_id': null,
                  'completed_by': null,
                  'user_id': 0,
                  'due_date': DateTime.now()
                      .add(const Duration(days: 1))
                      .millisecondsSinceEpoch,
                  'description': 'test description',
                  'completed': true
                }
              ],
            }));
    nock(apiUrl)
        .patch(
          '/homework',
        )
        .reply(
          200,
          json.encode({'status': 'success'}),
        );
  } else {
    nock(apiUrl)
        .get(
          '/homework',
        )
        .reply(
          200,
          json.encode({
            'status': 'success',
            'data': [],
          }),
        );
    nock(apiUrl)
        .patch(
          '/homework',
        )
        .persist()
        .reply(
          200,
          json.encode({'status': 'success'}),
        );
  }
}

void mockSharedPrefs({bool homework = true}) {
  String hw = '';
  if (homework) {
    hw = json.encode(
      [
        {
          'homework_id': 1,
          'name': 'test homework',
          'class_id': null,
          'completed_by': null,
          'user_id': 0,
          'due_date': DateTime.now()
              .add(const Duration(days: 1))
              .millisecondsSinceEpoch,
          'description': 'test description',
          'completed': false
        },
        {
          'homework_id': 2,
          'name': 'test hidden homework',
          'class_id': null,
          'completed_by': null,
          'user_id': 0,
          'due_date': DateTime.now()
              .add(const Duration(days: 1))
              .millisecondsSinceEpoch,
          'description': 'test description',
          'completed': true
        }
      ],
    );
  } else {
    hw = json.encode([]);
  }
  SharedPreferences.setMockInitialValues({
    'homework': hw,
  });
}

/// Logs into the PlannerApp for a test
/// Tester must already have PlannerApp() pumped.
Future<void> login(WidgetTester tester) async {
  expect(find.byType(LoginPage), findsOneWidget);
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
