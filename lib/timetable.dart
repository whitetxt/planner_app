import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import "package:http/http.dart" as http;
import 'package:planner_app/globals.dart';

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
    this.day,
    this.period,
    this.data, {
    Key? key,
    this.width = 128,
    this.height = 32,
    this.borderWidth = 1,
    this.clickable = true,
  }) : super(key: key);

  final int day;
  final int period;

  final TimetableData data;
  final double width;
  final double height;
  final double borderWidth;
  final bool clickable;

  @override
  State<TimetableSlot> createState() => _TimetableSlotState();
}

class _TimetableSlotState extends State<TimetableSlot> {
  String teacher = "";
  String room = "";
  String name = "";

  Future<void> updateTimetable() async {
    addRequest(
      NetworkOperation(
        "/api/v1/subjects/name/$name",
        "GET",
        (http.Response response) {
          if (response.statusCode != 200) {
            if (response.statusCode == 500) {
              createPopup("Internal server error");
              return;
            }
            dynamic data = json.decode(response.body);
            createPopup("An error has occurred: ${data['message']}");
          }
          dynamic data = json.decode(response.body);
          if (data["status"] != "success") {
            createPopup("An error has occurred: ${data['message']}");
            return;
          }
          for (var subject in data["data"]) {
            if (subject["room"] == room && subject["teacher"] == teacher) {
              addRequest(
                NetworkOperation(
                  "/api/v1/timetable",
                  "POST",
                  (http.Response response) {
                    if (response.statusCode != 200) {
                      if (response.statusCode == 500) {
                        createPopup("Internal server error");
                        return;
                      }
                      dynamic data = json.decode(response.body);
                      createPopup("An error has occurred: ${data['message']}");
                      return;
                    }
                    dynamic data = json.decode(response.body);
                    if (data["status"] != "success") {
                      createPopup("An error has occurred: ${data['message']}");
                      return;
                    }
                    createPopup("Successfully changed timetable.");
                    setState(() {});
                  },
                  data: {
                    "subject_id": subject["subject_id"].toString(),
                    "day": widget.day.toString(),
                    "period": widget.period.toString()
                  },
                ),
              );
              return;
            }
          }
          addRequest(
            NetworkOperation(
              "/api/v1/subjects",
              "POST",
              (http.Response response) {
                if (response.statusCode != 200) {
                  if (response.statusCode == 500) {
                    createPopup("Internal server error");
                    return;
                  }
                  dynamic data = json.decode(response.body);
                  createPopup("An error has occurred: ${data['message']}");
                  return;
                }
                dynamic data = json.decode(response.body);
                if (data["status"] != "success") {
                  createPopup("An error has occurred: ${data['message']}");
                  return;
                }
                addRequest(
                  NetworkOperation(
                    "/api/v1/timetable",
                    "POST",
                    (http.Response response) {
                      if (response.statusCode != 200) {
                        if (response.statusCode == 500) {
                          createPopup("Internal server error");
                          return;
                        }
                        dynamic data = json.decode(response.body);
                        createPopup(
                            "An error has occurred: ${data['message']}");
                        return;
                      }
                      dynamic data = json.decode(response.body);
                      if (data["status"] != "success") {
                        createPopup(
                            "An error has occurred: ${data['message']}");
                        return;
                      }
                      createPopup("Successfully changed timetable.");
                      setState(() {});
                    },
                    data: {
                      "subject_id": data["id"].toString(),
                      "day": widget.day.toString(),
                      "period": widget.period.toString()
                    },
                  ),
                );
              },
              data: {
                "name": name,
                "teacher": teacher,
                "room": room,
              },
            ),
          );
        },
      ),
    );
  }

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
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text("Room: ${widget.data.room}"),
                  Text("Teacher: ${widget.data.teacher}"),
                  const Divider(thickness: 2),
                  TextButton(
                    child: const Text("Change Period"),
                    onPressed: () {
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
                              child: const Text(
                                "Changing Timetable",
                                textAlign: TextAlign.center,
                              ),
                            ),
                            content: Form(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  TextFormField(
                                    decoration: const InputDecoration(
                                      labelText: "Subject Name",
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return "Enter a name";
                                      }
                                      return null;
                                    },
                                    onChanged: (value) {
                                      name = value;
                                    },
                                    onFieldSubmitted: (String _) async {
                                      await updateTimetable();
                                    },
                                  ),
                                  TextFormField(
                                    decoration: const InputDecoration(
                                      labelText: "Teacher",
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return "Enter a teacher";
                                      }
                                      return null;
                                    },
                                    onChanged: (value) {
                                      teacher = value;
                                    },
                                    onFieldSubmitted: (String _) async {
                                      await updateTimetable();
                                    },
                                  ),
                                  TextFormField(
                                    decoration: const InputDecoration(
                                      labelText: "Room",
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return "Enter a room";
                                      }
                                      return null;
                                    },
                                    onChanged: (value) {
                                      room = value;
                                    },
                                    onFieldSubmitted: (String _) async {
                                      await updateTimetable();
                                    },
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      // Validate the form (returns true if all is ok)
                                      updateTimetable();
                                    },
                                    child: const Text('Register'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
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
    }));
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
    }));
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
                                0,
                                -1,
                                const TimetableData("Monday", "", ""),
                                width: width,
                                height: height,
                                borderWidth: borderWidth * 2,
                                clickable: false,
                              ),
                              TimetableSlot(
                                1,
                                -1,
                                const TimetableData("Tuesday", "", ""),
                                width: width,
                                height: height,
                                borderWidth: borderWidth * 2,
                                clickable: false,
                              ),
                              TimetableSlot(
                                2,
                                -1,
                                const TimetableData("Wednesday", "", ""),
                                width: width,
                                height: height,
                                borderWidth: borderWidth * 2,
                                clickable: false,
                              ),
                              TimetableSlot(
                                3,
                                -1,
                                const TimetableData("Thursday", "", ""),
                                width: width,
                                height: height,
                                borderWidth: borderWidth * 2,
                                clickable: false,
                              ),
                              TimetableSlot(
                                4,
                                -1,
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
                                  j,
                                  i,
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
