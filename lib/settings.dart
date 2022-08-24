import 'package:flutter/material.dart';
import 'package:planner_app/network.dart';

import "package:http/http.dart" as http;

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

void onLogoutResponse(http.Response dontCare) {
  Navigator.of(context).pushReplacementNamed("/");
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
      body: SizedBox(
        width: MediaQuery.of(context).size.width / 2,
        height: MediaQuery.of(context).size.height - 32,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: ElevatedButton(
                child: Row(children: const <Widget>[
                  Icon(Icons.logout_outlined),
                  Text("Logout")
                ]),
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
          ],
        ),
      ),
    );
  }
}
