import "package:flutter/material.dart";

import "pl_appbar.dart"; // Provides PLAppBar for the bar at the top of the screen.
import "timetable.dart"; // Provides TodayTimetable
import "homework.dart"; // Provides HomeworkMini
import "calendar.dart"; // Provides EventsMini

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PLAppBar("Dashboard", context),
      backgroundColor: Theme.of(context).backgroundColor,
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const <Widget>[
                HomeworkMini(),
                EventsMini(),
                TodayTimetable(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
