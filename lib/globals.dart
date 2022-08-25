import 'dart:isolate';

import "package:flutter/material.dart";
import "dart:async";

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

String token = "";
//List<Popup> popups = [];

void createPopup(String text) {
  print(text);
  //popups.add(Popup(text));
}

String apiUrl = "http://127.0.0.1:8000";
SendPort? networkSendPort;
