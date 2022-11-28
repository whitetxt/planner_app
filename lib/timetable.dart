import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:clock/clock.dart';

import 'package:http/http.dart' as http;
import 'package:planner_app/globals.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import 'pl_appbar.dart'; // Provides PLAppBar for the bar at the top of the screen.
import 'network.dart'; // Allows network requests on this page.

class TimetableData {
  const TimetableData(this.id, this.name, this.teacher, this.room, this.colour);

  final int id;
  final String name;
  final String teacher;
  final String room;
  final String colour;
}

List<List<TimetableData>> timetable = [[], [], [], [], []];
DateTime lastFetchTime = clock.now();

List<TimetableData> subjects = [];

class TimetableSlot extends StatefulWidget {
  const TimetableSlot(
    this.day,
    this.period,
    this.data,
    this.settingSubject,
    this.toSetTo, {
    Key? key,
    this.width = 128,
    this.height = 32,
    this.borderWidth = 1,
    this.clickable = true,
    this.reset,
  }) : super(key: key);

  final int day;
  final int period;
  final bool settingSubject;
  final TimetableData? toSetTo;

  final TimetableData data;
  final double width;
  final double height;
  final double borderWidth;
  final bool clickable;

  // Function passed must force the parent element to reset its state.
  final Function()? reset;

  @override
  State<TimetableSlot> createState() => _TimetableSlotState();
}

class _TimetableSlotState extends State<TimetableSlot> {
  void resetStates() {
    Navigator.of(context).popUntil(ModalRoute.withName('/dash'));
    if (widget.reset != null) {
      widget.reset!();
    }
  }

