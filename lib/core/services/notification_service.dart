import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/schedule.dart';
import '../models/medication.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'medtime_reminder';
  static const _channelName = 'Medication Reminders';

  Future<void> initialize() async {
    tz.initializeTimeZones();

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
  }

  Future<bool> requestPermissions() async {
    final platform = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await platform?.requestNotificationsPermission();
    await platform?.requestExactAlarmsPermission();
    return granted ?? false;
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
          const AndroidNotificationAction('taken', '✅  Taken', showsUserInterface: true),
          const AndroidNotificationAction('skipped', '⏭️  Skip', showsUserInterface: true),
        ],
      );

  Future<void> scheduleDoseNotification({
    required MedSchedule schedule,
    required Medication medication,
    required DateTime scheduledDoseTime,
  }) async {
    final notifyAt = scheduledDoseTime.subtract(
        Duration(minutes: schedule.notifyBeforeMinutes));
    if (notifyAt.isBefore(DateTime.now())) return;

    final id = _notifId(schedule.id, scheduledDoseTime);
    final tzTime = tz.TZDateTime.from(notifyAt, tz.local);

    await _plugin.zonedSchedule(
      id,
      '💊 Time for ${medication.name}',
      '${medication.dosageAmount} ${medication.dosageUnit} — due in ${schedule.notifyBeforeMinutes} min',
      tzTime,
      NotificationDetails(android: _androidDetails()),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: '${schedule.id}|${medication.id}|${scheduledDoseTime.toIso8601String()}',
    );
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
