import 'package:flutter/material.dart';

// These keys are used to keep a hold of the current navigator and scaffold.
// The navigator key is used to close dialogs without needing the BuildContext.
// The scaffold key is used to get the current context without needing the BuildContext.
GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
GlobalKey<ScaffoldState> loginScaffoldKey = GlobalKey<ScaffoldState>();
GlobalKey<ScaffoldState> mainScaffoldKey = GlobalKey<ScaffoldState>();
GlobalKey<ScaffoldState> currentScaffoldKey = loginScaffoldKey;

// These variables allow me to control things with the notification system.
int initialTabIndex = 2;
bool notificationsEnabled = false;
int lastNotificationID = 0;

enum Permissions {
  // We create an enum here to hold user's permissions.
  // These variables can be accessed with Permissions.user or Permissions.teacher.
  user(0),
  teacher(1);

  final int value;
  const Permissions(this.value);
}

class User {
  User(this.uid, this.name, this.createdAt, this.permissions);

  final int? uid;
  final String name;
  final DateTime createdAt;
  final Permissions permissions;

  factory User.fromJson(Map<String, dynamic> data) {
    // Converts server's json data into a User object.
    return User(
      data['uid'],
      data['username'],
      DateTime.fromMillisecondsSinceEpoch(data['created_at']),
      Permissions.values[data['permissions']],
    );
  }
}

String token =
    ''; // We keep the token as a global variable, as this lets me use it across multiple files easily.

User? me; // Keep a version of us on hand, for whenever we might need it.

void addNotif(String text, {bool error = true}) {
  // This function is used to display something to the user.
  if (currentScaffoldKey.currentContext == null) {
    // This shouldn't ever be null but it could be.
    return;
  }
  ScaffoldMessenger.of(currentScaffoldKey.currentContext!).showSnackBar(
    SnackBar(
      content: Text(
        text,
        style: Theme.of(currentScaffoldKey.currentContext!)
            .textTheme
            .bodyMedium!
            .apply(
              // Change the text colour based on if the background is red or blue.
              // This is to increase contrast and make the text easier to read.
              color: error ? Colors.white : Colors.black,
            ),
        textAlign: TextAlign.center,
      ),
      backgroundColor: error
          // We change the background colour if this message is an error.
          ? Theme.of(currentScaffoldKey.currentContext!).colorScheme.error
          : Theme.of(currentScaffoldKey.currentContext!).highlightColor,
      duration: const Duration(seconds: 3),
    ),
  );
}

// This is used to tell the entire program where the server is hosted.
// It will easily let me change it in the event of losing a domain.
// DuckDNS is a service used to get free domains, which I am using here as to
// make it easy to recognise.
//const String apiUrl = 'https://planner-app.duckdns.org';

// Localhost debug server.
const String apiUrl = 'http://127.0.0.1:8000';
