import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import "package:http/http.dart" as http;

import "globals.dart";

bool onlineMode = true;
Timer? onlineTest;

List<NetworkOperation> pending = [];

class NetworkOperation {
  NetworkOperation(this.url, this.method, this.callback, {this.data});

  String url; // The url to contact.
  final String method; // The method to use (GET, POST etc.)
  final Map<String, dynamic>? data; // The data to send along in the body.
  final Function(http.Response)
      callback; // The function to call with the data retrieved.
}

class PortData {
  const PortData({this.send, this.data, this.operation});

  final SendPort? send;
  final String? data;
  final NetworkOperation? operation;
}

void addRequest(NetworkOperation request) {
  request.url = apiUrl + request.url;
  while (token.isEmpty) {
    sleep(const Duration(milliseconds: 100));
  }
  if (onlineMode) {
    processNetworkRequest(request).then(
      (value) {
        if (value.statusCode == 999) {
          pending.add(request);
          onlineMode = false;
          createOnlineTest();
        } else {
          request.callback(value);
        }
      },
    );
  } else {
    pending.add(request);
    createOnlineTest();
  }
}

void createOnlineTest() {
  onlineTest ??= Timer.periodic(
    const Duration(seconds: 10),
    (timer) {
      processNetworkRequest(NetworkOperation("$apiUrl/", "GET", (_) {})).then(
        (http.Response resp) {
          if (validateResponse(resp)) {
            onlineMode = true;
            for (var request in pending) {
              // We must rate-limit ourselves since the server has just started back up,
              // it will be under quite a lot of load from other users and we don't want
              // to overload it.

              // This queues up all of the requests for once every 250ms (4 per second).
              Future.delayed(
                Duration(milliseconds: pending.indexOf(request) * 250),
                () => processNetworkRequest(request).then(
                  (value) => request.callback(value),
                ),
              );
            }
            pending = [];
            addNotif("Back online!", error: false);
            timer.cancel();
            onlineTest = null;
            Timer(
              const Duration(seconds: 1),
              () => ScaffoldMessenger.of(
                scaffoldKey.currentContext!,
              ).clearSnackBars(),
            );
          }
        },
      );
    },
  );
}

bool validateResponse(http.Response response) {
  if (response.statusCode != 200) {
    if (response.statusCode == 500) {
      addNotif("Internal Server Error", error: true);
      return false;
    }
    if (response.statusCode > 900) {
      return false;
    }
    addNotif(response.body, error: true);
    return false;
  }
  return true;
}

Future<http.Response> processNetworkRequest(NetworkOperation task) async {
  http.Response? response;
  switch (task.method) {
    case "GET":
      response = await performRequest(
        http.get,
        task.url,
        null,
      );
      break;
    case "POST":
      response = await performRequest(
        http.post,
        task.url,
        task.data,
      );
      break;
    case "DELETE":
      response = await performRequest(
        http.delete,
        task.url,
        task.data,
      );
      break;
    case "PUT":
      response = await performRequest(
        http.put,
        task.url,
        task.data,
      );
      break;
    case "PATCH":
      response = await performRequest(
        http.patch,
        task.url,
        task.data,
      );
      break;
    default:
      throw Exception("Unknown method type: ${task.method}");
  }
  return response;
}

Future<http.Response> performRequest(
  Function method,
  String url,
  Map<String, dynamic>? body,
) async {
  if (token.isEmpty) {
    return http.Response("", 998);
  }
  if (body != null) {
    return await method(
      Uri.parse(url),
      body: body,
      headers: {"Authorization": token},
    ).catchError(
      (error, stackTrace) {
        if (url != "$apiUrl/") {
          ScaffoldMessenger.of(
            scaffoldKey.currentContext!,
          ).clearSnackBars();
          addNotif(
            "Connection Error. Running in offline mode.",
          );
          addNotif(
            "If you close the app before we are back online, data will be lost.",
          );
          onlineMode = false;
        }
        return http.Response("", 999);
      },
    );
  }
  return await method(
    Uri.parse(url),
    headers: {"Authorization": token},
  ).catchError(
    (error, stackTrace) {
      if (url != "$apiUrl/") {
        ScaffoldMessenger.of(
          scaffoldKey.currentContext!,
        ).clearSnackBars();
        addNotif(
          "Connection Error. Running in offline mode.",
        );
        addNotif(
          "If you close the app before we are back online, data will be lost.",
        );
        onlineMode = false;
      }
      return http.Response("", 999);
    },
  );
}
