import "package:flutter/material.dart";

import "pl_appbar.dart"; // Provides PLAppBar for the bar at the top of the screen.

class ExamPage extends StatefulWidget {
  const ExamPage(this.token, {Key? key}) : super(key: key);

  final String token;

  @override
  State<ExamPage> createState() => _ExamPageState();
}

class _ExamPageState extends State<ExamPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PLAppBar("Exams", context),
      backgroundColor: Theme.of(context).backgroundColor,
      body: const Center(
        child: Text("Hoi"),
      ),
    );
  }
}
