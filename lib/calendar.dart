import "package:flutter/material.dart";

import "pl_appbar.dart";

class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PLAppBar("Calendar", context),
      backgroundColor: Theme.of(context).backgroundColor,
      body: Center(
        child: Text("Hello"),
      ),
    );
  }
}
