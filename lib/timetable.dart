import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import "pl_appbar.dart"; // Provides PLAppBar for the bar at the top of the screen.

List<List<String>> sampleTimetableData = [
  [
    "Applied Maths",
    "Applied Maths",
    "Free",
    "Free",
    "Free",
    "Free",
    "Computer Science",
    "Free",
    "Free",
  ],
  [
    "Computer Science",
    "Computer Science",
    "Free",
    "Free",
    "Physics",
    "Physics",
    "Games",
    "Games",
    "Games",
  ],
  [
    "Pure Maths",
    "Pure Maths",
    "Free",
    "Free",
    "Physics",
    "Physics",
    "Applied Maths",
    "Free",
    "Free",
  ],
  [
    "Physics",
    "Physics",
    "Free",
    "Free",
    "Pure Maths",
    "Pure Maths",
    "Computer Science",
    "Computer Science",
    "Computer Science",
  ],
  [
    "Pure Maths",
    "Pure Maths",
    "Physics",
    "Physics",
    "Free",
    "Free",
    "Free",
    "Computer Science",
    "Computer Science",
  ],
];

class TimetableSlot extends StatefulWidget {
  const TimetableSlot(
    this.text, {
    Key? key,
    this.width = 128,
    this.height = 32,
    this.borderWidth = 1,
    this.clickable = true,
  }) : super(key: key);

  final String text;
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
                  widget.text,
                  textAlign: TextAlign.center,
                ),
              ),
              content: const Text("Room: <TEST>\nTeacher: <TEST>"),
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
                  widget.text,
                  textAlign: TextAlign.center,
                  minFontSize: 6,
                  maxFontSize: 16,
                  maxLines: 2,
                  semanticsLabel: widget.text,
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
              for (int idx = 0; idx < sampleTimetableData[today].length; idx++)
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text("Period ${idx + 1}"),
                      Text(sampleTimetableData[today][idx]),
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

class TimetablePage extends StatefulWidget {
  const TimetablePage({Key? key}) : super(key: key);

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  // This is a 2D array of subjects in the timetable.
  // This is the format which the API will return once implemented.

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
                    double height = constraints.maxHeight /
                            (sampleTimetableData[0].length + 2) -
                        (borderWidth * 2 + borderWidth);
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              TimetableSlot(
                                "Monday",
                                width: width,
                                height: height,
                                borderWidth: borderWidth * 2,
                                clickable: false,
                              ),
                              TimetableSlot(
                                "Tuesday",
                                width: width,
                                height: height,
                                borderWidth: borderWidth * 2,
                                clickable: false,
                              ),
                              TimetableSlot(
                                "Wednesday",
                                width: width,
                                height: height,
                                borderWidth: borderWidth * 2,
                                clickable: false,
                              ),
                              TimetableSlot(
                                "Thursday",
                                width: width,
                                height: height,
                                borderWidth: borderWidth * 2,
                                clickable: false,
                              ),
                              TimetableSlot(
                                "Friday",
                                width: width,
                                height: height,
                                borderWidth: borderWidth * 2,
                                clickable: false,
                              ),
                            ],
                          ),
                        ],
                        for (int i = 0; i < sampleTimetableData[0].length; i++)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              for (int j = 0;
                                  j < sampleTimetableData.length;
                                  j++)
                                TimetableSlot(
                                  sampleTimetableData[j][i],
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
