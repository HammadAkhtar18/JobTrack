import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_track/services/notification_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockNotificationsPlugin extends Mock implements FlutterLocalNotificationsPlugin {}

class MockAndroidNotificationsPlugin extends Mock
    implements AndroidFlutterLocalNotificationsPlugin {}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('generates stable notification IDs per application', () async {
    final service = NotificationService.test();

    final first = await service.getOrCreateNotificationIdForTest('app-1');
    final second = await service.getOrCreateNotificationIdForTest('app-1');
    final third = await service.getOrCreateNotificationIdForTest('app-2');

    expect(first, equals(1));
    expect(second, equals(1));
    expect(third, equals(2));
  });

  test('permission denial path completes without throwing on Android', () async {
    final notifications = MockNotificationsPlugin();
    final androidPlugin = MockAndroidNotificationsPlugin();

    when(
      () => notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>(),
    ).thenReturn(androidPlugin);
    when(
      () => notifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>(),
    ).thenReturn(null);
    when(
      () => notifications
          .resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>(),
    ).thenReturn(null);
    when(() => androidPlugin.requestNotificationsPermission()).thenAnswer((_) async => false);

    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    final service = NotificationService.test(notifications: notifications);

    await expectLater(service.requestPermissionsForTest(), completes);
    verify(() => androidPlugin.requestNotificationsPermission()).called(1);
  });
}
