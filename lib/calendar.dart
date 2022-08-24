import "package:flutter/material.dart";

import "pl_appbar.dart"; // Provides PLAppBar for the bar at the top of the screen.

class EventsMini extends StatefulWidget {
  const EventsMini({Key? key}) : super(key: key);

  @override
  State<EventsMini> createState() => _EventsMiniState();
}

class _EventsMiniState extends State<EventsMini> {
  @override
  Widget build(BuildContext context) {
    return Container(child: const Text("hello event mini"));
  }
}

class CalendarPage extends StatefulWidget {
  const CalendarPage(this.token, {Key? key}) : super(key: key);

  final String token;

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PLAppBar("Calendar", context),
      backgroundColor: Theme.of(context).backgroundColor,
      body: const Center(
        child: Text("Hello"),
      ),
    );
  }
}
