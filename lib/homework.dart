import "package:flutter/material.dart";

import "pl_appbar.dart";

class HomeworkData {
  HomeworkData(this.timeDue, this.name, this.teacher, this.subject);

  final DateTime timeDue;
  final String name;
  final String teacher;
  final String subject;

  factory HomeworkData.fromJson(dynamic jsonData) {
    return HomeworkData(
      DateTime.fromMillisecondsSinceEpoch(jsonData["timeDue"]),
      jsonData["name"],
      jsonData["teacher"],
      jsonData["subject"],
    );
  }
}

class HomeworkWidget extends StatelessWidget {
  const HomeworkWidget(this.data, {Key? key}) : super(key: key);

  final HomeworkData data;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            Column(
              children: <Widget>[
                Text("${data.timeDue.day}/${data.timeDue.month}"),
                Text("${data.timeDue.hour}:${data.timeDue.minute}")
              ],
            ),
            Column(
              children: <Widget>[
                Text("Homework for ${data.subject} (${data.teacher}):"),
                Text(data.name),
              ],
            ),
            PopupMenuButton(
              child: Material(
                elevation: 4,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.black),
                    color: Theme.of(context).highlightColor,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: const [
                      Icon(Icons.more_horiz, color: Colors.black),
                      Text(
                        "Actions",
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 1,
                  onTap: () {},
                  child: const Text("More Info"),
                ),
                PopupMenuItem(
                  value: 1,
                  onTap: () {},
                  child: const Text("Complete"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class HomeworkPage extends StatefulWidget {
  const HomeworkPage({Key? key}) : super(key: key);

  @override
  State<HomeworkPage> createState() => _HomeworkPageState();
}

class _HomeworkPageState extends State<HomeworkPage> {
  List<HomeworkData> sampleHomeworkData = [
    HomeworkData(DateTime.now(), "Test Name", "Test Teacher", "Test Subject"),
    HomeworkData(DateTime.now().add(const Duration(days: 1)), "Test Name",
        "Test Teacher", "Test Subject"),
    HomeworkData(DateTime.now().add(const Duration(days: 2)), "Test Name",
        "Test Teacher", "Test Subject"),
    HomeworkData(DateTime.now().add(const Duration(days: 3, hours: 6)),
        "Test Name", "Test Teacher", "Test Subject"),
    HomeworkData(DateTime.now().add(const Duration(days: 4, hours: 12)),
        "Test Name", "Test Teacher", "Test Subject"),
    HomeworkData(DateTime.now().add(const Duration(days: 4, hours: 12)),
        "Test Name", "Test Teacher", "Test Subject"),
    HomeworkData(DateTime.now().add(const Duration(days: 4, hours: 12)),
        "Test Name", "Test Teacher", "Test Subject"),
    HomeworkData(DateTime.now().add(const Duration(days: 4, hours: 12)),
        "Test Name", "Test Teacher", "Test Subject"),
    HomeworkData(DateTime.now().add(const Duration(days: 4, hours: 12)),
        "Test Name", "Test Teacher", "Test Subject"),
    HomeworkData(DateTime.now().add(const Duration(days: 4, hours: 12)),
        "Test Name", "Test Teacher", "Test Subject"),
    HomeworkData(DateTime.now().add(const Duration(days: 4, hours: 12)),
        "Test Name", "Test Teacher", "Test Subject"),
    HomeworkData(DateTime.now().add(const Duration(days: 4, hours: 12)),
        "Test Name", "Test Teacher", "Test Subject"),
    HomeworkData(DateTime.now().add(const Duration(days: 4, hours: 12)),
        "Test Name", "Test Teacher", "Test Subject"),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PLAppBar("Homework", context),
      backgroundColor: Theme.of(context).backgroundColor,
      body: Center(
        child: ListView(
          children: [
            for (var hw in sampleHomeworkData) HomeworkWidget(hw),
          ],
        ),
      ),
    );
  }
}
