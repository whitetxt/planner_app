import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planner_app/login.dart';
import 'package:planner_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'nock.dart';
import 'dart:convert';

void mockApis(
  String apiUrl, {
  bool onlineCheck = true,
  bool register = true,
  bool login = true,
  bool teacher = false,
  bool logout = true,
  bool delete = true,
  bool reset = true,
  bool usersme = true,
  bool events = true,
  bool timetable = true,
  bool homework = true,
  bool subjects = true,
  bool marks = true,
  bool classes = true,
}) {
  apiUrl = '$apiUrl/api/v1';
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
                // If we want to be a teacher, say we are, otherwise don't.
                'permissions': teacher ? 1 : 0,
              }
            },
          ),
        );
  }
  if (logout) {
    nock(apiUrl)
        .get(
          '/auth/logout',
        )
        .reply(
            200,
            json.encode({
              'status': 'success',
            }));
  }
  if (delete) {
    nock(apiUrl)
        .delete(
          '/users/@me',
        )
        .reply(
            200,
            json.encode(
              {
                'status': 'success',
              },
            ));
  }
  if (reset) {
    nock(apiUrl)
        .post(
          '/users/reset',
        )
        .reply(
            200,
            json.encode(
              {
                'status': 'success',
              },
            ));
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
                'event_id': 2,
                'user_id': 0,
                'name': 'event today',
                'time': clock.now().millisecondsSinceEpoch,
                'description': 'test description',
                'private': false
              },
              {
                'event_id': 3,
                'user_id': 1,
                'name': 'not yours',
                'time': clock.now().millisecondsSinceEpoch,
                'description': 'description',
                'private': false
              },
              {
                'event_id': 0,
                'user_id': 0,
                'name': 'public event',
                'time': clock
                    .now()
                    .add(
                      const Duration(
                        days: 1,
                      ),
                    )
                    .millisecondsSinceEpoch,
                'description': 'test description',
                'private': false
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
                'event_id': 2,
                'user_id': 0,
                'name': 'event today',
                'time': clock.now().millisecondsSinceEpoch,
                'description': 'test description',
                'private': false
              },
              {
                'event_id': 0,
                'user_id': 0,
                'name': 'public event',
                'time': clock
                    .now()
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
                'event_id': 1,
                'user_id': 0,
                'name': 'private event',
                'time': clock
                    .now()
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
        .post(
          '/events',
        )
        .reply(
          200,
          json.encode({'status': 'success'}),
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
    nock(apiUrl)
        .post(
          '/events',
        )
        .reply(
          200,
          json.encode({'status': 'success'}),
        );
    nock(apiUrl)
        .delete(
          '/events/2',
        )
        .reply(
          200,
          json.encode({'status': 'success'}),
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
          'name': 'test subject $i $j',
          'teacher': 'test teacher',
          'room': 'test room',
          'colour': '#FFFFFF',
        };
      }
      fakeTimetable[i][1] = null;
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
    nock(apiUrl)
        .delete(
          '/timetable',
        )
        .reply(
          200,
          json.encode(
            {
              'status': 'success',
            },
          ),
        );
    nock(apiUrl)
        .post(
          '/timetable',
        )
        .reply(
          200,
          json.encode(
            {
              'status': 'success',
            },
          ),
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
    nock(apiUrl)
        .delete(
          '/timetable',
        )
        .reply(
          200,
          json.encode(
            {
              'status': 'success',
            },
          ),
        );
    nock(apiUrl)
        .post(
          '/timetable',
        )
        .reply(
          200,
          json.encode(
            {
              'status': 'success',
            },
          ),
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
                  'due_date': clock
                      .now()
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
                  'due_date': clock
                      .now()
                      .add(const Duration(days: 1))
                      .millisecondsSinceEpoch,
                  'description': 'test description',
                  'completed': true
                },
                {
                  'homework_id': 3,
                  'name': 'test homework far future',
                  'class_id': null,
                  'completed_by': null,
                  'user_id': 0,
                  'due_date': clock
                      .now()
                      .add(const Duration(days: 90))
                      .millisecondsSinceEpoch,
                  'description': 'test description',
                  'completed': false
                },
                {
                  'homework_id': 4,
                  'name': 'test homework future',
                  'class_id': null,
                  'completed_by': null,
                  'user_id': 0,
                  'due_date': clock
                      .now()
                      .add(const Duration(days: 4))
                      .millisecondsSinceEpoch,
                  'description': 'test description',
                  'completed': false
                },
                {
                  'homework_id': 5,
                  'name': 'test homework soon',
                  'class_id': null,
                  'completed_by': null,
                  'user_id': 0,
                  'due_date': clock
                      .now()
                      .add(const Duration(hours: 1))
                      .millisecondsSinceEpoch,
                  'description': 'test description',
                  'completed': false
                },
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
    nock(apiUrl)
        .post(
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
        .reply(
          200,
          json.encode({'status': 'success'}),
        );
  }
  if (subjects) {
    nock(apiUrl)
        .get(
          '/subjects/@me',
        )
        .reply(
            200,
            json.encode(
              {
                'status': 'success',
                'data': [
                  {
                    'subject_id': 0,
                    'user_id': 0,
                    'name': 'test subject',
                    'teacher': 'subject teacher',
                    'room': 'A1',
                    'colour': '#FF0000',
                  }
                ],
              },
            ));
    nock(apiUrl)
        .post(
          '/subjects',
        )
        .reply(
          200,
          json.encode(
            {
              'status': 'success',
            },
          ),
        );
    nock(apiUrl)
        .patch(
          '/subjects/0',
        )
        .reply(
          200,
          json.encode(
            {
              'status': 'success',
            },
          ),
        );
  } else {
    nock(apiUrl).get('/subjects/@me').reply(
        200,
        json.encode(
          {
            'status': 'success',
            'data': [],
          },
        ));
    nock(apiUrl)
        .post(
          '/subjects',
        )
        .reply(
          200,
          json.encode(
            {
              'status': 'success',
            },
          ),
        );
    nock(apiUrl)
        .patch(
          '/subjects/0',
        )
        .reply(
          200,
          json.encode(
            {
              'status': 'success',
            },
          ),
        );
  }
  if (marks) {
    nock(apiUrl).get('/marks').reply(
        200,
        json.encode({
          'status': 'success',
          'data': [
            {
              'mark_id': 0,
              'user_id': 0,
              'test_name': 'test mark',
              'mark': 100,
              'grade': 'A*',
            },
          ],
        }));
    nock(apiUrl)
        .post(
          '/marks',
        )
        .reply(
          200,
          json.encode(
            {
              'status': 'success',
            },
          ),
        );
    nock(apiUrl)
        .put(
          '/marks',
        )
        .reply(
          200,
          json.encode(
            {
              'status': 'success',
            },
          ),
        );
    nock(apiUrl)
        .delete(
          '/marks',
        )
        .reply(
          200,
          json.encode(
            {
              'status': 'success',
            },
          ),
        );
  } else {
    nock(apiUrl)
        .get(
          '/marks',
        )
        .reply(200, json.encode({'status': 'success', 'data': []}));
    nock(apiUrl)
        .post(
          '/marks',
        )
        .reply(
          200,
          json.encode(
            {
              'status': 'success',
            },
          ),
        );
    nock(apiUrl)
        .put(
          '/marks',
        )
        .reply(
          200,
          json.encode(
            {
              'status': 'success',
            },
          ),
        );
    nock(apiUrl)
        .delete(
          '/marks',
        )
        .reply(
          200,
          json.encode(
            {
              'status': 'success',
            },
          ),
        );
  }
  if (classes) {
    nock(apiUrl)
        .get(
          '/classes',
        )
        .reply(
          200,
          json.encode(
            {
              'status': 'success',
              'data': [
                {
                  'class_id': 0,
                  'teacher_id': 0,
                  'class_name': 'test class',
                  'homework': [
                    {
                      'homework_id': 10,
                      'name': 'test class homework',
                      'class_id': 0,
                      'completed_by': 0,
                      'user_id': 0,
                      'due_date': clock
                          .now()
                          .add(const Duration(days: 1))
                          .millisecondsSinceEpoch,
                      'description': 'test description',
                      'completed': false
                    },
                  ],
                  'students': [
                    {
                      'uid': 1,
                      'username': 'test_student',
                      'created_at': 0,
                      'permissions': 0,
                    },
                  ],
                },
              ],
            },
          ),
        );
    nock(apiUrl)
        .get(
          '/users/search/test',
        )
        .reply(
          200,
          json.encode(
            {
              'status': 'success',
              'data': [
                {
                  'uid': 1,
                  'username': 'test_student',
                  'created_at': 0,
                  'permissions': 0,
                },
                {
                  'uid': 2,
                  'username': 'test_student2',
                  'created_at': 0,
                  'permissions': 0,
                },
              ]
            },
          ),
        );
    nock(apiUrl)
        .get(
          '/users/search/test_student2',
        )
        .reply(
          200,
          json.encode(
            {
              'status': 'success',
              'data': [
                {
                  'uid': 2,
                  'username': 'test_student2',
                  'created_at': 0,
                  'permissions': 0,
                },
              ]
            },
          ),
        );
    nock(apiUrl)
        .patch(
          '/classes/0',
        )
        .reply(
          200,
          json.encode(
            {
              'status': 'success',
            },
          ),
        );
    nock(apiUrl)
        .post(
          '/classes',
        )
        .reply(
          200,
          json.encode(
            {
              'status': 'success',
            },
          ),
        );
    nock(apiUrl)
        .post(
          '/classes/0/homework',
        )
        .reply(
          200,
          json.encode(
            {
              'status': 'success',
            },
          ),
        );

    nock(apiUrl)
        .get(
          '/classes/0/homework/10',
        )
        .reply(
          200,
          json.encode(
            {
              'status': 'success',
              'data': {
                'incomplete': ['test_student'],
                'completed': [],
              },
            },
          ),
        );
  }
}

void mockSharedPrefs({bool homework = true, bool marks = true}) {
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
          'due_date':
              clock.now().add(const Duration(days: 1)).millisecondsSinceEpoch,
          'description': 'test description',
          'completed': false
        },
        {
          'homework_id': 2,
          'name': 'test hidden homework',
          'class_id': null,
          'completed_by': null,
          'user_id': 0,
          'due_date':
              clock.now().add(const Duration(days: 1)).millisecondsSinceEpoch,
          'description': 'test description',
          'completed': true
        },
        {
          'homework_id': 3,
          'name': 'test homework far future',
          'class_id': null,
          'completed_by': null,
          'user_id': 0,
          'due_date':
              clock.now().add(const Duration(days: 90)).millisecondsSinceEpoch,
          'description': 'test description',
          'completed': false
        },
        {
          'homework_id': 4,
          'name': 'test homework future',
          'class_id': null,
          'completed_by': null,
          'user_id': 0,
          'due_date':
              clock.now().add(const Duration(days: 4)).millisecondsSinceEpoch,
          'description': 'test description',
          'completed': false
        },
        {
          'homework_id': 5,
          'name': 'test homework soon',
          'class_id': null,
          'completed_by': null,
          'user_id': 0,
          'due_date':
              clock.now().add(const Duration(hours: 1)).millisecondsSinceEpoch,
          'description': 'test description',
          'completed': false
        }
      ],
    );
  } else {
    hw = json.encode([]);
  }
  String mks = '';
  if (marks) {
    mks = json.encode([
      {
        'mark_id': 0,
        'user_id': 0,
        'test_name': 'test mark',
        'mark': 100,
        'grade': 'A*',
      },
    ]);
  } else {
    mks = json.encode([]);
  }
  SharedPreferences.setMockInitialValues({
    'homework': hw,
    'marks': mks,
  });
}

/// Logs into the PlannerApp for a test
/// Tester must already have PlannerApp() pumped.
Future<void> login(WidgetTester tester) async {
  expect(find.byType(LoginPage), findsOneWidget);
  // Enter fake details to login to account
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
