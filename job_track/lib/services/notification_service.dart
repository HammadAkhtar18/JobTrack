import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:job_track/models/job_application.dart';
import 'package:shared_preferences/shared_preferences.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService.instance;
});

class NotificationService {
  NotificationService._({
    FlutterLocalNotificationsPlugin? notifications,
    Future<SharedPreferences> Function()? sharedPreferencesProvider,
  })  : _notifications = notifications ?? FlutterLocalNotificationsPlugin(),
        _sharedPreferencesProvider =
            sharedPreferencesProvider ?? SharedPreferences.getInstance;

  static final NotificationService instance = NotificationService._();

  @visibleForTesting
  factory NotificationService.test({
    FlutterLocalNotificationsPlugin? notifications,
    Future<SharedPreferences> Function()? sharedPreferencesProvider,
  }) {
    return NotificationService._(
      notifications: notifications,
      sharedPreferencesProvider: sharedPreferencesProvider,
    );
  }

  final FlutterLocalNotificationsPlugin _notifications;
  final Future<SharedPreferences> Function() _sharedPreferencesProvider;
  bool _initialized = false;
  static const String _notificationIdMapKey = 'notification_id_map';
  static const String _nextNotificationIdKey = 'next_notification_id';

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

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
    _initialized = true;
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

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    var androidScheduleMode = AndroidScheduleMode.inexact;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final canScheduleExact =
          await androidPlugin?.canScheduleExactNotifications() ?? false;
      if (canScheduleExact) {
        androidScheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
      } else {
        debugPrint(
          'Exact alarms are not permitted. Falling back to inexact schedule mode.',
        );
      }
    }

    await _notifications.schedule(
      notificationId,
      'Follow up with ${app.companyName}',
      "Don't forget to follow up on your ${app.jobTitle} application",
      scheduledAt,
      notificationDetails,
      androidScheduleMode: androidScheduleMode,
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
    final prefs = await _sharedPreferencesProvider();
    final notificationIdMap = _readNotificationIdMap(prefs);
    return notificationIdMap[applicationId];
  }

  Future<int> _getOrCreateNotificationId(String applicationId) async {
    final prefs = await _sharedPreferencesProvider();
    final map = _readNotificationIdMap(prefs);

    final existingId = map[applicationId];
    if (existingId != null) {
      return existingId;
    }

    final nextId = prefs.getInt(_nextNotificationIdKey) ?? 1;
    map[applicationId] = nextId;

    await _writeNotificationIdMap(prefs, map);
    await prefs.setInt(_nextNotificationIdKey, nextId + 1);

    return nextId;
  }

  Map<String, int> _readNotificationIdMap(SharedPreferences prefs) {
    final encodedMap = prefs.getString(_notificationIdMapKey);
    if (encodedMap == null || encodedMap.isEmpty) {
      return <String, int>{};
    }

    try {
      final decoded = jsonDecode(encodedMap);
      if (decoded is! Map<String, dynamic>) {
        return <String, int>{};
      }

      final map = <String, int>{};
      decoded.forEach((key, value) {
        if (value is int) {
          map[key] = value;
          return;
        }
        if (value is String) {
          final parsedValue = int.tryParse(value);
          if (parsedValue != null) {
            map[key] = parsedValue;
          }
        }
      });
      return map;
    } catch (_) {
      return <String, int>{};
    }
  }

  Future<void> _writeNotificationIdMap(
    SharedPreferences prefs,
    Map<String, int> map,
  ) {
    return prefs.setString(_notificationIdMapKey, jsonEncode(map));
  }

  @visibleForTesting
  Future<int> getOrCreateNotificationIdForTest(String applicationId) {
    return _getOrCreateNotificationId(applicationId);
  }

  @visibleForTesting
  Future<void> requestPermissionsForTest() {
    return _requestPermissions();
  }
}
