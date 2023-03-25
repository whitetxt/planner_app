import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'globals.dart';

final FlutterLocalNotificationsPlugin notifPlugin =
    FlutterLocalNotificationsPlugin();

final StreamController<ReceivedNotification> notifStream =
    StreamController<ReceivedNotification>.broadcast();

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

String? selectedNotifPayload;

Future<void> setupNotifications() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows) return;

  if (!(kIsWeb || Platform.isLinux)) {
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
  }

  final NotificationAppLaunchDetails? notifLaunchDetails =
      !kIsWeb && Platform.isLinux
          ? null
          : await notifPlugin.getNotificationAppLaunchDetails();
  if (notifLaunchDetails?.didNotificationLaunchApp ?? false) {
    selectedNotifPayload = notifLaunchDetails!.notificationResponse?.payload;
  }

  const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('app_icon');

  LinuxInitializationSettings linuxInit = LinuxInitializationSettings(
    defaultActionName: 'Open notification',
    defaultIcon: AssetsLinuxIcon('icons/app_icon.png'),
  );

  InitializationSettings initSettings = InitializationSettings(
    android: androidInit,
    linux: linuxInit,
  );

  await notifPlugin.initialize(
    // Initialise the notification package
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      if (response.payload == null) return;
      if (response.payload!.startsWith('TABIDX')) {
        int tabIndex = int.parse(
          response.payload!.replaceAll('TABIDX', ''),
        );
        initialTabIndex = tabIndex;
      }
    },
  );

  if (!kIsWeb && Platform.isAndroid) {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        notifPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    // Request permission to send notifications from the user.
    final bool? granted = await androidImplementation?.requestPermission();
    notificationsEnabled = granted ?? false;
  }

  notifStream.stream.listen((ReceivedNotification receivedNotification) async {
    String? payload = receivedNotification.payload;
    if (payload == null) {
      return;
    }
    if (int.tryParse(payload) == null) {
      addToast('Invalid notification payload recieved: $payload');
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

  AndroidNotificationDetails androidNotifDetails = AndroidNotificationDetails(
    'org.duckdns.evieuwo.planAway',
    'PlanAway',
    channelDescription: 'Notifications for PlanAway',
    importance: importance,
    priority: priority,
    ticker: 'PlanAway Notification',
  );
  NotificationDetails notificationDetails =
      NotificationDetails(android: androidNotifDetails);

  await notifPlugin.show(
    // Show the notification now
    // Increment the last notification id AFTER we use it.
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

  // Schedule the notification for the future
  await notifPlugin.zonedSchedule(
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
