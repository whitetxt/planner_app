import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';

class TimetableSlot extends StatefulWidget {
  const TimetableSlot(this.text, {Key? key}) : super(key: key);

  final String text;

  @override
  State<TimetableSlot> createState() => _TimetableSlotState();
}

class _TimetableSlotState extends State<TimetableSlot> {
  ExpandableController? _expController;

  @override
  void initState() {
    super.initState();
    _expController = ExpandableController(initialExpanded: false);
  }

  @override
  void dispose() {
    _expController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 32,
      ),
      margin: const EdgeInsets.only(
        bottom: 1,
      ),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        border: const Border(
          left: BorderSide(color: Colors.black),
        ),
      ),
      child: ExpandablePanel(
        header: const Text("Hello there"),
        collapsed: Container(),
        expanded: const Text(
          "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
          softWrap: true,
        ),
        controller: _expController,
      ),
    );
  }
}

class Timetable extends StatefulWidget {
  const Timetable({Key? key}) : super(key: key);

  @override
  State<Timetable> createState() => _TimetableState();
}

class _TimetableState extends State<Timetable> {
  // This is a 2D array of subjects in the timetable.
  // This is the format which the API will return once implemented.
  List<List<String>> subjects = [
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(32),
        child: AppBar(
          title: const Center(
            child: Text("Your Timetable"),
          ),
        ),
      ),
      backgroundColor: Colors.grey.shade700,
      body: Column(
        children: [
          Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.bottom,
            children: [
              ...[
                const TableRow(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.black),
                      top: BorderSide(color: Colors.black),
                    ),
                  ),
                  children: <Widget>[
                    TimetableSlot("Monday"),
                    TimetableSlot("Tuesday"),
                    TimetableSlot("Wednesday"),
                    TimetableSlot("Thursday"),
                    TimetableSlot("Friday"),
                  ],
                ),
              ],
              for (int i = 0; i < subjects[0].length; i++)
                TableRow(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.black),
                      top: BorderSide(color: Colors.black),
                    ),
                  ),
                  children: <Widget>[
                    for (int j = 0; j < subjects.length; j++)
                      TimetableSlot(subjects[j][i])
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
