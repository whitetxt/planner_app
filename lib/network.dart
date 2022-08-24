import 'dart:io';
import 'dart:isolate';

import "package:http/http.dart" as http;
import "package:collection/collection.dart";

import "globals.dart";

class NetworkOperation {
  NetworkOperation(this.url, this.method, this.callback,
      {this.data, this.priority = 0});

  String url; // The url to contact
  final String method; // The method to use (GET, POST etc.)
  final Map<String, dynamic>? data; // The data to send along in the body.
  final Function(http.Response)
      callback; // The function to call with the data retrieved.
  final int priority;
}

class PortData {
  const PortData({this.send, this.data, this.operation});

  final SendPort? send;
  final String? data;
  final NetworkOperation? operation;
}

PriorityQueue<NetworkOperation> networkRequestQueue =
    PriorityQueue<NetworkOperation>(
  (elem1, elem2) => elem1.priority.compareTo(elem2.priority),
);

void addRequest(NetworkOperation request) {
  request.url = apiUrl + request.url;
  networkSendPort!.send(PortData(operation: request));
}

void processNetworkRequests(SendPort port) async {
  bool looping = true;
  ReceivePort recieve = ReceivePort();
  recieve.listen(
    (value) {
      PortData realData = value as PortData;
      if (realData.data != null) {
        if (realData.data!.contains("kill")) {
          looping = false;
        }
      }
      if (realData.operation != null) {
        networkRequestQueue.add(realData.operation!);
      }
    },
  );
  port.send(PortData(send: recieve.sendPort, data: "Created Network Thread."));
  while (looping) {
    sleep(const Duration(milliseconds: 250));
    if (networkRequestQueue.isEmpty) continue;
    print("Processing a Request.");
    NetworkOperation task = networkRequestQueue.removeFirst();
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
      default:
        print("Unknown method type: ${task.method}");
        continue;
    }
    port.send("Processing ${task.method} ${task.url} with body ${task.data}");
    task.callback(response);
  }
}

Future<http.Response> performRequest(
  Function method,
  String url,
  Map<String, dynamic>? body,
) async {
  if (body != null) {
    return await method(
      Uri.parse(url),
      body: body,
      headers: {"Authorization": token},
    );
  }
  return await method(
    Uri.parse(url),
    headers: {"Authorization": token},
  );
}
