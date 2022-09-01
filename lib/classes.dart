import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import "package:http/http.dart" as http;

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

class ClassWidget extends StatefulWidget {
  const ClassWidget(this.data, {Key? key}) : super(key: key);

  final AppClass data;

  @override
  State<ClassWidget> createState() => _ClassWidgetState();
}

void gotClasses(http.Response response) {
  if (!validateResponse(response)) return;
  Map<String, dynamic> data = json.decode(response.body);
  classes = [];
  for (dynamic cls in data["data"]) {
    classes.add(AppClass.fromJson(cls));
  }
}

class _ClassWidgetState extends State<ClassWidget> {
  void load() {
    // This refreshes the homework page, grabbing new data from the API.
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

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: const Text("Class Name Here"),
      children: <Widget>[
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Column(
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
                      onPressed: () {},
                    ),
                  ],
                ),
                Column(
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
                      onPressed: () {},
                    ),
                  ],
                ),
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
            for (AppClass cls in classes) ClassWidget(cls),
          ]
        ],
      ),
    );
  }
}
