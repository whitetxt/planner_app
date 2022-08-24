import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import "package:http/http.dart" as http;

import "pl_appbar.dart"; // Provides PLAppBar for the bar at the top of the screen.
import "network.dart"; // Allows network requests on this page.

class TimetableData {
  const TimetableData(this.name, this.teacher, this.room);

  final String name;
  final String teacher;
  final String room;
}

List<List<TimetableData>> timetable = [[], [], [], [], []];
DateTime lastFetchTime = DateTime.now();

class TimetableSlot extends StatefulWidget {
  const TimetableSlot(
    this.data, {
    Key? key,
    this.width = 128,
    this.height = 32,
    this.borderWidth = 1,
    this.clickable = true,
  }) : super(key: key);

  final TimetableData data;
  final double width;
  final double height;
  final double borderWidth;
  final bool clickable;

  @override
  State<TimetableSlot> createState() => _TimetableSlotState();
}

class _TimetableSlotState extends State<TimetableSlot> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!widget.clickable) return;
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  widget.data.name,
                  textAlign: TextAlign.center,
                ),
              ),
              content: Text(
                  "Room: ${widget.data.room}\nTeacher: ${widget.data.teacher}"),
            );
          },
        );
      },
      child: Material(
        elevation: 2,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).highlightColor,
            border: Border.all(
              color: Theme.of(context).bottomAppBarTheme.color!,
              width: widget.borderWidth,
            ),
            borderRadius: BorderRadius.circular(widget.borderWidth / 2),
          ),
          child: SizedBox(
            width: widget.width,
            height: widget.height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                AutoSizeText(
                  widget.data.name,
                  textAlign: TextAlign.center,
                  minFontSize: 6,
                  maxFontSize: 16,
                  maxLines: 2,
                  semanticsLabel: widget.data.name,
                  wrapWords: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TodayTimetable extends StatefulWidget {
  const TodayTimetable({Key? key}) : super(key: key);

  @override
  State<TodayTimetable> createState() => _TodayTimetableState();
}

class _TodayTimetableState extends State<TodayTimetable> {
  @override
  void initState() {
    if (timetable[0].length != 9) {
      for (var i = 0; i < 5; i++) {
        for (var j = 0; j < 9; j++) {
          timetable[i]
              .add(const TimetableData("Loading", "Loading", "Loading"));
        }
      }
    }
    addRequest(
        NetworkOperation("/api/v1/timetable", "GET", (http.Response response) {
      gotTimetable(response);
      setState(() {});
    }, priority: 2));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    int today = DateTime.now().weekday;
    if (today >= 6) {
      // If Sat or Sun
      return Card(
        elevation: 4,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const <Widget>[
            AutoSizeText(
              "No lessons today.",
              minFontSize: 8,
              maxFontSize: 32,
            ),
          ],
        ),
      );
    }
    today--;
    return SizedBox(
      width: 15 * MediaQuery.of(context).size.width / 16,
      child: Card(
        elevation: 4,
        child: Column(
          children: <Widget>[
            const Text("Today's Timetable"),
            const Divider(
              indent: 4,
              endIndent: 4,
            ),
            ...[
              for (int idx = 0; idx < timetable[today].length; idx++)
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text("Period ${idx + 1}"),
                      Text(timetable[today][idx].name),
                    ],
                  ),
                ),
            ]
          ],
        ),
      ),
    );
  }
}

void gotTimetable(http.Response response) {
  if (response.statusCode != 200) {
    print(response.body);
    return;
  }
  Map<String, dynamic> data = json.decode(response.body);
  for (var i = 0; i < data["data"].length; i++) {
    var today = data["data"][i];
    for (var j = 0; j < today.length; j++) {
      var period = today[j];
      if (period == null) {
        timetable[i][j] = const TimetableData("Invalid", "Invalid", "Invalid");
      } else {
        timetable[i][j] =
            TimetableData(period["name"], period["teacher"], period["room"]);
      }
    }
  }
}

class TimetablePage extends StatefulWidget {
  const TimetablePage(this.token, {Key? key}) : super(key: key);

  final String token;

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  @override
  void initState() {
    if (timetable[0].length != 9) {
      for (var i = 0; i < 5; i++) {
        for (var j = 0; j < 9; j++) {
          timetable[i]
              .add(const TimetableData("Loading", "Loading", "Loading"));
        }
      }
    }
    addRequest(
        NetworkOperation("/api/v1/timetable", "GET", (http.Response response) {
      gotTimetable(response);
      setState(() {});
    }, priority: 2));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PLAppBar("Timetable", context),
      backgroundColor: Theme.of(context).backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Material(
              elevation: 4,
              borderRadius: const BorderRadius.all(
                Radius.circular(8),
              ),
              child: Container(
                width: 15 * MediaQuery.of(context).size.width / 16,
                height: 3 * MediaQuery.of(context).size.height / 4,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.white,
                    width: 8,
                  ),
                  borderRadius: const BorderRadius.all(
                    Radius.circular(8),
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    double borderWidth = 1;
                    double width = constraints.maxWidth / 6 -
                        (borderWidth * 2 + borderWidth);
                    double height =
                        constraints.maxHeight / (timetable[0].length + 2) -
                            (borderWidth * 2 + borderWidth);
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              TimetableSlot(
                                const TimetableData("Monday", "", ""),
                                width: width,
                                height: height,
                                borderWidth: borderWidth * 2,
                                clickable: false,
                              ),
                              TimetableSlot(
                                const TimetableData("Tuesday", "", ""),
                                width: width,
                                height: height,
                                borderWidth: borderWidth * 2,
                                clickable: false,
                              ),
                              TimetableSlot(
                                const TimetableData("Wednesday", "", ""),
                                width: width,
                                height: height,
                                borderWidth: borderWidth * 2,
                                clickable: false,
                              ),
                              TimetableSlot(
                                const TimetableData("Thursday", "", ""),
                                width: width,
                                height: height,
                                borderWidth: borderWidth * 2,
                                clickable: false,
                              ),
                              TimetableSlot(
                                const TimetableData("Friday", "", ""),
                                width: width,
                                height: height,
                                borderWidth: borderWidth * 2,
                                clickable: false,
                              ),
                            ],
                          ),
                        ],
                        for (int i = 0; i < timetable[0].length; i++)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              for (int j = 0; j < timetable.length; j++)
                                TimetableSlot(
                                  timetable[j][i],
                                  width: width,
                                  height: height,
                                  borderWidth: borderWidth,
                                ),
                            ],
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
