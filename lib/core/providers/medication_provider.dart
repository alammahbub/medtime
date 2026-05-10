import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/settings_service.dart';
import '../database/database_helper.dart';
import '../models/medication.dart';
import '../models/schedule.dart';
import '../models/dose_log.dart';
import '../services/notification_service.dart';

class MedicationProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;
  final _ns = NotificationService.instance;
  final _uuid = const Uuid();

  List<Medication> _medications = [];
  Map<String, List<MedSchedule>> _schedules = {};
  List<Map<String, dynamic>> _todayDoses = [];
  bool _loading = false;

  List<Medication> get medications => _medications;
  Map<String, List<MedSchedule>> get allSchedules => _schedules;
  List<Map<String, dynamic>> get todayDoses => _todayDoses;
  bool get loading => _loading;

  List<Medication> get activeMedications =>
      _medications.where((m) => m.isActive).toList();

  Future<void> loadAll() async {
    _loading = true;
    notifyListeners();
    try {
      final maps = await _db.getMedications();
      _medications = maps.map(Medication.fromMap).toList();
      
      _schedules = {};
      for (final med in _medications) {
        final smaps = await _db.getSchedules(med.id);
        _schedules[med.id] = smaps.map(MedSchedule.fromMap).toList();
      }

      await _generateTodayLogs();
      await _loadTodayDoses();
    } catch (e) {
      debugPrint('Error loading medications: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> addMedication(Medication med, List<MedSchedule> schedules) async {
    await _db.insertMedication(med.toMap());
    for (final s in schedules) {
      await _db.insertSchedule(s.toMap());
    }
    await loadAll();
    await _rescheduleAll();
  }

  Future<void> updateMedication(Medication med, List<MedSchedule> schedules) async {
    await _db.updateMedication(med.toMap());
    await _db.deleteSchedulesForMedication(med.id);
    for (final s in schedules) {
      await _db.insertSchedule(s.toMap());
    }
    await loadAll();
    await _rescheduleAll();
  }

  Future<void> deleteMedication(String id) async {
    await _db.deleteMedication(id);
    await _ns.cancelNotificationsForMedication(id);
    await loadAll();
    await _rescheduleAll();
  }

  Future<void> toggleActive(String id) async {
    final med = _medications.firstWhere((m) => m.id == id);
    await _db.updateMedication(
      med.copyWith(isActive: !med.isActive, updatedAt: DateTime.now().toIso8601String()).toMap(),
    );
    await loadAll();
    await _rescheduleAll();
  }

  Future<void> markDose(String logId, String status) async {
    await _db.updateDoseLog(logId, status, DateTime.now().toIso8601String());
    await _loadTodayDoses();
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getLogsForDate(DateTime date) =>
      _db.getLogsForDate(date);

  Future<Map<String, dynamic>> getAdherenceStats(String medicationId) =>
      _db.getAdherenceStats(medicationId);

  Future<List<MedSchedule>> getSchedules(String medicationId) async {
    final maps = await _db.getSchedules(medicationId);
    return maps.map(MedSchedule.fromMap).toList();
  }

  Future<bool> requestNotificationPermissions() => _ns.requestPermissions();

  Future<void> recalculateMealSchedules() async {
    _loading = true;
    notifyListeners();
    try {
      final mealTimes = await SettingsService.instance.getMealTimes();
      final allSchedules = await _db.getAllActiveSchedules();
      final now = DateTime.now().toIso8601String();

      for (final sm in allSchedules) {
        final s = MedSchedule.fromMap(sm);
        final label = s.label;
        
        TimeOfDay? baseTime;
        int offset = 0;

        if (label.contains('Breakfast')) {
          baseTime = mealTimes['Breakfast']!;
          offset = label.startsWith('Before') ? -30 : 30;
        } else if (label.contains('Lunch')) {
          baseTime = mealTimes['Lunch']!;
          offset = label.startsWith('Before') ? -30 : 30;
        } else if (label.contains('Dinner')) {
          baseTime = mealTimes['Dinner']!;
          offset = label.startsWith('Before') ? -30 : 30;
        }

        if (baseTime != null) {
          final totalMinutes = baseTime.hour * 60 + baseTime.minute + offset;
          final finalTime = TimeOfDay(hour: (totalMinutes ~/ 60) % 24, minute: totalMinutes % 60);
          final timeStr = '${finalTime.hour.toString().padLeft(2, '0')}:${finalTime.minute.toString().padLeft(2, '0')}';
          
          if (timeStr != s.timeOfDay) {
            await _db.updateSchedule(s.copyWith(timeOfDay: timeStr, updatedAt: now).toMap());
            
            // NEW: Update today's pending logs for this schedule
            final todayStr = DateTime.now().toIso8601String().substring(0, 10);
            final parts = timeStr.split(':');
            final newDoseTime = DateTime(
              DateTime.now().year, DateTime.now().month, DateTime.now().day,
              int.parse(parts[0]), int.parse(parts[1]),
            );
            await _db.updatePendingDoseTime(s.id, todayStr, newDoseTime.toIso8601String());
          }
        }
      }
      await loadAll();
      await _rescheduleAll();
    } catch (e) {
      debugPrint('Error recalculating schedules: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> clearAll() async {
    await _db.clearAllData();
    await _ns.cancelAll();
    await loadAll();
  }

  // ── Private ───────────────────────────────────────────────
  Future<void> _loadTodayDoses() async {
    _todayDoses = await _db.getTodayPendingDoses();
    // Auto-miss overdue pending doses (>1hr past)
    final now = DateTime.now();
    for (final d in _todayDoses) {
      if (d['status'] == 'pending') {
        final scheduled = DateTime.parse(d['scheduled_time']);
        if (now.difference(scheduled).inMinutes > 60) {
          await _db.updateDoseLog(d['id'], 'missed', null);
        }
      }
    }
    _todayDoses = await _db.getTodayPendingDoses();
  }

  Future<void> _generateTodayLogs() async {
    final allScheduleMaps = await _db.getAllActiveSchedules();
    final today = DateTime.now();
    final todayStr = today.toIso8601String().substring(0, 10);
    final todayWeekday = today.weekday;

    for (final sm in allScheduleMaps) {
      final s = MedSchedule.fromMap(sm);
      if (!s.activeDays.contains(todayWeekday)) continue;
      final exists = await _db.doseLogExists(s.id, todayStr);
      if (!exists) {
        final parts = s.timeOfDay.split(':');
        final doseTime = DateTime(
          today.year, today.month, today.day,
          int.parse(parts[0]), int.parse(parts[1]),
        );
        await _db.insertDoseLog(DoseLog(
          id: _uuid.v4(),
          medicationId: s.medicationId,
          scheduleId: s.id,
          scheduledTime: doseTime.toIso8601String(),
          status: 'pending',
          createdAt: DateTime.now().toIso8601String(),
        ).toMap());
      }
    }
  }

  Future<void> _rescheduleAll() async {
    await _ns.cancelAll();
    final scheduleMaps = await _db.getAllActiveSchedules();
    final now = DateTime.now();
    for (final sm in scheduleMaps) {
      final s = MedSchedule.fromMap(sm);
      final med = _medications.firstWhereOrNull((m) => m.id == s.medicationId);
      if (med == null) continue;
      // Schedule next 7 days
      for (var i = 0; i < 7; i++) {
        final day = now.add(Duration(days: i));
        if (!s.activeDays.contains(day.weekday)) continue;
        final parts = s.timeOfDay.split(':');
        final doseTime = DateTime(
          day.year, day.month, day.day,
          int.parse(parts[0]), int.parse(parts[1]),
        );
        await _ns.scheduleDoseNotification(
          schedule: s,
          medication: med,
          scheduledDoseTime: doseTime,
        );
      }
    }
  }
}

extension ListExt<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) { if (test(e)) return e; }
    return null;
  }
}
