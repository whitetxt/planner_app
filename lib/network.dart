import 'dart:io';
import 'dart:isolate';

import "package:http/http.dart" as http;

import "globals.dart";

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
  processNetworkRequest(request).then((value) => request.callback(value));
}

bool validateResponse(http.Response response) {
  if (response.statusCode != 200) {
    if (response.statusCode == 500) {
      addNotif("Internal Server Error", error: true);
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
