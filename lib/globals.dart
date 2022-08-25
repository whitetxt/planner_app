import 'dart:async';
import 'dart:isolate';

import "package:flutter/material.dart";

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

String token = "";
List<String> notifs = [];

void addNotif(String text) {
  print(text);
  /*notifs.add(text);
  Timer(
    const Duration(seconds: 2, milliseconds: 500),
    () {
      notifs.removeAt(0);
    },
  );*/
}

String apiUrl = "http://127.0.0.1:8000";
SendPort? networkSendPort;
