import 'package:flutter/material.dart';
import 'package:planner_app/network.dart';

import 'package:http/http.dart' as http;
import 'package:planner_app/notifs.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'globals.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

Future<void> onLogoutResponse(http.Response _) async {
  // When we logout, we don't care if it failed or succeeded,
  // just throw away our token and go back to the login screen.
  token = '';
  me = null;
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('token');
  addNotif('Successfully logged out!', error: false);
  navigatorKey.currentState!.pushNamedAndRemoveUntil('/', (_) => false);
}

void onResetResponse(http.Response response) {
  if (!validateResponse(response)) return;
  // If the reset was successful, alert the user.
  addNotif('Successfully reset user data!', error: false);
  navigatorKey.currentState!.popUntil(ModalRoute.withName('/dash'));
}

void onDeleteResponse(http.Response response) {
  if (!validateResponse(response)) return;
  // If everything was OK, then tell the user and go back to the login screen.
  ScaffoldMessenger.of(currentScaffoldKey.currentContext!).clearSnackBars();
  addNotif('Successfully deleted account!', error: false);
  token = '';
  me = null;
  // Remove all of the previous navigation menus, so that a back arrow doesn't appear.
  navigatorKey.currentState!.pushReplacementNamed('/');
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(32),
        child: AppBar(
          title: const Center(
            child: Text('Settings'),
          ),
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
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
                  label: const Text('Logout'),
                  onPressed: () {
                    addRequest(
                      NetworkOperation(
                        '/api/v1/auth/logout',
                        'GET',
                        onLogoutResponse,
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade900,
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        // Since this is an important action, show this dialog to warn the user
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
                                Icon(Icons.warning),
                                Text('WARNING!'),
                              ],
                            ),
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const Text(
                                'Are you sure you want to reset all data?',
                              ),
                              const Text(
                                'THIS ACTION CANNOT BE UNDONE!',
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
                                    // Remove the popup and don't do anything.
                                    addNotif('Cancelled resetting data',
                                        error: false);
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
                                    // Tell the server that we want to reset our account,
                                    // And then tell the user that we are waiting on a
                                    // response from the server.
                                    addRequest(
                                      NetworkOperation(
                                        '/api/v1/users/reset',
                                        'POST',
                                        onResetResponse,
                                      ),
                                    );
                                    Navigator.of(context).pop();
                                    addNotif(
                                      'This may take a while. Please be patient',
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
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Delete Account'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade900,
                  ),
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
                                Icon(Icons.warning),
                                Text('WARNING!'),
                              ],
                            ),
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const Text(
                                'Are you sure you want to delete your account?',
                              ),
                              const Text(
                                'THIS ACTION CANNOT BE UNDONE!',
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
                                    addNotif('Cancelled deleting account',
                                        error: false);
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
                                    Navigator.of(context).pop();
                                    addRequest(
                                      NetworkOperation(
                                        '/api/v1/users/@me',
                                        'DELETE',
                                        onDeleteResponse,
                                      ),
                                    );
                                    addNotif(
                                      'This may take a while. Please be patient',
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
