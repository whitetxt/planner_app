import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import "package:http/http.dart" as http;
import 'package:planner_app/globals.dart';
import 'package:shared_preferences/shared_preferences.dart';

import "package:flutter_colorpicker/flutter_colorpicker.dart";

import "pl_appbar.dart"; // Provides PLAppBar for the bar at the top of the screen.
import "network.dart"; // Allows network requests on this page.

class TimetableData {
  const TimetableData(this.name, this.teacher, this.room, this.colour);

  final String name;
  final String teacher;
  final String room;
  final String colour;
}

List<List<TimetableData>> timetable = [[], [], [], [], []];
DateTime lastFetchTime = DateTime.now();

List<TimetableData> subjects = [];

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
    this.reset,
  }) : super(key: key);

  final int day;
  final int period;

  final TimetableData data;
  final double width;
  final double height;
  final double borderWidth;
  final bool clickable;

  // Function passed must force the parent element to reset its state.
  final Function()? reset;

  @override
  State<TimetableSlot> createState() => _TimetableSlotState();
}

class _TimetableSlotState extends State<TimetableSlot> {
  final _formKey = GlobalKey<FormState>();

  String teacher = "";
  String room = "";
  String name = "";
  String colour = "#ffffff";
  Color realColour = const Color(0xFFFFFFFF);

