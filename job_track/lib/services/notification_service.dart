import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:job_track/models/job_application.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static const String _notificationIdMapKey = 'notification_id_map';
  static const String _nextNotificationIdKey = 'next_notification_id';

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

    final notificationId = await _getOrCreateNotificationId(app.id);

    await _notifications.schedule(
      notificationId,
      'Follow up with ${app.companyName}',
      "Don't forget to follow up on your ${app.jobTitle} application",
      scheduledAt,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelReminder(String id) async {
    final notificationId = await _getNotificationId(id);
    if (notificationId != null) {
      await _notifications.cancel(notificationId);
    }
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

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }
  }

  Future<int?> _getNotificationId(String applicationId) async {
    final prefs = await SharedPreferences.getInstance();
    final notificationIdMap = prefs.getStringList(_notificationIdMapKey) ?? [];

    for (final entry in notificationIdMap) {
      final parts = entry.split(':');
      if (parts.length != 2) {
        continue;
      }
      if (parts[0] == applicationId) {
        return int.tryParse(parts[1]);
      }
    }

    return null;
  }

  Future<int> _getOrCreateNotificationId(String applicationId) async {
    final prefs = await SharedPreferences.getInstance();
    final notificationIdMap = prefs.getStringList(_notificationIdMapKey) ?? [];
    final map = <String, int>{};

    for (final entry in notificationIdMap) {
      final parts = entry.split(':');
      if (parts.length != 2) {
        continue;
      }
      final parsedId = int.tryParse(parts[1]);
      if (parsedId != null) {
        map[parts[0]] = parsedId;
      }
    }

    final existingId = map[applicationId];
    if (existingId != null) {
      return existingId;
    }

    final nextId = prefs.getInt(_nextNotificationIdKey) ?? 1;
    map[applicationId] = nextId;

    final serializedMap = map.entries
        .map((entry) => '${entry.key}:${entry.value}')
        .toList();
    await prefs.setStringList(_notificationIdMapKey, serializedMap);
    await prefs.setInt(_nextNotificationIdKey, nextId + 1);

    return nextId;
  }
}
