import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import "package:flutter/material.dart";
import 'package:flutter_calendar_widget/flutter_calendar_widget.dart';
import "package:http/http.dart" as http;
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import 'globals.dart';
import 'network.dart';
import "pl_appbar.dart"; // Provides PLAppBar for the bar at the top of the screen.

class Event {
  // This class represents an event stored in the server's database.
  const Event(
    this.eventId,
    this.userId,
    this.name,
    this.time,
    this.description,
  );

  // All of the fields are marked as final, which means they cannot be modified after instantiation.
  final int eventId;
  final int userId;
  final String name;
  final DateTime time;
  final String? description;

  factory Event.fromJson(Map<String, dynamic> json) {
    // This function lets me easily convert a response from the server into this object.
    return Event(
      json["event_id"],
      json["user_id"],
      json["name"],
      DateTime.fromMillisecondsSinceEpoch(json["time"]),
      json["description"],
    );
  }
}

Map<DateTime, List<Event>> events = {};

class EventsMini extends StatefulWidget {
  const EventsMini({Key? key}) : super(key: key);

  @override
  State<EventsMini> createState() => _EventsMiniState();
}

class _EventsMiniState extends State<EventsMini> {
  @override
  void initState() {
    // We call initState first, just in the rare case that the request returns
    // quicker than we can initState, and it attempts to setState on something
    // that has not been init'd.
    super.initState();
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
                if (!mounted) return;
                setState(
                    () {}); // This then just forces the page to rebuild and redraw itself.
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If we are offline, there's no point allowing the user to see events since
    // their local version will be outdated and new events will be hidden from them.
    if (!onlineMode) {
      return SizedBox(
        width: 15 * MediaQuery.of(context).size.width / 16,
        height: MediaQuery.of(context).size.height / 4,
        child: Card(
          elevation: 4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const <Widget>[
              Text(
                "Offline :(",
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
    bool upcoming = false;
    for (DateTime date in events.keys) {
      if (upcoming || date.isBefore(DateTime.now())) continue;
      upcoming = true;
      break;
    }
    // If there's no events in the future, we should just show that instead of an
    // empty menu.
    if (!upcoming) {
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
        child: SingleChildScrollView(
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
                for (DateTime date in events.keys)
                  // For each of the days that there are events, we should check
                  // if its today, or after today since we don't want to show
                  // previous events.
                  if (date.isAfter(DateTime.now()) ||
                      date.difference(DateTime.now()).inDays == 0)
                    for (Event event in events[date]!)
                      // As we only checked for the day previously, we must now
                      // check that it is after the current time.
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
                                // The ? : operator is called the ternary operator.
                                // It allows me to easily put IF-ELSE statements such as this into code
                                // without having to write it explicitly.
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
      ),
    );
  }
}

void gotEvents(http.Response response, {bool add = false}) {
  // This just handles the server's response for returning events.
  // We must check for an error, then notify the user of it.
  if (!validateResponse(response)) return;
  dynamic data = json.decode(response.body);
  if (data["status"] != "success") {
    addNotif(data["message"], error: true);
    return;
  }
  if (!add) {
    events = {};
  }
  if (data["data"] != null) {
    for (dynamic rawEvent in data["data"]) {
      Event event = Event.fromJson(rawEvent);
      DateTime eventTime = DateTime(
        // Since the DateTime provided is too precise and not specifically a day,
        // It must be recreated using the fields in order to just specify a day.
        event.time.year,
        event.time.month,
        event.time.day,
      );
      if (events.containsKey(eventTime)) {
        if (events[eventTime]!.every(
          (Event e) {
            return e.name != event.name &&
                e.eventId != event.eventId &&
                e.description != event.description &&
                e.time != event.time;
          },
        )) {
          // Since public events will show up in both responses for the owners,
          // If this event already exists we don't want to add it again.
          events[eventTime]!.add(event);
        }
      } else {
        events[eventTime] = [event];
      }
    }
  }
}

class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  String name = "";
  DateTime time = DateTime.now();
  String description = "";
  bool? private = true;

  List<Event> _selectedEvents = [];
  DateTime _selectedDay = DateTime.now();

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
                if (!mounted) return;
                setState(() {
                  _selectedEvents =
                      events.containsKey(time) ? events[time]! : [];
                }); // This then just forces the page to rebuild and redraw itself.
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
    // Again, we refesh after initState to prevent calling setState on an invalid state.
    refreshCalendar();
  }

  @override
  Widget build(BuildContext context) {
    // If we are offline, again, we do not want to allow the user to modify events.
    // As the server would not see these changes.
    if (!onlineMode) {
      return Scaffold(
        appBar: PLAppBar("Calendar", context),
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
                "Events cannot be managed without an internet connection.",
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
      appBar: PLAppBar("Calendar", context),
      backgroundColor: Theme.of(context).backgroundColor,
      body: ListView(
        children: <Widget>[
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.now().add(
              const Duration(days: 365),
            ),
            startingDayOfWeek: StartingDayOfWeek.monday,
            focusedDay: DateTime.now(),
            rangeSelectionMode: RangeSelectionMode.disabled,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              time = selectedDay;
              setState(() {
                _selectedDay = selectedDay;
                bool found = false;
                for (DateTime day in events.keys) {
                  if (isSameDay(day, _selectedDay)) {
                    _selectedEvents = events[day]!;
                    found = true;
                    break;
                  }
                }
                if (!found) {
                  _selectedEvents = [];
                }
              });
            },
            eventLoader: (day) {
              for (DateTime kDay in events.keys) {
                if (isSameDay(kDay, day)) {
                  return events[kDay]!;
                }
              }
              return [];
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
                          // Adding the key here, allows me to check if this form is
                          // valid later on in the code.
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
                                    initialDate: time,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(
                                      const Duration(days: 365),
                                    ),
                                  );
                                  final TimeOfDay? selectedTime =
                                      await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.now(),
                                  );
                                  if (selected != null) {
                                    if (!mounted) return;
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
                                        // We want to show that this was successful,
                                        // and so we set the text of the text field.
                                        _dateController.text =
                                            DateFormat("dd-MM-yy HH:mm")
                                                .format(time);
                                      },
                                    );
                                  }
                                },
                                child: TextFormField(
                                  // This form is disabled, as the code inside the
                                  // InkWell will control its text.
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
                                keyboardType: TextInputType.multiline,
                                maxLines: 5,
                                onChanged: (value) {
                                  description = value;
                                },
                                onFieldSubmitted: (String _) {
                                  createEvent();
                                },
                              ),
                              // We have 2 different buttons for private and public
                              // events, as this makes it easier to see whats going on.
                              // Both call the same function, they just change a bool
                              // to be correct before they call createEvent.
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
                              if (me != null &&
                                  me!.permissions == Permissions.teacher)
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
                        // As the time until should be formatted nicely, this
                        // long statement is used to format it into different
                        // formats depending on how far away it is.
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
                    if (event.userId == me!.uid)
                      ListTile(
                        title: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade400,
                          ),
                          child: const Text("Delete"),
                          onPressed: () {
                            addRequest(
                              NetworkOperation(
                                "/api/v1/events/${event.eventId}",
                                "DELETE",
                                (http.Response resp) {
                                  if (!validateResponse(resp)) return;
                                  refreshCalendar();
                                  if (!mounted) return;
                                  setState(() {
                                    _selectedEvents = events.containsKey(time)
                                        ? events[time]!
                                        : [];
                                  });
                                },
                              ),
                            );
                          },
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
