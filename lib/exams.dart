import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'globals.dart';
import 'network.dart';
import 'pl_appbar.dart'; // Provides PLAppBar for the bar at the top of the screen.

List<ExamMark> marks = [];

class ExamMark {
  const ExamMark(this.id, this.name, this.mark, this.grade);

  final int id;
  final String name;
  final int mark;
  final String? grade;

  Map<String, dynamic> toJson() {
    // Convert this object back into JSON.
    return {'mark_id': id, 'test_name': name, 'mark': mark, 'grade': grade};
  }
}

// Stop dart linter complaining that some fields aren't final.
// ignore: must_be_immutable
class MarkWidget extends StatelessWidget {
  MarkWidget(this.data, this.reset, {Key? key}) : super(key: key);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final ExamMark data;
  final Function reset;

  String newName = '';
  int newMark = 0;
  String newGrade = '';

  void updateMark() {
    addRequest(
      NetworkOperation(
        '/api/v1/marks',
        'PUT',
        (http.Response response) {
          if (!validateResponse(response)) return;
          reset();
        },
        data: {
          'mark_id': data.id,
          'name': data.name,
          'mark': data.mark.toString(),
          'grade': data.grade
        },
      ),
    );
  }

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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${data.mark}',
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      '${data.grade}',
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
                      onTap: () {
                        Future.delayed(
                          const Duration(microseconds: 1),
                          () => showDialog(
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
                                    'Changing Mark',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                content: Form(
                                  // Adding the key here, allows me to check if this form is
                                  // valid later on in the code.
                                  key: _formKey,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      TextFormField(
                                        decoration: const InputDecoration(
                                          labelText: 'Name',
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Enter a name';
                                          }
                                          return null;
                                        },
                                        initialValue: data.name,
                                        onChanged: (value) {
                                          newName = value;
                                        },
                                        onFieldSubmitted: (String _) {
                                          updateMark();
                                        },
                                      ),
                                      TextFormField(
                                        decoration: const InputDecoration(
                                          labelText: 'Mark',
                                        ),
                                        keyboardType: TextInputType.number,
                                        initialValue: data.mark.toString(),
                                        onChanged: (value) {
                                          if (int.tryParse(value) != null) {
                                            newMark = int.parse(value);
                                          }
                                        },
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Enter a mark';
                                          }
                                          if (int.tryParse(value) == null) {
                                            return 'Mark must be a number';
                                          }
                                          return null;
                                        },
                                        onFieldSubmitted: (String _) {
                                          updateMark();
                                        },
                                      ),
                                      TextFormField(
                                        decoration: const InputDecoration(
                                          labelText: 'Grade',
                                        ),
                                        initialValue: data.grade,
                                        onChanged: (value) {
                                          newGrade = value;
                                        },
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Enter a name';
                                          }
                                          return null;
                                        },
                                        onFieldSubmitted: (String _) {
                                          updateMark();
                                        },
                                      ),
                                      // Create a button which updates the mark.
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: ElevatedButton(
                                          onPressed: () {
                                            // Validate the form (returns true if all is ok)
                                            if (_formKey.currentState!
                                                .validate()) {
                                              updateMark();
                                            }
                                          },
                                          child: const Text('Update Mark'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                      child: const Text(
                        'Modify Mark',
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      onTap: () {
                        addRequest(
                          NetworkOperation(
                            '/api/v1/marks',
                            'DELETE',
                            (http.Response response) {
                              reset();
                            },
                            data: {'mark_id': data.id.toString()},
                          ),
                        );
                      },
                      child: const Text(
                        'Delete',
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

Future<void> gotMarks(http.Response response) async {
  // This just handles the server's response for returning homework.
  // We must check for an error, then notify the user of it.
  if (!validateResponse(response)) return;
  dynamic data = json.decode(response.body);
  if (data['status'] != 'success') {
    addNotif(data['message'], error: true);
    return;
  }
  marks = [];
  if (data['data'] != null) {
    for (dynamic mark in data['data']) {
      marks.add(
        ExamMark(
          mark['mark_id'],
          mark['test_name'],
          mark['mark'],
          mark['grade'],
        ),
      );
    }
  }
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('marks', json.encode(data['data']));
}

class ExamPage extends StatefulWidget {
  const ExamPage({Key? key}) : super(key: key);

  @override
  State<ExamPage> createState() => _ExamPageState();
}

class _ExamPageState extends State<ExamPage> {
  final _formKey = GlobalKey<FormState>();

  String name = '';
  int mark = 0;
  String grade = '';

  Future<void> load() async {
    // Load our local copy first.
    final prefs = await SharedPreferences.getInstance();
    String? storedMarks = prefs.getString('marks');
    if (storedMarks != null) {
      List<dynamic> data = json.decode(storedMarks);
      marks = [];
      for (dynamic mark in data) {
        marks.add(
          ExamMark(
            mark['mark_id'],
            mark['test_name'],
            mark['mark'],
            mark['grade'],
          ),
        );
      }
      if (!mounted) return;
      setState(() {});
    }
    // This refreshes the marks page, grabbing new data from the API.
    addRequest(
      NetworkOperation(
        '/api/v1/marks',
        'GET',
        (http.Response response) {
          gotMarks(response);
          Navigator.of(context).popUntil(ModalRoute.withName(
              '/dash')); // This removes any modals or popup dialogs that are active at the current time.
          if (!mounted) return;
          setState(
              () {}); // This then just forces the page to rebuild and redraw itself.
        },
      ),
    );
  }

  Future<void> addMark() async {
    // First we update our offline buffer of marks.
    final prefs = await SharedPreferences.getInstance();
    String? storedMarks = prefs.getString('marks');
    if (storedMarks != null) {
      List<dynamic> data = json.decode(storedMarks);
      marks = [];
      for (dynamic mark in data) {
        marks.add(
          ExamMark(
            mark['mark_id'],
            mark['test_name'],
            mark['mark'],
            mark['grade'],
          ),
        );
      }
      // After getting the ones currently in the buffer, now we should add the new
      // one and update the buffer.
      marks.add(ExamMark(0, name, mark, grade));
      await prefs.setString(
          'marks', json.encode([for (ExamMark mark in marks) mark.toJson()]));
      if (!mounted) return;
      setState(() {
        Navigator.of(context).popUntil(ModalRoute.withName('/dash'));
      });
    }
    // This adds a piece of homework to the server, and then refreshes the page.
    addRequest(
      NetworkOperation(
        '/api/v1/marks',
        'POST',
        (http.Response response) {
          load();
        },
        data: {
          'name': name,
          'mark': mark.toString(),
          'grade': grade,
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
    // This code is very similar to the homework page.
    return Scaffold(
      appBar: PLAppBar('Exam Marks', context),
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
                              'Add a mark',
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
                                    labelText: 'Test Name',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Enter a name';
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
                                    labelText: 'Mark',
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null ||
                                        value.isEmpty ||
                                        int.tryParse(value) == null) {
                                      return 'Enter a valid mark';
                                    }
                                    return null;
                                  },
                                  onChanged: (value) {
                                    // If we try and parse it, this returns null if its not an integer.
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
                                    labelText: 'Grade',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Enter a grade';
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
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      // Validate the form (returns true if all is ok)
                                      if (_formKey.currentState!.validate()) {
                                        addMark();
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
                    'New',
                    style: TextStyle(
                      color: Colors.black,
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
                  // If there is nothing to show, display this message.
                  const Text(
                    'No marks',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                    ),
                  ),
                for (var hw in marks) ...[MarkWidget(hw, load)],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
