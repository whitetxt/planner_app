import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'globals.dart';

bool onlineMode = true;
Timer? onlineTest;

// A queue is used here to ensure that all of the pending requests are processed
// in the order that they were made.
Queue<NetworkOperation> pendingRequests = Queue();

class NetworkOperation {
  NetworkOperation(this.url, this.method, this.callback, {this.data});

  String url; // The url to contact.
  final String method; // The method to use (GET, POST etc.)
  final Map<String, dynamic>? data; // The data to send along in the body.
  final Function(http.Response)
      callback; // The function to call with the data retrieved.
}

void addRequest(NetworkOperation request) {
  request.url = apiUrl + request.url;
  while (token.isEmpty) {
    sleep(const Duration(milliseconds: 100));
  }
  if (onlineMode) {
    // If we are online, then process this request normally.
    processNetworkRequest(request).then(
      (value) {
        if (value.statusCode == 999) {
          // Status code 999 is not used by HTTP, and so I use it to show a connection error.
          // If this occurs, then stop sending requests and start checking for whenever we
          // come back online.
          pendingRequests.add(request);
          onlineMode = false;
          createOnlineTest();
        } else {
          request.callback(value);
        }
      },
    );
  } else {
    // If we are offline, then add it to the requests to be processed and start checking
    // for when we come back online.
    pendingRequests.add(request);
    createOnlineTest();
  }
}

void createOnlineTest() {
  // The ??= operator ensures that flutter will only assign the new value if onlineTest
  // is null. This saves me doing a manual check with an if statement.
  onlineTest ??= Timer.periodic(
    // Every 10 seconds, send a request to check if we are online.
    const Duration(seconds: 10),
    (timer) {
      processNetworkRequest(
        NetworkOperation(
          '$apiUrl/onlineCheck',
          'GET',
          (_) {},
        ),
      ).then(
        (http.Response resp) {
          if (!validateResponse(resp)) return;
          // If the server responds, then we are online and everything is good.
          onlineMode = true;
          int delay = 0;
          while (pendingRequests.isNotEmpty) {
            NetworkOperation request = pendingRequests.removeFirst();
            // We must rate-limit ourselves since the server has just started back up,
            // it will be under quite a lot of load from other users and we don't want
            // to overload it.
            // This queues up all of the requests for once every 250ms (4 per second).

            // This also ensures that all of the requests are processed in the correct order.
            // While using the callbacks will sometimes produce errors, such as if setState
            // is called in the callback (due to the widget changing since
            // the callback was registered), these are not fatal and must all still be
            // executed as there will be important processes going on in the callbacks
            // that should not be missed.

            // Essentially, we are calling all callbacks, even at risk of causing some
            // errors (which we can ignore due to them not being fatal), as the
            // callbacks could contain important stuff and we don't know until we try.
            Future.delayed(
              Duration(milliseconds: delay),
              () => processNetworkRequest(request).then(
                (value) => request.callback(value),
              ),
            );
            delay += 250;
          }
          addNotif('Back online!', error: false);
          // Cancel this timer so that it doesnt keep checking for online status.
          timer.cancel();
          // Also reset onlineTest back so that any new requests will go through normally.
          onlineTest = null;
          // Since we just sent many requests, the callbacks will most likely create many
          // popups at the bottom of the screen and therefore we should clear all
          // of them so they don't spam the user for ages.
          Future.delayed(
            // Do this 1 second after the last request was sent, hopefully all
            // of them have been completed by that point.
            Duration(milliseconds: delay + 1000),
            () => ScaffoldMessenger.of(
              currentScaffoldKey.currentContext!,
            ).clearSnackBars(),
          );
        },
      );
    },
  );
}

bool validateResponse(http.Response response) {
  // If the status code is not OK
  if (response.statusCode != 200) {
    if (response.statusCode == 500) {
      // If it's 500, the server didn't get a chance to return a proper error message.
      addNotif('Internal Server Error');
      return false;
    }
    if (response.statusCode > 900) {
      // HTTP doesn't use status codes over 900, so they are used internally to
      // communicate custom errors.
      return false;
    }
    addNotif('An unknown network error has occurred: ${response.body}');
    return false;
  }
  Map<String, dynamic> data = json.decode(response.body);
  if (data['status'] != 'success') {
    // If it wasn't successful then the server will have returned the reason why
    // in the JSON so we display that to the user.
    addNotif('A network error has occurred: ${data['message']}');
    return false;
  }
  return true;
}

Future<http.Response> processNetworkRequest(NetworkOperation task) async {
  http.Response? response;
  switch (task.method) {
    // This switch statement converts the text method into the HTTP function.
    case 'GET':
      response = await performRequest(
        http.get,
        task.url,
        null,
      );
      break;
    case 'POST':
      response = await performRequest(
        http.post,
        task.url,
        task.data,
      );
      break;
    case 'DELETE':
      response = await performRequest(
        http.delete,
        task.url,
        task.data,
      );
      break;
    case 'PUT':
      response = await performRequest(
        http.put,
        task.url,
        task.data,
      );
      break;
    case 'PATCH':
      response = await performRequest(
        http.patch,
        task.url,
        task.data,
      );
      break;
    default:
      // If we don't know what the method is, just throw an Exception to exit.
      throw Exception('Unknown method type: ${task.method}');
  }
  return response;
}

Future<http.Response> performRequest(
  Function method,
  String url,
  Map<String, dynamic>? body,
) async {
  if (token.isEmpty) {
    // Status code 998 is used to show that the token is empty.
    return http.Response('', 998);
  }
  if (body != null) {
    return await method(
      Uri.parse(url),
      body: body,
      headers: {'Authorization': token},
    ).catchError(
      (error, stackTrace) {
        log('Network Request Failed.\nRequest Body: $body',
            stackTrace: stackTrace, error: error);
        return handleNetworkError(error, url);
      },
    );
  }
  return await method(
    Uri.parse(url),
    headers: {'Authorization': token},
  ).catchError(
    (error, stackTrace) {
      log('Network Request Failed.\nRequest Body: null',
          stackTrace: stackTrace, error: error);
      return handleNetworkError(error, url);
    },
  );
}

http.Response handleNetworkError(dynamic error, String url) {
  if (url != '$apiUrl/onlineCheck') {
    ScaffoldMessenger.of(
      currentScaffoldKey.currentContext!,
    ).clearSnackBars();
    // This message is too long to show in one notification, so just display it
    // in two.
    addNotif(
      'Connection Error. Running in offline mode.',
    );
    addNotif(
      'If you close the app before we are back online, data will be lost.',
    );
    onlineMode = false;
  }
  // Status code 999 is used to show that there was an error connecting to the server.
  return http.Response(error.toString(), 999);
}
