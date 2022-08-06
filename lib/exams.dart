import "package:flutter/material.dart";

import "pl_appbar.dart";

class ExamPage extends StatefulWidget {
  const ExamPage({Key? key}) : super(key: key);

  @override
  State<ExamPage> createState() => _ExamPageState();
}

class _ExamPageState extends State<ExamPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PLAppBar("Exams", context),
      backgroundColor: Theme.of(context).backgroundColor,
      body: Center(
        child: Text("Hoi"),
      ),
    );
  }
}
