import 'package:auto_size_text/auto_size_text.dart';
import "package:flutter/material.dart";

import "pl_appbar.dart";

class Homework extends StatefulWidget {
  const Homework({Key? key}) : super(key: key);

  @override
  State<Homework> createState() => _HomeworkState();
}

class _HomeworkState extends State<Homework> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PLAppBar("Homework", context),
    );
  }
}
