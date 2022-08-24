import "package:flutter/material.dart";

import "pl_appbar.dart"; // Provides PLAppBar for the bar at the top of the screen.

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
        padding: const EdgeInsets.fromLTRB(0, 6, 0, 6),
        child: IntrinsicHeight(
          child: Flex(
            direction: Axis.horizontal,
            children: <Widget>[
              Expanded(
                flex: 1,
                child: Column(
                  children: <Widget>[
                    Text("${data.timeDue.day}/${data.timeDue.month}"),
                    Text("${data.timeDue.hour}:${data.timeDue.minute}")
                  ],
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                flex: 4,
                child: Column(
                  children: <Widget>[
                    Text("${data.subject} (${data.teacher}):"),
                    Text(data.name),
                  ],
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                flex: 1,
                child: PopupMenuButton(
                  icon: const Icon(Icons.more_horiz),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      onTap: () {},
                      child: const Text(
                        "More Info",
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      onTap: () {},
                      child: const Text(
                        "Complete",
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeworkMini extends StatefulWidget {
  const HomeworkMini({Key? key}) : super(key: key);

  @override
  State<HomeworkMini> createState() => _HomeworkMiniState();
}

class _HomeworkMiniState extends State<HomeworkMini> {
  @override
  Widget build(BuildContext context) {
    return Container(child: const Text("Hello mini homework"));
  }
}

class HomeworkPage extends StatefulWidget {
  const HomeworkPage(this.token, {Key? key}) : super(key: key);

  final String token;

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
    ...[
      for (int i = 1; i < 25; i++)
        HomeworkData(DateTime.now().add(Duration(days: 4, hours: i)),
            "Test Name", "Test Teacher", "Test Subject"),
    ]
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
