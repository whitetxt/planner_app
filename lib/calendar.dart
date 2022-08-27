import 'dart:convert';

import 'package:collection/collection.dart';
import "package:flutter/material.dart";
import 'package:flutter_calendar_widget/flutter_calendar_widget.dart';
import "package:http/http.dart" as http;

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
  final String description;

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(json["event_id"], json["user_id"], json["name"], json["time"],
        json["description"]);
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
  Widget build(BuildContext context) {
    return Container(child: const Text("hello event mini"));
  }
}

void gotEvents(http.Response response) {
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
  events = EventList<Event>(events: {});
  if (data["data"] != null) {
    for (dynamic rawEvent in data["data"]) {
      Event event = Event.fromJson(rawEvent);
      events.add(event.time, event);
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

  void refreshCalendar() {
    // This refreshes the page, grabbing new data from the API.
    addRequest(
      NetworkOperation(
        "/api/v1/events",
        "GET",
        (http.Response response) {
          gotEvents(response);
          Navigator.of(context).popUntil(ModalRoute.withName(
              "/dash")); // This removes any modals or popup dialogs that are active at the current time.
          setState(
              () {}); // This then just forces the page to rebuild and redraw itself.
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
          "private": private,
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
      body: Center(
        child: Column(
          children: [
            FlutterCalendar(
              selectionMode: CalendarSelectionMode.single,
              startingDayOfWeek: DayOfWeek.mon,
              selectedDates: [DateTime.now()],
              focusedDate: DateTime.now(),
              events: events,
              onDayPressed: (DateTime day) {
                List<Event> event = events.get(day);
              },
            ),
          ],
        ),
      ),
    );
  }
}
