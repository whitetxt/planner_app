import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:clock/clock.dart';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import 'globals.dart';
import 'pl_appbar.dart'; // Provides PLAppBar for the bar at the top of the screen.
import 'network.dart'; // Allows network requests on this page.

class TimetableData {
  const TimetableData(this.id, this.name, this.teacher, this.room, this.colour);

  final int id;
  final String name;
  final String teacher;
  final String room;
  final String? colour;
}

List<List<TimetableData>> timetable = [[], [], [], [], []];

List<TimetableData> subjects = [];

class TimetableSlot extends StatefulWidget {
  const TimetableSlot(
    this.day,
    this.period,
    this.data,
    this.settingSubject,
    this.toSetTo, {
    Key? key,
    // The following are optional fields, so that this widget can be customized.
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
  TimetableData? data;

  @override
  Widget build(BuildContext context) {
    data ??= widget.data;
    Color bg;
    if (data!.colour == null) {
      bg = Theme.of(context).highlightColor;
    } else {
      bg = Color(
        // Convert a hex code back into a color object.
        int.parse(data!.colour!.substring(1, 7), radix: 16) + 0xFF000000,
      );
    }
    return GestureDetector(
      onTap: () {
        if (!widget.clickable) return;
        if (widget.settingSubject) {
          if (widget.toSetTo == null) return;
          setState(() {
            data = widget.toSetTo!;
          });
          addRequest(
            NetworkOperation(
              '/api/v1/timetable',
              'POST',
              (http.Response resp) {
                addRequest(
                  NetworkOperation(
                    '/api/v1/timetable',
                    'GET',
                    (http.Response resp) async {
                      await gotTimetable(resp);
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
                    data!.name,
                    textAlign: TextAlign.center,
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      "Room: ${data!.room.isEmpty ? 'None' : data!.room}",
                    ),
                    Text(
                      "Teacher: ${data!.teacher.isEmpty ? 'None' : data!.teacher}",
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
                        data!.name,
                        textAlign: TextAlign.center,
                        minFontSize: 5,
                        maxFontSize: 16,
                        stepGranularity: 0.1,
                        maxLines: 3,
                        semanticsLabel: data!.name,
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
    // Adjust the day so that Monday is 0 instead of 1.
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
                          Text(timetable[today][idx].teacher),
                          Text(timetable[today][idx].room),
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
          null,
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
  const SubjectWidget(
    this.subject,
    this.settingTimetable,
    this.getSubjects,
    this.beingSet, {
    Key? key,
  }) : super(key: key);

  final TimetableData subject;
  final Function(TimetableData) settingTimetable;
  final Function getSubjects;
  final bool beingSet;

  void modifySubject(Color colour) {
    var red = colour.red.toRadixString(16).padLeft(2, '0');
    var green = colour.green.toRadixString(16).padLeft(2, '0');
    var blue = colour.blue.toRadixString(16).padLeft(2, '0');

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
    Color backgroundColour;
    if (subject.colour == null) {
      backgroundColour = Theme.of(context).highlightColor;
    } else {
      backgroundColour = Color(
        int.parse(subject.colour!.substring(1, 7), radix: 16) + 0xFF000000,
      );
    }

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
            break;
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
                  fontWeight: beingSet ? FontWeight.bold : FontWeight.normal,
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
                  fontWeight: beingSet ? FontWeight.bold : FontWeight.normal,
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
                  fontWeight: beingSet ? FontWeight.bold : FontWeight.normal,
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
            // If there is no period, then just set it to have no data.
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
    // Convert the color object into a hex code.
    String red = colour.red.toRadixString(16).padLeft(2, '0');
    String green = colour.green.toRadixString(16).padLeft(2, '0');
    String blue = colour.blue.toRadixString(16).padLeft(2, '0');
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
          'colour': '#$red$green$blue',
        },
      ),
    );
    Navigator.of(context).popUntil(ModalRoute.withName('/dash'));
  }

  Future<void> getSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedSubjects = prefs.getString('subjects');
    if (storedSubjects != null) {
      // Overwrite current subject data with the stored data.
      subjects = [];
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
        (http.Response response) async {
          await gotSubjects(response);
          if (!mounted) return;
          setState(() {
            getTimetable();
          });
        },
      ),
    );
  }

  void setTimetableSubject(TimetableData subject) {
    // Tells the timetables to set their subject when clicked.
    if (!mounted) return;
    setState(() {
      settingTimetable = true;
      toSetTo = subject;
    });
  }

  @override
  void initState() {
    super.initState();
    if (timetable[0].length != 9) {
      // If the timetable doesn't have all of the items in it, we need to load it.
      // In this case, we show the user that it is loading.
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
  }

  @override
  Widget build(BuildContext context) {
    String baseColour =
        '#${(Theme.of(context).highlightColor.value & 0x00FFFFFF).toRadixString(16)}';
    double borderWidth = 1;
    double width = MediaQuery.of(context).size.width / (timetable.length + 1) -
        (borderWidth * 2 + borderWidth);
    double height =
        MediaQuery.of(context).size.height / (timetable[0].length + 4) -
            (borderWidth * 2 + borderWidth);
    height *= 1.25;
    double indent = 16;
    return Scaffold(
      appBar: PLAppBar('Timetable', context),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      backgroundColor: Theme.of(context).highlightColor,
                    ),
                    icon: Icon(settingTimetable ? Icons.stop : Icons.add),
                    label: Text(settingTimetable ? 'Stop Setting' : 'New'),
                    onPressed: () {
                      if (settingTimetable) {
                        if (!mounted) return;
                        // If we are currently setting the timetable, stop setting it.
                        setState(() {
                          settingTimetable = false;
                          toSetTo = null;
                        });
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
                                        } else if (value.length > 32) {
                                          return 'Subject name must be less than 32 characters';
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
                                        } else if (value.length > 32) {
                                          return "Teacher's name must be less than 32 characters";
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
                                        } else if (value.length > 16) {
                                          return 'Room must be less than 16 characters';
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
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: ColorPicker(
                                          enableAlpha: false,
                                          hexInputBar: true,
                                          pickerColor: colour,
                                          onColorChanged: onColourChanged,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          // Validate the form (returns true if all is ok)
                                          if (_formKey.currentState!
                                              .validate()) {
                                            createSubject();
                                          }
                                        },
                                        child: const Text('Create'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }
                    },
                  ),
                ),
                Expanded(
                  child: SizedBox(
                    height: 80,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (TimetableData subject in subjects)
                          SubjectWidget(
                            subject,
                            setTimetableSubject,
                            getTimetable,
                            subject == toSetTo,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
