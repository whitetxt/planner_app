import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import "package:flutter/material.dart";
import 'package:flutter_calendar_widget/flutter_calendar_widget.dart';
import "package:http/http.dart" as http;
import 'package:intl/intl.dart';

import 'globals.dart';
import 'network.dart';
import "pl_appbar.dart"; // Provides PLAppBar for the bar at the top of the screen.

class Event {
  const Event(
    this.eventId,
    this.userId,
    this.name,
    this.time,
    this.description,
  );

  final int eventId;
  final int userId;
  final String name;
  final DateTime time;
  final String? description;

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      json["event_id"],
      json["user_id"],
      json["name"],
      DateTime.fromMillisecondsSinceEpoch(json["time"]),
      json["description"],
    );
  }
}

EventList<Event> events = EventList(events: {});

class EventsMini extends StatefulWidget {
  const EventsMini({Key? key}) : super(key: key);

  @override
  State<EventsMini> createState() => _EventsMiniState();
}

class _EventsMiniState extends State<EventsMini> {
  @override
  void initState() {
    addRequest(
      NetworkOperation(
        "/api/v1/events",
        "GET",
        (http.Response response) {
          gotEvents(response);
          addRequest(
            NetworkOperation(
              "/api/v1/events/user/@me",
              "GET",
              (http.Response response) {
                gotEvents(response, add: true);
                Navigator.of(context).popUntil(ModalRoute.withName(
                    "/dash")); // This removes any modals or popup dialogs that are active at the current time.
                setState(
                    () {}); // This then just forces the page to rebuild and redraw itself.
              },
            ),
          );
        },
      ),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    bool upcoming = false;
    for (DateTime date in events.events.keys) {
      if (upcoming || date.isBefore(DateTime.now())) continue;
      upcoming = true;
      break;
    }
    if (!upcoming) {
      // If there arent any events in the future.
      return SizedBox(
        width: 15 * MediaQuery.of(context).size.width / 16,
        height: MediaQuery.of(context).size.height / 4,
        child: Card(
          elevation: 4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const <Widget>[
              Text(
                "No upcoming events!",
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
    return SizedBox(
      width: 15 * MediaQuery.of(context).size.width / 16,
      height: MediaQuery.of(context).size.height / 4,
      child: Card(
        elevation: 4,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            const AutoSizeText(
              "Upcoming Events",
              style: TextStyle(fontSize: 18),
              maxLines: 1,
              minFontSize: 12,
            ),
            const Divider(
              indent: 4,
              endIndent: 4,
            ),
            ...[
              for (DateTime date in events.events.keys)
                if (date.isAfter(DateTime.now()) ||
                    date.difference(DateTime.now()).inDays == 0)
                  for (Event event in events.events[date]!)
                    if (event.time.isAfter(DateTime.now()))
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            AutoSizeText(
                              "${event.name} - ${DateFormat('HH:mm').format(event.time)}",
                              style: const TextStyle(fontSize: 16),
                              maxLines: 1,
                              minFontSize: 8,
                            ),
                            AutoSizeText(
                              event.time.difference(DateTime.now()) >=
                                      const Duration(days: 1, hours: 12)
                                  ? "In ${event.time.difference(DateTime.now()).inDays} days and ${event.time.difference(DateTime.now()).inHours - event.time.difference(DateTime.now()).inDays * 24} hours"
                                  : event.time.difference(DateTime.now()) >=
                                          const Duration(hours: 12)
                                      ? "In ${event.time.difference(DateTime.now()).inHours} hours"
                                      : "In ${event.time.difference(DateTime.now()).toString().substring(0, 4)}",
                              style: const TextStyle(fontSize: 16),
                              maxLines: 1,
                              minFontSize: 8,
                            ),
                          ],
                        ),
                      ),
            ]
          ],
        ),
      ),
    );
  }
}

void gotEvents(http.Response response, {bool add = false}) {
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
  if (!add) {
    events = EventList<Event>(events: {});
  }
  if (data["data"] != null) {
    for (dynamic rawEvent in data["data"]) {
      Event event = Event.fromJson(rawEvent);
      events.add(
        DateTime(event.time.year, event.time.month, event.time.day),
        event,
      );
    }
  }
}

class CalendarPage extends StatefulWidget {
  const CalendarPage(this.token, {Key? key}) : super(key: key);

  final String token;

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  String name = "";
  DateTime time = DateTime.now();
  String description = "";
  bool? private = true;

