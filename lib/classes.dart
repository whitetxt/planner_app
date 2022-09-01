import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import "package:http/http.dart" as http;
import 'package:intl/intl.dart';

import 'homework.dart';
import 'pl_appbar.dart';
import 'globals.dart';
import 'network.dart';

class AppClass {
  AppClass(
    this.classId,
    this.teacherId,
    this.className,
    this.homework,
    this.students,
  );

  final int classId;
  final int teacherId;
  final String className;
  final List<HomeworkData> homework;
  final List<User> students;

  factory AppClass.fromJson(Map<String, dynamic> data) {
    return AppClass(
      data["class_id"],
      data["teacher_id"],
      data["class_name"],
      [
        for (dynamic homework in data["homework"])
          HomeworkData.fromJson(homework)
      ],
      [
        for (dynamic student in data["students"]) User.fromJson(student),
      ],
    );
  }
}

List<AppClass> classes = [];

void gotClasses(http.Response response) {
  if (!validateResponse(response)) return;
  Map<String, dynamic> data = json.decode(response.body);
  print(data);
  classes = [];
  for (dynamic cls in data["data"]) {
    classes.add(AppClass.fromJson(cls));
  }
}

class ClassWidget extends StatefulWidget {
  const ClassWidget(this.data, this.reset, {Key? key}) : super(key: key);

  final AppClass data;
  final Function reset;

  @override
  State<ClassWidget> createState() => _ClassWidgetState();
}

class _ClassWidgetState extends State<ClassWidget> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();

  User? selectedUser;
  String name = "";
  DateTime date = DateTime.now();
  String description = "";

  void setHomework() {
    addRequest(
      NetworkOperation(
        "/api/v1/classes/${widget.data.classId}/homework",
        "POST",
        (http.Response response) {
          if (!validateResponse(response)) return;
        },
        data: {
          "homework_name": name,
          "due_date": date.millisecondsSinceEpoch.toString(),
          "description": description
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(
        "${widget.data.className} - ${widget.data.students.length} Students",
      ),
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                const AutoSizeText(
                  "Students",
                  style: TextStyle(
                    fontSize: 24,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text("Add Student"),
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
                              "Add a Student",
                              textAlign: TextAlign.center,
                            ),
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Autocomplete<User>(
                                optionsBuilder:
                                    (TextEditingValue textEditingValue) {
                                  if (textEditingValue.text.isEmpty) {
                                    return const Iterable<User>.empty();
                                  }
                                  return processNetworkRequest(
                                    NetworkOperation(
                                      "$apiUrl/api/v1/users/search/${textEditingValue.text}",
                                      "GET",
                                      (_) {},
                                    ),
                                  ).then(
                                    (http.Response resp) {
                                      if (!validateResponse(resp)) {
                                        return const Iterable<User>.empty();
                                      }
                                      Map<String, dynamic> data =
                                          json.decode(resp.body);
                                      List<User> users = [];
                                      for (Map<String, dynamic> user
                                          in data["data"]) {
                                        users.add(User.fromJson(user));
                                      }
                                      List<User> finalUsers = [];
                                      for (User user in users) {
                                        // Filter out any users that are already in the class.
                                        if (!widget.data.students.any(
                                            (User element) =>
                                                element.uid == user.uid)) {
                                          finalUsers.add(user);
                                        }
                                      }
                                      return finalUsers;
                                    },
                                  );
                                },
                                onSelected: (User option) =>
                                    selectedUser = option,
                                displayStringForOption: (User option) =>
                                    option.name,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (selectedUser == null) {
                                      return;
                                    }
                                    addRequest(
                                      NetworkOperation(
                                        "/api/v1/classes/${widget.data.classId}",
                                        "PATCH",
                                        (_) {
                                          widget.reset();
                                        },
                                        data: {
                                          "student_id":
                                              selectedUser!.uid.toString(),
                                        },
                                      ),
                                    );
                                  },
                                  child: const Text('Add Student'),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
                ...[
                  for (User student in widget.data.students) Text(student.name)
                ]
              ],
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                const AutoSizeText(
                  "Homework",
                  style: TextStyle(
                    fontSize: 24,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text("Create Homework"),
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
                              "Assign Homework",
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
                                    setHomework();
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
                                    setHomework();
                                  },
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      addRequest(
                                        NetworkOperation(
                                          "/api/v1/classes/${widget.data.classId}/homework",
                                          "POST",
                                          (_) {
                                            widget.reset();
                                          },
                                          data: {
                                            "homework_name": name,
                                            "due_date": date
                                                .millisecondsSinceEpoch
                                                .toString(),
                                            "description": description,
                                          },
                                        ),
                                      );
                                    },
                                    child: const Text('Create Homework'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                ...[
                  for (HomeworkData hwData in widget.data.homework)
                    Text(hwData.name),
                ],
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class ClassPage extends StatefulWidget {
  const ClassPage({Key? key}) : super(key: key);

  @override
  State<ClassPage> createState() => _ClassPageState();
}

class _ClassPageState extends State<ClassPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String name = "";

  void refreshClasses() {
    // This refreshes the class page, grabbing new data from the API.
    addRequest(
      NetworkOperation(
        "/api/v1/classes",
        "GET",
        (http.Response response) {
          gotClasses(response);
          setState(
              () {}); // This then just forces the page to rebuild and redraw itself.
        },
      ),
    );
  }

  void createClass() {
    addRequest(
      NetworkOperation(
        "/api/v1/classes",
        "POST",
        (http.Response response) {
          refreshClasses();
        },
        data: {
          "name": name,
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    refreshClasses();
  }

  @override
  Widget build(BuildContext context) {
    if (!onlineMode) {
      return Scaffold(
        appBar: PLAppBar("Classes", context),
        backgroundColor: Theme.of(context).backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const <Widget>[
              AutoSizeText(
                "Unfortunately, you are offline.",
                style: TextStyle(
                  fontSize: 24,
                ),
              ),
              AutoSizeText(
                "Classes cannot be managed without an internet connection.",
                style: TextStyle(
                  fontSize: 24,
                ),
              ),
              AutoSizeText(
                "Please try again later.",
                style: TextStyle(
                  fontSize: 24,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: PLAppBar("Classes", context),
      backgroundColor: Theme.of(context).backgroundColor,
      body: ListView(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: TextButton.icon(
                  label: const Text(
                    "Create Class",
                    style: TextStyle(color: Colors.black),
                  ),
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
                              "Create a class",
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
                                    labelText: "Class Name",
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
                                    createClass();
                                  },
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      // Validate the form (returns true if all is ok)
                                      if (_formKey.currentState!.validate()) {
                                        createClass();
                                      }
                                    },
                                    child: const Text('Create Class!'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Theme.of(context).highlightColor,
                    side: const BorderSide(color: Colors.black),
                  ),
                  icon: const Icon(Icons.add, color: Colors.black),
                ),
              ),
            ],
          ),
          ...[
            for (AppClass cls in classes)
              ClassWidget(
                cls,
                () {
                  refreshClasses();
                  Navigator.of(context).popUntil(ModalRoute.withName("/dash"));
                },
              ),
          ]
        ],
      ),
    );
  }
}
