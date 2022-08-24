import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nock/nock.dart';

import 'package:planner_app/main.dart';

void main() {
  setUpAll(nock.init);
  setUp(() {
    nock.cleanAll();
  });
  testWidgets('Registration', (WidgetTester tester) async {
    nock("http://127.0.0.1:8000").post("/api/v1/auth/register").reply(
          200,
          json.encode({"access_token": "fake_token", "token_type": "Bearer"}),
        );
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PlannerApp());

    expect(find.text('Login or Register'), findsOneWidget);

    // Verify that our counter starts at 0.
    await tester.enterText(
        find.widgetWithText(TextFormField, "Username"), "test_account");
    await tester.pump();
    await tester.enterText(
        find.widgetWithText(TextFormField, "Password"), "test_password");
    await tester.pump();

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.widgetWithText(ElevatedButton, "Register"));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('Login or Register'), findsNothing);
  });
}
