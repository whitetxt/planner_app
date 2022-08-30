import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:planner_app/pl_appbar.dart';

import 'network.dart';

class ClassPage extends StatefulWidget {
  const ClassPage({Key? key}) : super(key: key);

  @override
  State<ClassPage> createState() => _ClassPageState();
}

class _ClassPageState extends State<ClassPage> {
  @override
  Widget build(BuildContext context) {
    if (!onlineMode) {
      return Scaffold(
        appBar: PLAppBar("Classes", context),
        backgroundColor: Theme.of(context).backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const <Widget>[
              AutoSizeText(
                "Unfortunately, you are offline.",
                style: TextStyle(
                  fontSize: 24,
                ),
              ),
              AutoSizeText(
                "Classes cannot be managed without an internet connection.",
                style: TextStyle(
                  fontSize: 24,
                ),
              ),
              AutoSizeText(
                "Please try again later.",
                style: TextStyle(
                  fontSize: 24,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: PLAppBar("Classes", context),
      backgroundColor: Theme.of(context).backgroundColor,
      body: ListView(
        children: [
          Row(),
          ExpansionTile(title: Text("Hello")),
        ],
      ),
    );
  }
}
