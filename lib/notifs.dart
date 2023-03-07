import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'globals.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

final StreamController<ReceivedNotification> didReceiveLocalNotificationStream =
    StreamController<ReceivedNotification>.broadcast();

final StreamController<String?> selectNotificationStream =
    StreamController<String?>.broadcast();

const MethodChannel platform =
    MethodChannel('dexterx.dev/flutter_local_notifications_example');

const String portName = 'notification_send_port';

class ReceivedNotification {
  ReceivedNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
  });

  final int id;
  final String? title;
  final String? body;
  final String? payload;
}

String? selectedNotificationPayload;

/// A notification action which triggers a homework to be completed
const String homeworkCompletion = 'id_1';

/// A notification action which triggers a App navigation event
const String navigationActionId = 'id_3';

Future<void> setupNotifications() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!(kIsWeb || Platform.isLinux)) {
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
  }

  final NotificationAppLaunchDetails? notificationAppLaunchDetails = !kIsWeb &&
          Platform.isLinux
      ? null
      : await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
  if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
    selectedNotificationPayload =
        notificationAppLaunchDetails!.notificationResponse?.payload;
  }

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('app_icon');

  const LinuxInitializationSettings initializationSettingsLinux =
      LinuxInitializationSettings(
    defaultActionName: 'Open notification',
  );

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    linux: initializationSettingsLinux,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse:
        (NotificationResponse notificationResponse) {
      if (notificationResponse.payload == null) return;
      if (notificationResponse.payload!.startsWith('TABIDX')) {
        int tabIndex = int.parse(
          notificationResponse.payload!.replaceAll('TABIDX', ''),
        );
        initialTabIndex = tabIndex;
      }
    },
  );

  if (Platform.isAndroid) {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    final bool? granted = await androidImplementation?.requestPermission();
    notificationsEnabled = granted ?? false;
  }

  didReceiveLocalNotificationStream.stream
      .listen((ReceivedNotification receivedNotification) async {
    String? payload = receivedNotification.payload;
    if (payload == null) {
      return;
    }
    if (int.tryParse(payload) == null) {
      addNotif('Invalid notification payload recieved: $payload');
      return;
    }
    initialTabIndex = int.parse(payload);
  });
}

Future<void> createNotificationNow(String title, String body, String payload,
    {Importance? importance, Priority? priority}) async {
  // If none specified, set to default priority/importance.
  importance ??= Importance.defaultImportance;
  priority ??= Priority.defaultPriority;

  AndroidNotificationDetails androidNotificationDetails =
      AndroidNotificationDetails(
    'org.duckdns.evieuwo.planAway',
    'PlanAway',
    channelDescription: 'Notifications for PlanAway',
    importance: importance,
    priority: priority,
    ticker: 'PlanAway Notification',
  );
  NotificationDetails notificationDetails =
      NotificationDetails(android: androidNotificationDetails);

  await flutterLocalNotificationsPlugin.show(
    lastNotificationID++,
    title,
    body,
    notificationDetails,
    payload: payload,
  );
}

Future<void> createTimedNotification(
    String title, String body, String payload, tz.TZDateTime date,
    {Importance? importance, Priority? priority}) async {
  // If none specified, set to default priority/importance.
  importance ??= Importance.defaultImportance;
  priority ??= Priority.defaultPriority;

  await flutterLocalNotificationsPlugin.zonedSchedule(
    lastNotificationID++,
    title,
    body,
    date,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'org.duckdns.evieuwo.planAway',
        'PlanAway',
        channelDescription: 'Notifications for PlanAway',
      ),
    ),
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    androidAllowWhileIdle: true,
    matchDateTimeComponents: DateTimeComponents.time,
  );
}

Future<void> getPendingNotifications() async {
  await flutterLocalNotificationsPlugin.pendingNotificationRequests();
}
