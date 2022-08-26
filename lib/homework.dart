import 'dart:convert';
import 'package:intl/intl.dart';

import "package:flutter/material.dart";
import 'package:planner_app/globals.dart';
import 'package:planner_app/network.dart';
import "package:http/http.dart" as http;

import "pl_appbar.dart"; // Provides PLAppBar for the bar at the top of the screen.

List<HomeworkData> homework = [];

class HomeworkData {
  const HomeworkData(
      this.id, this.timeDue, this.name, this.classId, this.completed);

  final int id;
  final DateTime timeDue;
  final String name;
  final String? classId;
  final bool completed;

  factory HomeworkData.fromJson(dynamic jsonData) {
    return HomeworkData(
      jsonData["homework_id"],
      DateTime.fromMillisecondsSinceEpoch(jsonData["due_date"]),
      jsonData["name"],
      jsonData["class_id"],
      jsonData["completed"],
    );
  }
}

class HomeworkWidget extends StatelessWidget {
  const HomeworkWidget(this.data, this.reset, {Key? key}) : super(key: key);

  final HomeworkData data;
  final Function reset;

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
                child: Text(
                  "${data.timeDue.day}/${data.timeDue.month}",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    // We should change the colours of all the elements if the homework is completed.
                    // This is because it will be easier for the user to see that they have already done it.
                    color: data.completed ? Colors.green : Colors.black,
                  ),
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                flex: 4,
                child: Text(
                  data.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: data.completed ? Colors.green : Colors.black,
                  ),
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                flex: 1,
                child: PopupMenuButton(
                  icon: Icon(
                    Icons.more_horiz,
                    color: data.completed ? Colors.green : Colors.black,
                  ),
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
                      onTap: () {
                        addRequest(
                          NetworkOperation(
                            "/api/v1/homework",
                            "PUT",
                            (http.Response response) {
                              reset();
                            },
                            data: {"id": data.id.toString()},
                          ),
                        );
                      },
                      child: Text(
                        data.completed ? "Undo Completion" : "Complete",
                        style: const TextStyle(
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
  bool any = false;
  @override
  void initState() {
    addRequest(
      NetworkOperation(
        "/api/v1/homework",
        "GET",
        (http.Response response) {
          gotHomework(response);
          setState(() {});
        },
      ),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 15 * MediaQuery.of(context).size.width / 16,
      height: MediaQuery.of(context).size.height / 4,
      child: Card(
        elevation: 4,
        child: Column(
          children: <Widget>[
            const Text("Due Homework"),
            const Divider(
              indent: 4,
              endIndent: 4,
            ),
            ...[
              for (int idx = 0;
                  idx <
                          homework
                              .where((element) => !element.completed)
                              .length && // This filters the list of homework to only ones that have not been completed.
                      // This is done as the dashboard should only display things the user needs to know.
                      idx < 5;
                  idx++)
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "${homework.where((element) => !element.completed).toList()[idx].timeDue.day}/${homework[idx].timeDue.month}",
                      ),
                      Text(homework
                          .where((element) => !element.completed)
                          .toList()[idx]
                          .name),
                    ],
                  ),
                ),
            ],
            if (homework.every(
              (element) => element.completed,
            )) ...[
              // If every piece of homework is completed, then we should tell the user instead of having an empty card.
              // If they are all completed, then we know the above for loop will have not added anything and do not need to worry about that.
              const Text(
                "No Homework!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

void gotHomework(http.Response response) {
  // This just handles the server's response for returning homework.
  // We must check for an error, then notify the user of it.
  if (response.statusCode != 200) {
    if (response.statusCode == 500) {
      addNotif("Internal Server Error", error: true);
      return;
    }
    addNotif(response.body, error: true);
    return;
  }
  dynamic data = json.decode(response.body);
  if (data["status"] != "success") {
    addNotif(data["message"], error: true);
    return;
  }
  homework = [];
  if (data["data"] != null) {
    for (dynamic hw in data["data"]) {
      homework.add(HomeworkData.fromJson(hw));
    }
  }
}

class HomeworkPage extends StatefulWidget {
  const HomeworkPage(this.token, {Key? key}) : super(key: key);

  final String token;

  @override
  State<HomeworkPage> createState() => _HomeworkPageState();
}

class _HomeworkPageState extends State<HomeworkPage> {
  final TextEditingController _dateController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String name = "";
  DateTime date = DateTime.now();
  bool showCompleted = false;

  void refreshHomework() {
    // This refreshes the homework page, grabbing new data from the API.
    addRequest(
      NetworkOperation(
        "/api/v1/homework",
        "GET",
        (http.Response response) {
          gotHomework(response);
          Navigator.of(context).popUntil(ModalRoute.withName(
              "/dash")); // This removes any modals or popup dialogs that are active at the current time.
          setState(
              () {}); // This then just forces the page to rebuild and redraw itself.
        },
      ),
    );
  }

  void addHomework() {
    // This adds a piece of homework to the server, and then refreshes the page.
    addRequest(
      NetworkOperation(
        "/api/v1/homework",
        "POST",
        (http.Response response) {
          refreshHomework();
        },
        data: {
          "name": name,
          "due_date": date.millisecondsSinceEpoch.toString()
        },
      ),
    );
  }

  @override
  void initState() {
    refreshHomework();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PLAppBar("Homework", context),
      backgroundColor: Theme.of(context).backgroundColor,
      body: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(
                width: 80,
                height: 32,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
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
                                "Add homework",
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
                                      labelText: "Homework Name",
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
                                      addHomework();
                                    },
                                  ),
                                  InkWell(
                                    onTap: () async {
                                      final DateTime? selected =
                                          await showDatePicker(
                                        context: context,
                                        initialDate: DateTime.now(),
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime.now().add(
                                          const Duration(days: 9000),
                                        ),
                                      );
                                      if (selected != null) {
                                        setState(
                                          () {
                                            date = selected;
                                            _dateController.text =
                                                DateFormat("dd-MM-yy")
                                                    .format(selected);
                                          },
                                        );
                                      }
                                    },
                                    child: TextFormField(
                                      enabled: false,
                                      controller: _dateController,
                                      decoration: const InputDecoration(
                                        label: Text("Date Due"),
                                      ),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      // Validate the form (returns true if all is ok)
                                      if (_formKey.currentState!.validate()) {
                                        addHomework();
                                      }
                                    },
                                    child: const Text('Submit'),
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
              ),
              SizedBox(
                height: 32,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: showCompleted,
                          onChanged: (value) {
                            setState(() {
                              showCompleted = value!;
                            });
                          },
                        ),
                        const Text(
                          "Show Completed?",
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              children: [
                if (homework
                        .isEmpty || // We need this OR, otherwise if everything is completed and hidden then the page will be empty.
                    (homework.every((element) => element.completed) &&
                        !showCompleted))
                  const Text(
                    "No homework!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                    ),
                  ),
                for (var hw in homework)
                  if (!showCompleted && hw.completed)
                    ...[] // I could'nt figure out a way to do this any other way, so we just concatinate an empty array.
                  else ...[HomeworkWidget(hw, refreshHomework)],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
