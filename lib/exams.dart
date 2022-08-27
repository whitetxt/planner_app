import 'dart:convert';

import "package:flutter/material.dart";
import "package:http/http.dart" as http;

import 'globals.dart';
import 'network.dart';
import "pl_appbar.dart"; // Provides PLAppBar for the bar at the top of the screen.

List<ExamMark> marks = [];

class ExamMark {
  const ExamMark(this.id, this.name, this.mark, this.grade);

  final int id;
  final String name;
  final int mark;
  final String? grade;
}

class MarkWidget extends StatelessWidget {
  const MarkWidget(this.data, this.reset, {Key? key}) : super(key: key);

  final ExamMark data;
  final Function reset;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: IntrinsicHeight(
          child: Flex(
            direction: Axis.horizontal,
            children: <Widget>[
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Text(
                      "${data.mark}",
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      "${data.grade}",
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                flex: 4,
                child: Text(
                  data.name,
                  textAlign: TextAlign.center,
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                flex: 1,
                child: PopupMenuButton(
                  icon: const Icon(
                    Icons.more_horiz,
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      onTap: () {},
                      child: const Text(
                        "Modify Mark",
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      onTap: () {
                        addRequest(
                          NetworkOperation(
                            "/api/v1/marks",
                            "DELETE",
                            (http.Response response) {
                              reset();
                            },
                            data: {"mark_id": data.id.toString()},
                          ),
                        );
                      },
                      child: const Text(
                        "Delete",
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

void gotMarks(http.Response response) {
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
  marks = [];
  if (data["data"] != null) {
    for (dynamic mark in data["data"]) {
      marks.add(
        ExamMark(
          mark["mark_id"],
          mark["test_name"],
          mark["mark"],
          mark["grade"],
        ),
      );
    }
  }
}

class ExamPage extends StatefulWidget {
  const ExamPage(this.token, {Key? key}) : super(key: key);

  final String token;

  @override
  State<ExamPage> createState() => _ExamPageState();
}

class _ExamPageState extends State<ExamPage> {
  final _formKey = GlobalKey<FormState>();

  String name = "";
  int mark = 0;
  String grade = "";

  void refreshMarks() {
    // This refreshes the homework page, grabbing new data from the API.
    addRequest(
      NetworkOperation(
        "/api/v1/marks",
        "GET",
        (http.Response response) {
          gotMarks(response);
          Navigator.of(context).popUntil(ModalRoute.withName(
              "/dash")); // This removes any modals or popup dialogs that are active at the current time.
          setState(
              () {}); // This then just forces the page to rebuild and redraw itself.
        },
      ),
    );
  }

  void addMark() {
    // This adds a piece of homework to the server, and then refreshes the page.
    addRequest(
      NetworkOperation(
        "/api/v1/marks",
        "POST",
        (http.Response response) {
          refreshMarks();
        },
        data: {
          "name": name,
          "mark": mark.toString(),
          "grade": grade,
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    refreshMarks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PLAppBar("Exam Marks", context),
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
                                      labelText: "Test Name",
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
                                      addMark();
                                    },
                                  ),
                                  TextFormField(
                                    decoration: const InputDecoration(
                                      labelText: "Mark",
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null ||
                                          value.isEmpty ||
                                          int.tryParse(value) == null) {
                                        return "Enter a valid mark";
                                      }
                                      return null;
                                    },
                                    onChanged: (value) {
                                      int? result = int.tryParse(value);
                                      if (result != null) {
                                        mark = result;
                                      }
                                    },
                                    onFieldSubmitted: (String _) {
                                      addMark();
                                    },
                                  ),
                                  TextFormField(
                                    decoration: const InputDecoration(
                                      labelText: "Grade",
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return "Enter a grade";
                                      }
                                      return null;
                                    },
                                    onChanged: (value) {
                                      grade = value;
                                    },
                                    onFieldSubmitted: (String _) {
                                      addMark();
                                    },
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      // Validate the form (returns true if all is ok)
                                      if (_formKey.currentState!.validate()) {
                                        addMark();
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
            ],
          ),
          Expanded(
            child: ListView(
              children: [
                if (marks.isEmpty)
                  const Text(
                    "No marks",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                    ),
                  ),
                for (var hw in marks) ...[MarkWidget(hw, refreshMarks)],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
