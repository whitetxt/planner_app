import 'package:auto_size_text/auto_size_text.dart';
import "package:flutter/material.dart";

import "pl_appbar.dart";

class HomeworkData {
  HomeworkData(this.timeDue, this.name, this.teacher, this.subject);

  final DateTime timeDue;
  final String name;
  final String teacher;
  final String subject;

  factory HomeworkData.fromJson(dynamic jsonData) {
    return HomeworkData(
      DateTime.fromMillisecondsSinceEpoch(jsonData["timeDue"]),
      jsonData["name"],
      jsonData["teacher"],
      jsonData["subject"],
    );
  }
}

class HomeworkPage extends StatefulWidget {
  const HomeworkPage({Key? key}) : super(key: key);

  @override
  State<HomeworkPage> createState() => _HomeworkPageState();
}

class _HomeworkPageState extends State<HomeworkPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PLAppBar("Homework", context),
    );
  }
}
