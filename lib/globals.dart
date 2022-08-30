import "package:flutter/material.dart";

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

enum Permissions {
  user(0),
  teacher(1);

  final int value;
  const Permissions(this.value);
}

class User {
  User(this.uid, this.name, this.createdAt, this.permissions);

  final int uid;
  final String name;
  final DateTime createdAt;
  final Permissions permissions;
}

String token =
    ""; // We keep the token as a global variable, as this lets me use it across multiple files easily.

User? me;

void addNotif(String text, {bool error = true}) {
  ScaffoldMessenger.of(scaffoldKey.currentContext!).showSnackBar(
    SnackBar(
      content: Text(
        text,
        style:
            Theme.of(scaffoldKey.currentContext!).textTheme.bodyMedium!.apply(
                  color: error ? Colors.white : Colors.black,
                ),
        textAlign: TextAlign.center,
      ),
      backgroundColor: error
          ? Theme.of(scaffoldKey.currentContext!).errorColor
          : Theme.of(scaffoldKey.currentContext!).highlightColor,
      duration: const Duration(seconds: 3),
    ),
  );
}

String apiUrl = "http://127.0.0.1:8000";
