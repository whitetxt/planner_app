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
    mockApis(apiUrl);
  });

  testWidgets('Erroneous | Username Validation', (WidgetTester tester) async {
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

  testWidgets('Erroneous | Password Length Validation',
      (WidgetTester tester) async {
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

  testWidgets('Erroneous | Password Number Validation',
      (WidgetTester tester) async {
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

  testWidgets('Normal | Registration Cancel', (WidgetTester tester) async {
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

  testWidgets('Normal | Registration', (WidgetTester tester) async {
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

  testWidgets('Boundary | Password Length', (WidgetTester tester) async {
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

  testWidgets('Normal | Login', (WidgetTester tester) async {
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
}
