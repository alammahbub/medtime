import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/schedule.dart';
import '../models/medication.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'medtime_reminder';
  static const _channelName = 'Medication Reminders';

  Future<void> initialize() async {
    try {
      tz_data.initializeTimeZones();
      final String timeZoneName =
          (await FlutterTimezone.getLocalTimezone()).identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      await _plugin.initialize(
        const InitializationSettings(android: android, iOS: ios),
        onDidReceiveNotificationResponse: _onNotificationResponse,
        onDidReceiveBackgroundNotificationResponse: _backgroundHandler,
      );
    } catch (e) {
      debugPrint('NotificationService: Failed to initialize: $e');
    }
  }

  Future<bool> requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final plugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      // 1. Request POST_NOTIFICATIONS (Android 13+)
      final status = await Permission.notification.request();

      // 2. Request Exact Alarms (Android 12+)
      // This is critical for release mode
      final alarmStatus = await Permission.scheduleExactAlarm.request();

      return status.isGranted && alarmStatus.isGranted;
    }
    return true;
  }

  @pragma('vm:entry-point')
  static void _backgroundHandler(NotificationResponse resp) {
    _handleAction(resp.actionId, resp.payload);
  }

  static void _onNotificationResponse(NotificationResponse resp) {
    _handleAction(resp.actionId, resp.payload);
  }

  static void _handleAction(String? actionId, String? payload) {
    // Handled via MedicationProvider via shared_preferences flag
    if (payload == null) return;
    final parts = payload.split('|');
    if (parts.length < 2) return;
    // Store pending action for provider to pick up on next launch
  }

  AndroidNotificationDetails _androidDetails() => AndroidNotificationDetails(
    _channelId,
    _channelName,
    channelDescription: 'Alerts you before it is time to take your medication',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
    actions: [
      const AndroidNotificationAction(
        'taken',
        '✅  Taken',
        showsUserInterface: true,
      ),
      const AndroidNotificationAction(
        'skipped',
        '⏭️  Skip',
        showsUserInterface: true,
      ),
    ],
  );

  Future<void> scheduleDoseNotification({
    required MedSchedule schedule,
    required Medication medication,
    required DateTime scheduledDoseTime,
  }) async {
    final notifyAt = scheduledDoseTime.subtract(
      Duration(minutes: schedule.notifyBeforeMinutes),
    );
    if (notifyAt.isBefore(DateTime.now())) return;

    final id = _notifId(schedule.id, scheduledDoseTime);
    final tzTime = tz.TZDateTime.from(notifyAt, tz.local);

    try {
      await _plugin.zonedSchedule(
        id,
        '💊 Time for ${medication.name}',
        '${medication.dosageAmount} ${medication.dosageUnit} — due in ${schedule.notifyBeforeMinutes} min',
        tzTime,
        NotificationDetails(android: _androidDetails()),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload:
            '${schedule.id}|${medication.id}|${scheduledDoseTime.toIso8601String()}',
      );
    } catch (e) {
      debugPrint('NotificationService: Failed to schedule: $e');
      // Rethrow to allow the UI to handle it
      throw Exception(
        'Notification scheduling failed. Please ensure "Exact Alarm" permissions are granted in settings. ($e)',
      );
    }
  }

  Future<void> cancelNotificationsForMedication(String medicationId) async {
    // Cancel all — simplest safe approach; reschedule will re-add valid ones
    await _plugin.cancelAll();
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  int _notifId(String scheduleId, DateTime dt) {
    return (scheduleId + dt.toIso8601String()).hashCode.abs() % 2147483647;
  }
}
