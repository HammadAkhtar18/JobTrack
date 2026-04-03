import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:job_track/models/job_application.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
    await _requestPermissions();
  }

  Future<void> scheduleFollowUpReminder(JobApplication app) async {
    final followUpDate = app.followUpDate;
    if (followUpDate == null) {
      return;
    }

    final scheduledAt = DateTime(
      followUpDate.year,
      followUpDate.month,
      followUpDate.day,
      9,
    );

    if (scheduledAt.isBefore(DateTime.now())) {
      return;
    }

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'follow_up_reminders',
        'Follow-up reminders',
        channelDescription: 'Reminders for job application follow ups',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _notifications.schedule(
      _notificationIdFor(app.id),
      'Follow up with ${app.companyName}',
      "Don't forget to follow up on your ${app.jobTitle} application",
      scheduledAt,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelReminder(String id) async {
    await _notifications.cancel(_notificationIdFor(id));
  }

  Future<void> _requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await _notifications
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    if (Platform.isAndroid) {
      await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }
  }

  int _notificationIdFor(String id) {
    return id.hashCode & 0x7fffffff;
  }
}