  List<Event> _selectedEvents = [];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();

  void refreshCalendar() {
    // This refreshes the page, grabbing new data from the API.
    addRequest(
      NetworkOperation(
        "/api/v1/events",
        "GET",
        (http.Response response) {
          gotEvents(response);
          addRequest(
            NetworkOperation(
              "/api/v1/events/user/@me",
              "GET",
              (http.Response response) {
                gotEvents(response, add: true);
                Navigator.of(context).popUntil(ModalRoute.withName(
                    "/dash")); // This removes any modals or popup dialogs that are active at the current time.
                setState(
                    () {}); // This then just forces the page to rebuild and redraw itself.
              },
            ),
          );
        },
      ),
    );
  }

  void createEvent() {
    // This tells the server to create an event, then refreshes the page.
    addRequest(
      NetworkOperation(
        "/api/v1/events",
        "POST",
        (http.Response response) {
          refreshCalendar();
        },
        data: {
          "name": name,
          "time": time.millisecondsSinceEpoch.toString(),
          "description": description,
          "private": private.toString(),
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    refreshCalendar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PLAppBar("Calendar", context),
      backgroundColor: Theme.of(context).backgroundColor,
      body: ListView(
        children: <Widget>[
          FlutterCalendar(
            selectionMode: CalendarSelectionMode.single,
            startingDayOfWeek: DayOfWeek.mon,
            focusedDate: DateTime.now(),
            events: events,
            onDayPressed: (DateTime day) {
              time = day;
              setState(() {
                _selectedEvents = events.get(day);
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
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
                            "Create an Event",
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
                                  labelText: "Name",
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
                                  createEvent();
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
                                  final TimeOfDay? selectedTime =
                                      await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.now(),
                                  );
                                  if (selected != null) {
                                    setState(
                                      () {
                                        time = selected;
                                        if (selectedTime != null) {
                                          time = time.add(
                                            Duration(
                                              hours: selectedTime.hour,
                                              minutes: selectedTime.minute,
                                            ),
                                          );
                                        }
                                        _dateController.text =
                                            DateFormat("dd-MM-yy HH:mm")
                                                .format(time);
                                      },
                                    );
                                  }
                                },
                                child: TextFormField(
                                  enabled: false,
                                  controller: _dateController,
                                  decoration: const InputDecoration(
                                    label: Text("Date"),
                                  ),
                                ),
                              ),
                              TextFormField(
                                decoration: const InputDecoration(
                                  labelText: "Description",
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  description = value;
                                },
                                onFieldSubmitted: (String _) {
                                  createEvent();
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Validate the form (returns true if all is ok)
                                    if (_formKey.currentState!.validate()) {
                                      private = true;
                                      createEvent();
                                    }
                                  },
                                  child: const Text('Create Private Event'),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Validate the form (returns true if all is ok)
                                    if (_formKey.currentState!.validate()) {
                                      private = false;
                                      createEvent();
                                    }
                                  },
                                  child: const Text('Create Public Event'),
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
            ],
          ),
          ...[
            for (Event event in _selectedEvents)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: event.time.difference(DateTime.now()) <
                            const Duration(days: 1)
                        ? Colors.red
                        : event.time.difference(DateTime.now()) <
                                const Duration(days: 3)
                            ? Colors.orange
                            : Colors.green,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ExpansionTile(
                  title: Text(
                    "${event.name} - ${DateFormat('HH:mm').format(event.time)}",
                    style: const TextStyle(
                      fontSize: 24,
                    ),
                  ),
                  children: <ListTile>[
                    ListTile(
                      title: Text(
                        event.time.isBefore(DateTime.now())
                            ? "Event has happened."
                            : event.time.difference(DateTime.now()) >=
                                    const Duration(days: 1, hours: 12)
                                ? "In ${event.time.difference(DateTime.now()).inDays} days and ${event.time.difference(DateTime.now()).inHours - event.time.difference(DateTime.now()).inDays * 24} hours"
                                : event.time.difference(DateTime.now()) >=
                                        const Duration(hours: 12)
                                    ? "In ${event.time.difference(DateTime.now()).inHours} hours"
                                    : "In ${event.time.difference(DateTime.now()).toString().substring(0, 4)}",
                      ),
                    ),
                    ListTile(
                      title: Text(
                        event.description == null
                            ? "No Description"
                            : event.description!,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
