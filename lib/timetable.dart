import 'package:flutter/material.dart';

class TimetableSlot extends StatelessWidget {
  const TimetableSlot(this.text, {Key? key}) : super(key: key);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      margin: const EdgeInsets.only(
        bottom: 1,
      ),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        border: const Border(
          left: BorderSide(color: Colors.black),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class Timetable extends StatefulWidget {
  const Timetable({Key? key}) : super(key: key);

  @override
  State<Timetable> createState() => _TimetableState();
}

class _TimetableState extends State<Timetable>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: 3);
  }

  @override
  void dispose() {
    _tabController!.dispose();
    super.dispose();
  }

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
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
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