  void resetStates() {
    Navigator.of(context).popUntil(ModalRoute.withName("/dash"));
    if (widget.reset != null) {
      widget.reset!();
    }
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
                  Text(
                    "Room: ${widget.data.room.isEmpty ? 'None' : widget.data.room}",
                  ),
                  Text(
                    "Teacher: ${widget.data.teacher.isEmpty ? 'None' : widget.data.teacher}",
                  ),
                ],
              ),
            );
          },
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(4),
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
                  Expanded(
                    child: Center(
                      child: AutoSizeText(
                        widget.data.name,
                        textAlign: TextAlign.center,
                        minFontSize: 5,
                        maxFontSize: 16,
                        stepGranularity: 0.1,
                        maxLines: 3,
                        semanticsLabel: widget.data.name,
                        wrapWords: false,
                      ),
                    ),
                  ),
                ],
              ),
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
          timetable[i].add(
              const TimetableData("Loading", "Loading", "Loading", "#ffffff"));
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
    if (today >= DateTime.saturday) {
      // If Sat or Sun
      return SizedBox(
        width: 15 * MediaQuery.of(context).size.width / 16,
        height: MediaQuery.of(context).size.height / 4,
        child: Card(
          elevation: 4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const <Widget>[
              Text(
                "No lessons today!",
                style: TextStyle(
                  fontSize: 32,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    today--;
    return SizedBox(
      width: 15 * MediaQuery.of(context).size.width / 16,
      height: MediaQuery.of(context).size.height / 4,
      child: Card(
        elevation: 4,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const Text(
              "Today's Timetable",
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            const Divider(
              indent: 4,
              endIndent: 4,
            ),
            Expanded(
              child: ListView(
                children: [
                  for (int idx = 0; idx < timetable[today].length; idx++)
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text("Period ${idx + 1}"),
                          Text(timetable[today][idx].name),
                        ],
                      ),
                    ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

Future<void> gotTimetable(http.Response response) async {
  if (response.statusCode != 200) return;
  Map<String, dynamic> data = json.decode(response.body);
  for (var i = 0; i < data["data"].length; i++) {
    var today = data["data"][i];
    for (var j = 0; j < today.length; j++) {
      var period = today[j];
      if (period == null) {
        timetable[i][j] = const TimetableData("None", "None", "None", "None");
      } else {
        timetable[i][j] = TimetableData(
          period["name"],
          period["teacher"],
          period["room"],
          period["colour"],
        );
      }
    }
  }
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString("timetable", json.encode(data["data"]));
}

class SubjectWidget extends StatelessWidget {
  const SubjectWidget(this.subject, {Key? key}) : super(key: key);

  final TimetableData subject;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Color(
        int.parse(subject.colour.substring(1, 7), radix: 16) + 0xFF000000,
      ),
      child: Column(
        children: [
          Text(subject.name),
          Text(subject.teacher),
          Text(subject.room),
        ],
      ),
    );
  }
}

class TimetablePage extends StatefulWidget {
  const TimetablePage({Key? key}) : super(key: key);

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String teacher = "";
  String room = "";
  String name = "";
  Color colour = const Color.fromARGB(255, 255, 255, 255);

  void getTimetable() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedTimetable = prefs.getString("timetable");
    if (storedTimetable != null) {
      List<dynamic> data = json.decode(storedTimetable);
      for (var i = 0; i < data.length; i++) {
        var today = data[i];
        for (var j = 0; j < today.length; j++) {
          var period = today[j];
          if (period == null) {
            timetable[i][j] =
                const TimetableData("None", "None", "None", "#FFFFFF");
          } else {
            timetable[i][j] = TimetableData(
              period["name"],
              period["teacher"],
              period["room"],
              period["colour"],
            );
          }
        }
      }
      setState(() {});
    }
    addRequest(
      NetworkOperation(
        "/api/v1/timetable",
        "GET",
        (http.Response response) async {
          await gotTimetable(response);
          setState(() {});
        },
      ),
    );
  }

  void onColourChanged(Color color) {
    colour = color.withAlpha(255);
  }

  void createSubject() {
    addRequest(
      NetworkOperation(
        "/api/v1/subjects",
        "POST",
        (http.Response response) async {
          await gotTimetable(response);
          setState(() {});
        },
        data: {
          "name": name,
          "teacher": teacher,
          "room": room,
          "colour": colour.value.toRadixString(16),
        },
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  void initState() {
    if (timetable[0].length != 9) {
      for (var i = 0; i < 5; i++) {
        for (var j = 0; j < 9; j++) {
          timetable[i].add(
              const TimetableData("Loading", "Loading", "Loading", "#FFFFFF"));
        }
      }
    }
    getTimetable();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double borderWidth = 1;
    double width =
        MediaQuery.of(context).size.width / 6 - (borderWidth * 2 + borderWidth);
    double height =
        MediaQuery.of(context).size.height / (timetable[0].length + 4) -
            (borderWidth * 2 + borderWidth);
    height *= 1.25;
    double indent = 16;
    return Scaffold(
      appBar: PLAppBar("Timetable", context),
      backgroundColor: Theme.of(context).backgroundColor,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8),
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    backgroundColor: Theme.of(context).highlightColor,
                    side: const BorderSide(color: Colors.black),
                  ),
                  icon: const Icon(Icons.add, color: Colors.black),
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
                              "Creating Subject",
                              textAlign: TextAlign.center,
                            ),
                          ),
                          content: Form(
                            key: _formKey,
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
                                  onFieldSubmitted: (String _) {
                                    createSubject();
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
                                  onFieldSubmitted: (String _) {
                                    createSubject();
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
                                  onFieldSubmitted: (String _) {
                                    createSubject();
                                  },
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: ColorPicker(
                                    pickerColor: colour,
                                    onColorChanged: onColourChanged,
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    // Validate the form (returns true if all is ok)
                                    if (_formKey.currentState!.validate()) {
                                      createSubject();
                                    }
                                  },
                                  child: const Text('Create'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  label: const Text(
                    "New",
                    style: TextStyle(
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              ...[
                for (TimetableData subject in subjects) SubjectWidget(subject),
              ],
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              TimetableSlot(
                0,
                -1,
                TimetableData(
                  "Monday",
                  "",
                  "",
                  "#${Theme.of(context).highlightColor.value.toRadixString(16)}",
                ),
                width: width,
                height: height,
                borderWidth: borderWidth * 2,
                clickable: false,
              ),
              TimetableSlot(
                1,
                -1,
                TimetableData(
                  "Tuesday",
                  "",
                  "",
                  "#${Theme.of(context).highlightColor.value.toRadixString(16)}",
                ),
                width: width,
                height: height,
                borderWidth: borderWidth * 2,
                clickable: false,
              ),
              TimetableSlot(
                2,
                -1,
                TimetableData(
                  "Wednesday",
                  "",
                  "",
                  "#${Theme.of(context).highlightColor.value.toRadixString(16)}",
                ),
                width: width,
                height: height,
                borderWidth: borderWidth * 2,
                clickable: false,
              ),
              TimetableSlot(
                3,
                -1,
                TimetableData(
                  "Thursday",
                  "",
                  "",
                  "#${Theme.of(context).highlightColor.value.toRadixString(16)}",
                ),
                width: width,
                height: height,
                borderWidth: borderWidth * 2,
                clickable: false,
              ),
              TimetableSlot(
                4,
                -1,
                TimetableData(
                  "Friday",
                  "",
                  "",
                  "#${Theme.of(context).highlightColor.value.toRadixString(16)}",
                ),
                width: width,
                height: height,
                borderWidth: borderWidth * 2,
                clickable: false,
              ),
            ],
          ),
          Divider(
            indent: indent,
            endIndent: indent,
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return ListView(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        for (int period = 0;
                            period < timetable[0].length && period < 4;
                            period++)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              for (int day = 0; day < timetable.length; day++)
                                TimetableSlot(
                                  day,
                                  period,
                                  timetable[day][period],
                                  width: width,
                                  height: height,
                                  borderWidth: borderWidth,
                                  reset: getTimetable,
                                ),
                            ],
                          ),
                        Divider(
                          indent: indent,
                          endIndent: indent,
                        ),
                        for (int period = 4;
                            period < timetable[0].length && period < 6;
                            period++)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              for (int day = 0; day < timetable.length; day++)
                                TimetableSlot(
                                  day,
                                  period,
                                  timetable[day][period],
                                  width: width,
                                  height: height,
                                  borderWidth: borderWidth,
                                  reset: getTimetable,
                                ),
                            ],
                          ),
                        Divider(
                          indent: indent,
                          endIndent: indent,
                        ),
                        for (int period = 6;
                            period < timetable[0].length;
                            period++)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              for (int day = 0; day < timetable.length; day++)
                                TimetableSlot(
                                  day,
                                  period,
                                  timetable[day][period],
                                  width: width,
                                  height: height,
                                  borderWidth: borderWidth,
                                  reset: getTimetable,
                                ),
                            ],
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