  @override
  Widget build(BuildContext context) {
    Color bg = Color(
      int.parse(widget.data.colour.substring(1, 7), radix: 16) + 0xFF000000,
    );
    return GestureDetector(
      onTap: () {
        if (!widget.clickable) return;
        if (widget.settingSubject) {
          if (widget.toSetTo == null) return;
          addRequest(
            NetworkOperation(
              '/api/v1/timetable',
              'POST',
              (http.Response resp) {
                addRequest(
                  NetworkOperation(
                    '/api/v1/timetable',
                    'GET',
                    (http.Response resp) {
                      gotTimetable(resp);
                      widget.reset!();
                    },
                  ),
                );
              },
              data: {
                'subject_id': widget.toSetTo!.id.toString(),
                'day': widget.day.toString(),
                'period': widget.period.toString(),
              },
            ),
          );
        } else {
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
                  child: Text(
                    widget.data.name,
                    textAlign: TextAlign.center,
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      "Room: ${widget.data.room.isEmpty ? 'None' : widget.data.room}",
                    ),
                    Text(
                      "Teacher: ${widget.data.teacher.isEmpty ? 'None' : widget.data.teacher}",
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.delete),
                      label: const Text('Remove subject'),
                      onPressed: () {
                        addRequest(
                          NetworkOperation(
                            '/api/v1/timetable',
                            'DELETE',
                            (http.Response response) {
                              widget.reset!();
                              Navigator.of(context).popUntil(
                                ModalRoute.withName('/dash'),
                              );
                            },
                            data: {
                              'day': widget.day.toString(),
                              'period': widget.period.toString(),
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Material(
          elevation: 2,
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              border: Border.all(
                color: Theme.of(context).bottomAppBarTheme.color!,
                width: widget.borderWidth,
              ),
              borderRadius: BorderRadius.circular(widget.borderWidth / 2),
            ),
            child: SizedBox(
              width: widget.width,
              height: widget.height,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: Center(
                      child: AutoSizeText(
                        widget.data.name,
                        textAlign: TextAlign.center,
                        minFontSize: 5,
                        maxFontSize: 16,
                        stepGranularity: 0.1,
                        maxLines: 3,
                        semanticsLabel: widget.data.name,
                        wrapWords: false,
                        style: TextStyle(
                          color: bg.computeLuminance() > 0.5
                              ? Colors.black
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TodayTimetable extends StatefulWidget {
  const TodayTimetable({Key? key}) : super(key: key);

  @override
  State<TodayTimetable> createState() => _TodayTimetableState();
}

class _TodayTimetableState extends State<TodayTimetable> {
  @override
  void initState() {
    if (timetable[0].length != 9) {
      for (var i = 0; i < 5; i++) {
        for (var j = 0; j < 9; j++) {
          timetable[i].add(
            const TimetableData(
              -1,
              'Loading',
              'Loading',
              'Loading',
              '#ffffff',
            ),
          );
        }
      }
    }
    addRequest(
        NetworkOperation('/api/v1/timetable', 'GET', (http.Response response) {
      gotTimetable(response);
      if (!mounted) return;
      setState(() {});
    }));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    int today = clock.now().weekday;
    if (today >= DateTime.saturday) {
      // If Sat or Sun
      return SizedBox(
        width: 15 * MediaQuery.of(context).size.width / 16,
        height: MediaQuery.of(context).size.height / 4,
        child: Card(
          elevation: 4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const <Widget>[
              Text(
                'No lessons today!',
                style: TextStyle(
                  fontSize: 32,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    today--;
    return SizedBox(
      width: 15 * MediaQuery.of(context).size.width / 16,
      height: MediaQuery.of(context).size.height / 4,
      child: Card(
        elevation: 4,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const Text(
              "Today's Timetable",
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            const Divider(
              indent: 4,
              endIndent: 4,
            ),
            Expanded(
              child: ListView(
                children: [
                  for (int idx = 0; idx < timetable[today].length; idx++)
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text('Period ${idx + 1}'),
                          Text(timetable[today][idx].name),
                        ],
                      ),
                    ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

Future<void> gotTimetable(http.Response response) async {
  if (response.statusCode != 200) return;
  Map<String, dynamic> data = json.decode(response.body);
  for (var i = 0; i < data['data'].length; i++) {
    var today = data['data'][i];
    for (var j = 0; j < today.length; j++) {
      var period = today[j];
      if (period == null) {
        timetable[i][j] = const TimetableData(
          -1,
          'None',
          'None',
          'None',
          '#FFFFFF',
        );
      } else {
        timetable[i][j] = TimetableData(
          period['subject_id'],
          period['name'],
          period['teacher'],
          period['room'],
          period['colour'],
        );
      }
    }
  }
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('timetable', json.encode(data['data']));
}

Future<void> gotSubjects(http.Response response) async {
  if (response.statusCode != 200) return;
  Map<String, dynamic> data = json.decode(response.body);
  subjects = [];
  for (var i = 0; i < data['data'].length; i++) {
    var subject = data['data'][i];
    subjects.add(
      TimetableData(
        subject['subject_id'],
        subject['name'],
        subject['teacher'],
        subject['room'],
        subject['colour'],
      ),
    );
  }
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('subjects', json.encode(data['data']));
}

class SubjectWidget extends StatelessWidget {
  const SubjectWidget(this.subject, this.settingTimetable, this.getSubjects,
      {Key? key})
      : super(key: key);

  final TimetableData subject;
  final Function(TimetableData) settingTimetable;
  final Function getSubjects;

  void modifySubject(Color colour) {
    var red = colour.red < 16
        ? '0${colour.red.toRadixString(16)}'
        : colour.red.toRadixString(16);
    var green = colour.green < 16
        ? '0${colour.green.toRadixString(16)}'
        : colour.green.toRadixString(16);
    var blue = colour.blue < 16
        ? '0${colour.blue.toRadixString(16)}'
        : colour.blue.toRadixString(16);

    addRequest(
      NetworkOperation(
        '/api/v1/subjects/${subject.id}',
        'PATCH',
        (http.Response response) {
          getSubjects();
          Navigator.of(navigatorKey.currentContext!).pop();
        },
        data: {
          'colour': '#$red$green$blue',
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColour = Color(
      int.parse(subject.colour.substring(1, 7), radix: 16) + 0xFF000000,
    );

    // Automatically change the text colour based on what will be easiest to see.
    Color textColour =
        backgroundColour.computeLuminance() > 0.5 ? Colors.black : Colors.white;

    // Variable to store the new colour once it is updated.
    Color changedTo = backgroundColour;
    return PopupMenuButton(
      itemBuilder: (BuildContext context) => [
        PopupMenuItem(
          value: 1,
          onTap: () {},
          child: const Text('Set timetable'),
        ),
        PopupMenuItem(
          value: 2,
          onTap: () {},
          child: const Text('Modify'),
        ),
      ],
      onSelected: (int value) {
        switch (value) {
          case 1:
            settingTimetable(subject);
            break;
          case 2:
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
                      'Change Subject Colour',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: ColorPicker(
                          enableAlpha: false,
                          hexInputBar: true,
                          pickerColor: changedTo,
                          onColorChanged: (value) => changedTo = value,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: ElevatedButton(
                          onPressed: () {
                            modifySubject(changedTo);
                          },
                          child: const Text('Update'),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Cancel'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
            break;
          default:
        }
      },
      child: Card(
        color: backgroundColour,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
              ),
              child: Text(
                subject.name,
                style: TextStyle(
                  color: textColour,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
              ),
              child: Text(
                subject.teacher,
                style: TextStyle(
                  color: textColour,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
              ),
              child: Text(
                subject.room,
                style: TextStyle(
                  color: textColour,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TimetablePage extends StatefulWidget {
  const TimetablePage({Key? key}) : super(key: key);

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String teacher = '';
  String room = '';
  String name = '';
  Color colour = const Color.fromARGB(255, 255, 255, 255);

  bool settingTimetable = false;
  TimetableData? toSetTo;

  void getTimetable() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedTimetable = prefs.getString('timetable');
    if (storedTimetable != null) {
      List<dynamic> data = json.decode(storedTimetable);
      for (var i = 0; i < data.length; i++) {
        var today = data[i];
        for (var j = 0; j < today.length; j++) {
          var period = today[j];
          if (period == null) {
            timetable[i][j] = const TimetableData(
              -1,
              'None',
              'None',
              'None',
              '#FFFFFF',
            );
          } else {
            timetable[i][j] = TimetableData(
              period['subject_id'],
              period['name'],
              period['teacher'],
              period['room'],
              period['colour'],
            );
          }
        }
      }
      if (!mounted) return;
      setState(() {});
    }
    addRequest(
      NetworkOperation(
        '/api/v1/timetable',
        'GET',
        (http.Response response) async {
          await gotTimetable(response);
          if (!mounted) return;
          setState(() {});
        },
      ),
    );
  }

  void onColourChanged(Color color) {
    colour = color.withAlpha(255);
  }

  void createSubject() {
    addRequest(
      NetworkOperation(
        '/api/v1/subjects',
        'POST',
        (http.Response response) async {
          await getSubjects();
          if (!mounted) return;
          setState(() {});
        },
        data: {
          'name': name,
          'teacher': teacher,
          'room': room,
          'colour': '#${(colour.value & 0x00FFFFFF).toRadixString(16)}',
        },
      ),
    );
    Navigator.of(context).popUntil(ModalRoute.withName('/dash'));
  }

  Future<void> getSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedSubjects = prefs.getString('subjects');
    if (storedSubjects != null) {
      List<dynamic> data = json.decode(storedSubjects);
      for (var i = 0; i < data.length; i++) {
        var subject = data[i];
        subjects.add(
          TimetableData(
            subject['subject_id'],
            subject['name'],
            subject['teacher'],
            subject['room'],
            subject['colour'],
          ),
        );
      }
      if (!mounted) return;
      setState(() {});
    }
    addRequest(
      NetworkOperation(
        '/api/v1/subjects/@me',
        'GET',
        (http.Response response) {
          gotSubjects(response);
          getTimetable();
          if (!mounted) return;
          setState(() {});
        },
        data: {
          'name': name,
          'teacher': teacher,
          'room': room,
          'colour':
              '#${colour.red.toRadixString(16)}${colour.green.toRadixString(16)}${colour.blue.toRadixString(16)}',
        },
      ),
    );
  }

  void toggleSetting(TimetableData subject) {
    settingTimetable = !settingTimetable;
    toSetTo = subject;
    if (!mounted) return;
    setState(() {});
  }

  @override
  void initState() {
    if (timetable[0].length != 9) {
      for (var i = 0; i < 5; i++) {
        for (var j = 0; j < 9; j++) {
          timetable[i].add(
            const TimetableData(
              -1,
              'Loading',
              'Loading',
              'Loading',
              '#FFFFFF',
            ),
          );
        }
      }
    }
    getSubjects();
    getTimetable();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    String baseColour =
        '#${(Theme.of(context).highlightColor.value & 0x00FFFFFF).toRadixString(16)}';
    double borderWidth = 1;
    double width =
        MediaQuery.of(context).size.width / 6 - (borderWidth * 2 + borderWidth);
    double height =
        MediaQuery.of(context).size.height / (timetable[0].length + 4) -
            (borderWidth * 2 + borderWidth);
    height *= 1.25;
    double indent = 16;
    return Scaffold(
      appBar: PLAppBar('Timetable', context),
      backgroundColor: Theme.of(context).backgroundColor,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8),
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    backgroundColor: Theme.of(context).highlightColor,
                    side: const BorderSide(color: Colors.black),
                  ),
                  icon: Icon(
                    settingTimetable ? Icons.stop : Icons.add,
                    color: Colors.black,
                  ),
                  onPressed: () {
                    if (settingTimetable) {
                      if (!mounted) return;
                      setState(() => settingTimetable = false);
                    } else {
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
                                'Creating Subject',
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
                                      labelText: 'Subject Name',
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
                                      createSubject();
                                    },
                                  ),
                                  TextFormField(
                                    decoration: const InputDecoration(
                                      labelText: 'Teacher',
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Enter a teacher';
                                      }
                                      return null;
                                    },
                                    onChanged: (value) {
                                      teacher = value;
                                    },
                                    onFieldSubmitted: (String _) {
                                      createSubject();
                                    },
                                  ),
                                  TextFormField(
                                    decoration: const InputDecoration(
                                      labelText: 'Room',
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Enter a room';
                                      }
                                      return null;
                                    },
                                    onChanged: (value) {
                                      room = value;
                                    },
                                    onFieldSubmitted: (String _) {
                                      createSubject();
                                    },
                                  ),
                                  ColorPicker(
                                    enableAlpha: false,
                                    hexInputBar: true,
                                    pickerColor: colour,
                                    onColorChanged: onColourChanged,
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      // Validate the form (returns true if all is ok)
                                      if (_formKey.currentState!.validate()) {
                                        createSubject();
                                      }
                                    },
                                    child: const Text('Create'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }
                  },
                  label: Text(
                    settingTimetable ? 'Stop Setting' : 'New',
                    style: const TextStyle(
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SizedBox(
                  height: 64,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (TimetableData subject in subjects)
                        SubjectWidget(subject, toggleSetting, getSubjects),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              TimetableSlot(
                0,
                -1,
                TimetableData(
                  -1,
                  'Monday',
                  '',
                  '',
                  baseColour,
                ),
                settingTimetable,
                toSetTo,
                width: width,
                height: height,
                borderWidth: borderWidth * 2,
                clickable: false,
              ),
              TimetableSlot(
                1,
                -1,
                TimetableData(
                  -1,
                  'Tuesday',
                  '',
                  '',
                  baseColour,
                ),
                settingTimetable,
                toSetTo,
                width: width,
                height: height,
                borderWidth: borderWidth * 2,
                clickable: false,
              ),
              TimetableSlot(
                2,
                -1,
                TimetableData(
                  -1,
                  'Wednesday',
                  '',
                  '',
                  baseColour,
                ),
                settingTimetable,
                toSetTo,
                width: width,
                height: height,
                borderWidth: borderWidth * 2,
                clickable: false,
              ),
              TimetableSlot(
                3,
                -1,
                TimetableData(
                  -1,
                  'Thursday',
                  '',
                  '',
                  baseColour,
                ),
                settingTimetable,
                toSetTo,
                width: width,
                height: height,
                borderWidth: borderWidth * 2,
                clickable: false,
              ),
              TimetableSlot(
                4,
                -1,
                TimetableData(
                  -1,
                  'Friday',
                  '',
                  '',
                  baseColour,
                ),
                settingTimetable,
                toSetTo,
                width: width,
                height: height,
                borderWidth: borderWidth * 2,
                clickable: false,
              ),
            ],
          ),
          Divider(
            indent: indent,
            endIndent: indent,
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return ListView(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        for (int period = 0;
                            period < timetable[0].length && period < 4;
                            period++)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              for (int day = 0; day < timetable.length; day++)
                                TimetableSlot(
                                  day,
                                  period,
                                  timetable[day][period],
                                  settingTimetable,
                                  toSetTo,
                                  width: width,
                                  height: height,
                                  borderWidth: borderWidth,
                                  reset: getTimetable,
                                ),
                            ],
                          ),
                        Divider(
                          indent: indent,
                          endIndent: indent,
                        ),
                        for (int period = 4;
                            period < timetable[0].length && period < 6;
                            period++)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              for (int day = 0; day < timetable.length; day++)
                                TimetableSlot(
                                  day,
                                  period,
                                  timetable[day][period],
                                  settingTimetable,
                                  toSetTo,
                                  width: width,
                                  height: height,
                                  borderWidth: borderWidth,
                                  reset: getTimetable,
                                ),
                            ],
                          ),
                        Divider(
                          indent: indent,
                          endIndent: indent,
                        ),
                        for (int period = 6;
                            period < timetable[0].length;
                            period++)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              for (int day = 0; day < timetable.length; day++)
                                TimetableSlot(
                                  day,
                                  period,
                                  timetable[day][period],
                                  settingTimetable,
                                  toSetTo,
                                  width: width,
                                  height: height,
                                  borderWidth: borderWidth,
                                  reset: getTimetable,
                                ),
                            ],
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
