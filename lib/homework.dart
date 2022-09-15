import 'dart:convert';
import 'package:intl/intl.dart';

import "package:flutter/material.dart";
import 'package:planner_app/globals.dart';
import 'package:planner_app/network.dart';
import "package:http/http.dart" as http;
import 'package:shared_preferences/shared_preferences.dart';

import "pl_appbar.dart"; // Provides PLAppBar for the bar at the top of the screen.

List<HomeworkData> homework = [];

class HomeworkData {
  HomeworkData(
    this.id,
    this.timeDue,
    this.name,
    this.classId,
    this.description,
    this.completed,
    this.completedBy,
  );

  final int id;
  final String name;
  final int? classId;
  final int? completedBy;
  bool completed;
  final DateTime timeDue;
  final String? description;

  factory HomeworkData.fromJson(dynamic jsonData) {
    // Converts the server's response into a HomeworkData object.
    return HomeworkData(
      jsonData["homework_id"],
      DateTime.fromMillisecondsSinceEpoch(jsonData["due_date"]),
      jsonData["name"],
      jsonData["class_id"],
      jsonData["description"],
      jsonData["completed"],
      jsonData["completed_by"],
    );
  }

  Map<String, dynamic> toJson() {
    // Convert this object back into JSON, to be used elsewhere.
    // The Map<String, dynamic> type is the definition of JSON used in most places,
    // as Strings are commonly used as keys, and anything can be a value.
    return {
      "homework_id": id,
      "due_date": timeDue.millisecondsSinceEpoch,
      "name": name,
      "class_id": classId,
      "description": description,
      "completed": completed,
      "completed_by": completedBy
    };
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
      // This changes the background colour of the card depending on
      // when this is due.
      color: data.completed
          ? Colors.green.shade200
          : data.timeDue.isBefore(DateTime.now())
              ? Colors.red
              : data.timeDue.difference(DateTime.now()).inDays < 3
                  ? Colors.redAccent.shade100
                  : data.timeDue.difference(DateTime.now()).inDays < 7
                      ? Colors.orange.shade200
                      : Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: ExpansionTile(
          title: Flex(
            direction: Axis.horizontal,
            children: <Widget>[
              Expanded(
                flex: 2,
                child: Text(
                  "${data.timeDue.day}/${data.timeDue.month}/${data.timeDue.year}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    // We should change the colours of all the elements if the homework is completed.
                    // This is because it will be easier for the user to see that they have already done it.
                    color: Colors.black,
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  data.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          children: [
            Text(
              data.timeDue.isBefore(DateTime.now())
                  ? "Past Due!"
                  : data.timeDue.difference(DateTime.now()) >=
                          const Duration(days: 1, hours: 12)
                      ? "Due in ${data.timeDue.difference(DateTime.now()).inDays} days and ${data.timeDue.difference(DateTime.now()).inHours - data.timeDue.difference(DateTime.now()).inDays * 24} hours"
                      : data.timeDue.difference(DateTime.now()) >=
                              const Duration(hours: 12)
                          ? "Due in ${data.timeDue.difference(DateTime.now()).inHours} hours"
                          : "Due in ${data.timeDue.difference(DateTime.now()).toString().substring(0, 4)}",
              style: TextStyle(
                // If the homework is past due, then increase the size and weight of the font
                // so that it is easily visible to the user.
                fontWeight: data.timeDue.isBefore(DateTime.now())
                    ? FontWeight.w900
                    : FontWeight.normal,
                fontSize: data.timeDue.isBefore(DateTime.now()) ? 24 : 16,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                // If there isn't a description, display "No Description" instead of nothing.
                data.description != null && data.description!.isNotEmpty
                    ? data.description!
                    : "No Description",
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ElevatedButton(
                child: Text(
                  // The text must change if it's already completed, as it would
                  // look stupid to mark homework as complete when it's already complete.
                  data.completed ? "Mark as Incomplete" : "Mark as Complete",
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
                onPressed: () async {
                  data.completed = !data.completed;
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString(
                    "homework",
                    json.encode(
                      [for (HomeworkData hw in homework) hw.toJson()],
                    ),
                  );
                  addRequest(
                    NetworkOperation(
                      "/api/v1/homework",
                      "PATCH",
                      (http.Response response) {
                        reset();
                      },
                      data: {"id": data.id.toString()},
                    ),
                  );
                },
              ),
            ),
          ],
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

  Future<void> load() async {
    // We should load everything from our local store before trying to get stuff from the server.
    final prefs = await SharedPreferences.getInstance();
    String? storedHomework = prefs.getString("homework");
    if (storedHomework != null) {
      List<dynamic> data = json.decode(storedHomework);
      homework = [];
      for (dynamic hw in data) {
        homework.add(HomeworkData.fromJson(hw));
      }
      setState(() {});
    }
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
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Widget build(BuildContext context) {
    if (homework.every(
      (element) => element.completed,
    )) {
      // If all homework is completed, then tell the user there is nothing left.
      return SizedBox(
        width: 15 * MediaQuery.of(context).size.width / 16,
        height: MediaQuery.of(context).size.height / 4,
        child: Card(
          elevation: 4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const <Text>[
              Text(
                "No due homework!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                ),
              ),
            ],
          ),
        ),
      );
    }
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
            Expanded(
              child: ListView(
                children: [
                  for (HomeworkData hw
                      in homework.where((element) => !element.completed))
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          // Display the time due and name of the
                          Text(
                            "${hw.timeDue.day}/${hw.timeDue.month}/${hw.timeDue.year}",
                          ),
                          Text(hw.name),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> gotHomework(http.Response response) async {
  // This just handles the server's response for returning homework.
  // We must check for an error, then notify the user of it.
  if (!validateResponse(response)) return;
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
  // Once we have gotten everything on the server, save the data to the device.
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString("homework", json.encode(data["data"]));
}

class HomeworkPage extends StatefulWidget {
  const HomeworkPage({Key? key}) : super(key: key);

  @override
  State<HomeworkPage> createState() => _HomeworkPageState();
}

class _HomeworkPageState extends State<HomeworkPage> {
  final TextEditingController _dateController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String name = "";
  DateTime date = DateTime.now();
  bool showCompleted = false;
  String description = "";

  Future<void> refreshHomework() async {
    // First we get everything from the local save.
    final prefs = await SharedPreferences.getInstance();
    String? storedHomework = prefs.getString("homework");
    if (storedHomework != null) {
      List<dynamic> data = json.decode(storedHomework);
      homework = [];
      for (dynamic hw in data) {
        homework.add(HomeworkData.fromJson(hw));
      }
      setState(() {});
    }
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

  void removePopups() {
    Navigator.of(context).popUntil(ModalRoute.withName("/dash"));
  }

  Future<void> addHomework() async {
    // First, add it to the local copy and render that.
    final prefs = await SharedPreferences.getInstance();
    String? storedHomework = prefs.getString("homework");
    if (storedHomework != null) {
      List<dynamic> data = json.decode(storedHomework);
      homework = [];
      for (dynamic hw in data) {
        homework.add(HomeworkData.fromJson(hw));
      }
      homework.add(HomeworkData(0, date, name, 0, "", false, 0));
      await prefs.setString(
        "homework",
        json.encode([for (HomeworkData hw in homework) hw.toJson()]),
      );
      removePopups();
      setState(() {});
    }
    // Then, add it to the server and refresh.
    addRequest(
      NetworkOperation(
        "/api/v1/homework",
        "POST",
        (http.Response response) {
          refreshHomework();
        },
        data: {
          "name": name,
          "due_date": date.millisecondsSinceEpoch.toString(),
          "description": description,
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    refreshHomework();
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
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    backgroundColor: Theme.of(context).highlightColor,
                    side: const BorderSide(color: Colors.black),
                  ),
                  icon: const Icon(
                    Icons.add,
                    color: Colors.black,
                    size: 24,
                  ),
                  onPressed: () {
                    name = "";
                    date = DateTime.now();
                    description = "";
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
                                    // Using a DatePicker like this makes the UX better
                                    // as the user does not have to enter the date manually.
                                    final DateTime? selected =
                                        await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime.now().add(
                                        // Allow the user to create homework for the next year.
                                        const Duration(days: 365),
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
                                    // This is disabled as the code above controls it.
                                    enabled: false,
                                    controller: _dateController,
                                    decoration: const InputDecoration(
                                      label: Text("Date Due"),
                                    ),
                                  ),
                                ),
                                TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: "Description (Optional)",
                                  ),
                                  maxLines: 5,
                                  keyboardType: TextInputType.multiline,
                                  onChanged: (value) {
                                    description = value;
                                  },
                                  onFieldSubmitted: (String _) {
                                    addHomework();
                                  },
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      // Validate the form (returns true if all is ok)
                                      if (_formKey.currentState!.validate()) {
                                        addHomework();
                                      }
                                    },
                                    child: const Text('Submit'),
                                  ),
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
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Checkbox(
                        value: showCompleted,
                        onChanged: (value) {
                          setState(() {
                            // Just flip the bool.
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
            ],
          ),
          Expanded(
            child: ListView(
              children: [
                // We need this OR, otherwise if everything is completed and hidden then the page will be empty.
                if (homework.isEmpty ||
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
