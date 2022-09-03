import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:planner_app/network.dart';

import "package:http/http.dart" as http;

import "globals.dart";

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

void onLogoutResponse(http.Response _) {
  // When we logout, we don't care if it failed or succeeded,
  // just throw away our token and go back to the login screen.
  token = "";
  navigatorKey.currentState!.pushNamedAndRemoveUntil("/", (_) => false);
}

void onResetResponse(http.Response response) {
  if (!validateResponse(response)) return;
  dynamic data = json.decode(response.body);
  if (data["status"] != "success") {
    addNotif(data["message"], error: true);
    return;
  }
  addNotif(
    "Successfully reset user data!",
    error: false,
  );
}

void onDeleteResponse(http.Response response) {
  if (!validateResponse(response)) return;
  dynamic data = json.decode(response.body);
  if (data["status"] != "success") {
    // If it failed, then don't logout since the account may not be fully deleted.
    addNotif(data["message"], error: true);
    return;
  }
  ScaffoldMessenger.of(scaffoldKey.currentContext!).clearSnackBars();
  addNotif(
    "Successfully deleted account!",
    error: false,
  );
  token = "";
  navigatorKey.currentState!.pushNamedAndRemoveUntil("/", (_) => false);
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(32),
        child: AppBar(
          title: const Center(
            child: Text("Settings"),
          ),
        ),
      ),
      backgroundColor: Theme.of(context).backgroundColor,
      body: SizedBox(
        height: MediaQuery.of(context).size.height - 32,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: ElevatedButton.icon(
                  // Use an icon with text next to it for the button.
                  icon: const Icon(Icons.logout),
                  label: const Text("Logout"),
                  onPressed: () {
                    addRequest(
                      NetworkOperation(
                        "/api/v1/auth/logout",
                        "GET",
                        onLogoutResponse,
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: ElevatedButton.icon(
                  icon: const Icon(
                    Icons.refresh,
                  ),
                  label: const Text(
                    "Reset Data",
                  ),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade900),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        // Since this is an important action, I show this dialog to warn the user
                        // that this cannot be undone, and is dangerous.
                        return AlertDialog(
                          backgroundColor: Colors.red.shade400,
                          title: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Theme.of(context).dividerColor,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.warning_rounded,
                                ),
                                Text(
                                  "WARNING!",
                                ),
                              ],
                            ),
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const Text(
                                "Are you sure you want to reset all data?",
                              ),
                              const Text(
                                "THIS ACTION CANNOT BE UNDONE!",
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                child: ElevatedButton(
                                  child: const Text(
                                    "Don't do it! Take me back!",
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                child: ElevatedButton(
                                  child: const Text(
                                    "Yes, I know what I'm doing.",
                                  ),
                                  onPressed: () {
                                    addRequest(
                                      NetworkOperation(
                                        "/api/v1/users/reset",
                                        "POST",
                                        onResetResponse,
                                      ),
                                    );
                                    Navigator.of(context).pop();
                                    addNotif(
                                      "This may take a while. Please be patient",
                                      error: false,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: ElevatedButton.icon(
                  icon: const Icon(
                    Icons.delete_forever_rounded,
                  ),
                  label: const Text(
                    "Delete Account",
                  ),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade900),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          backgroundColor: Colors.red.shade400,
                          title: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Theme.of(context).dividerColor,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.warning_rounded,
                                ),
                                Text(
                                  "WARNING!",
                                ),
                              ],
                            ),
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const Text(
                                "Are you sure you want to delete your account?",
                              ),
                              const Text(
                                "THIS ACTION CANNOT BE UNDONE!",
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                child: ElevatedButton(
                                  child: const Text(
                                    "Don't do it! Take me back!",
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                child: ElevatedButton(
                                  child: const Text(
                                    "Yes, I know what I'm doing.",
                                  ),
                                  onPressed: () {
                                    addRequest(
                                      NetworkOperation(
                                        "/api/v1/users/@me",
                                        "DELETE",
                                        onDeleteResponse,
                                      ),
                                    );
                                    Navigator.of(context).pop();
                                    addNotif(
                                      "This may take a while. Please be patient",
                                      error: false,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
