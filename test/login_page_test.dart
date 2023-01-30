import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:planner_app/main.dart';
import 'package:planner_app/login.dart';

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
    testWidgets('Registration Cancel', (WidgetTester tester) async {
      mockApis(apiUrl);
      await tester.pumpWidget(const PlannerApp());

      // Enter fake details to "create" fake account
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'), 'test_account');
      await tester.pumpAndSettle();

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

    testWidgets('Registration', (WidgetTester tester) async {
      mockApis(apiUrl);
      await tester.pumpWidget(const PlannerApp());

      // Enter fake details to "create" fake account
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'), 'test_account');
      await tester.pumpAndSettle();

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

    testWidgets('Registration with registration code',
        (WidgetTester tester) async {
      mockApis(apiUrl);
      await tester.pumpWidget(const PlannerApp());

      // Enter fake details to "create" fake account
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'), 'test_account');
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'testpassword123');
      await tester.pumpAndSettle();

      // Press the register button.
      await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
      await tester.pumpAndSettle();

      // Use no registration code.
      await tester.enterText(
          find.widgetWithText(TextField, 'Registration Code'), 'abcd');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
      await tester.pumpAndSettle();

      expect(find.byType(MainPage), findsOneWidget);
      expect(find.byType(LoginPage), findsNothing);
    });

    testWidgets('Login', (WidgetTester tester) async {
      mockApis(apiUrl);
      await tester.pumpWidget(const PlannerApp());

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

    testWidgets('Login using enter key on username field',
        (WidgetTester tester) async {
      mockApis(apiUrl);
      await tester.pumpWidget(const PlannerApp());

      // Enter fake details to "create" fake account
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'testpassword123');
      await tester.pumpAndSettle();

      // Enter username second so that it is active when enter is pressed.
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'), 'test_account');
      await tester.pumpAndSettle();

      // Tell the text inputs that we have pressed enter.
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.byType(MainPage), findsOneWidget);
      expect(find.byType(LoginPage), findsNothing);
    });

    testWidgets('Login using enter key on password field',
        (WidgetTester tester) async {
      mockApis(apiUrl);
      await tester.pumpWidget(const PlannerApp());

      // Enter fake details to "create" fake account
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'), 'test_account');
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'testpassword123');
      await tester.pumpAndSettle();

      // Tell the text inputs that we have pressed enter.
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.byType(MainPage), findsOneWidget);
      expect(find.byType(LoginPage), findsNothing);
    });
  });
  group('Erroneous Data', () {
    testWidgets('Username Validation', (WidgetTester tester) async {
      mockApis(apiUrl);
      await tester.pumpWidget(const PlannerApp());

      // Test if it checks for
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'testpassword123');
      await tester.pumpAndSettle();

      // Press the register button.
      await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a username'), findsOneWidget);
    });

    testWidgets('Password Length Validation', (WidgetTester tester) async {
      mockApis(apiUrl);
      await tester.pumpWidget(const PlannerApp());

      // Enter fake details to "create" fake account
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'), 'test_account');
      await tester.pumpAndSettle();
      // Test if it checks for length
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'testp');
      await tester.pumpAndSettle();

      // Press the register button.
      await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
      await tester.pumpAndSettle();
      expect(find.text('Password must be at least 8 characters long.'),
          findsOneWidget);
    });

    testWidgets('Password Number Validation', (WidgetTester tester) async {
      mockApis(apiUrl);
      await tester.pumpWidget(const PlannerApp());

      // Enter fake details to "create" fake account
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'), 'test_account');
      await tester.pumpAndSettle();
      // Test if it checks for numbers
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'testpassword');
      await tester.pumpAndSettle();

      // Press the register button.
      await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
      await tester.pumpAndSettle();
      expect(find.text('Password must contain a number.'), findsOneWidget);
    });

    testWidgets('Registration Server 500 Response',
        (WidgetTester tester) async {
      mockApis(apiUrl, register: false);
      nock(apiUrl)
          .post(
            '/auth/register',
          )
          .reply(500, 'Whoops! Something went wrong.');
      await tester.pumpWidget(const PlannerApp());

      // Enter fake details to "create" fake account
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'), 'test_account');
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'testpassword123');
      await tester.pumpAndSettle();

      // Press the register button.
      await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
      await tester.pumpAndSettle();
      // Use no registration code.
      await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('Registration Connection Error', (WidgetTester tester) async {
      mockApis(apiUrl, register: false);
      nock(apiUrl)
          .post(
            '/auth/register',
          )
          .reply(999, "Couldn't connect");
      await tester.pumpWidget(const PlannerApp());

      // Enter fake details to "create" fake account
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'), 'test_account');
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'testpassword123');
      await tester.pumpAndSettle();

      // Press the register button.
      await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
      await tester.pumpAndSettle();
      // Use no registration code.
      await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('Registration Generic Error', (WidgetTester tester) async {
      mockApis(apiUrl, register: false);
      nock(apiUrl)
          .post(
            '/auth/register',
          )
          .reply(
            404,
            json.encode({
              'detail': 'Not Found.',
            }),
          );
      await tester.pumpWidget(const PlannerApp());

      // Enter fake details to "create" fake account
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'), 'test_account');
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'testpassword123');
      await tester.pumpAndSettle();

      // Press the register button.
      await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
      await tester.pumpAndSettle();
      // Use no registration code.
      await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('Login Server 500 Response', (WidgetTester tester) async {
      mockApis(apiUrl, login: false);
      nock(apiUrl)
          .post(
            '/auth/login',
          )
          .reply(500, 'Whoops! Something went wrong.');
      await tester.pumpWidget(const PlannerApp());

      // Enter fake details to "create" fake account
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'), 'test_account');
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'testpassword123');
      await tester.pumpAndSettle();

      // Press the register button.
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('Login Connection Error', (WidgetTester tester) async {
      mockApis(apiUrl, login: false);
      nock(apiUrl)
          .post(
            '/auth/login',
          )
          .reply(999, "Couldn't connect");
      await tester.pumpWidget(const PlannerApp());

      // Enter fake details to "create" fake account
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'), 'test_account');
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'testpassword123');
      await tester.pumpAndSettle();

      // Press the register button.
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('Login Generic Error', (WidgetTester tester) async {
      mockApis(apiUrl, login: false);
      nock(apiUrl)
          .post(
            '/auth/login',
          )
          .reply(
            404,
            json.encode({
              'detail': 'Not Found.',
            }),
          );
      await tester.pumpWidget(const PlannerApp());

      // Enter fake details to "create" fake account
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'), 'test_account');
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'testpassword123');
      await tester.pumpAndSettle();

      // Press the register button.
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);
    });
  });
  group('Boundary Data', () {
    testWidgets('Password Length', (WidgetTester tester) async {
      mockApis(apiUrl);
      await tester.pumpWidget(const PlannerApp());

      // Enter fake details to "create" fake account
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'), 'test_account');
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'testpas1');
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
  });
}
