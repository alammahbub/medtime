import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _db;
  DatabaseHelper._();

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'medtime.db');
    return openDatabase(
      path,
      version: 1,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE medications (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        image_path TEXT,
        color_hex TEXT NOT NULL DEFAULT "#1A8FE3",
        dosage_amount TEXT NOT NULL,
        dosage_unit TEXT NOT NULL DEFAULT "tablet(s)",
        instructions TEXT,
        start_date TEXT NOT NULL,
        end_date TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE schedules (
        id TEXT PRIMARY KEY,
        medication_id TEXT NOT NULL,
        time_of_day TEXT NOT NULL,
        label TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        days_of_week TEXT NOT NULL DEFAULT "1,2,3,4,5,6,7",
        notify_before_minutes INTEGER NOT NULL DEFAULT 10,
        created_at TEXT NOT NULL,
        FOREIGN KEY (medication_id) REFERENCES medications(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE dose_logs (
        id TEXT PRIMARY KEY,
        medication_id TEXT NOT NULL,
        schedule_id TEXT NOT NULL,
        scheduled_time TEXT NOT NULL,
        action_time TEXT,
        status TEXT NOT NULL DEFAULT "pending",
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (medication_id) REFERENCES medications(id) ON DELETE CASCADE,
        FOREIGN KEY (schedule_id) REFERENCES schedules(id) ON DELETE CASCADE
      )
    ''');
  }

  // ── Medications ──────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getMedications() async {
    final db = await database;
    return db.query('medications', orderBy: 'created_at DESC');
  }

  Future<int> insertMedication(Map<String, dynamic> data) async {
    final db = await database;
    return db.insert('medications', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateMedication(Map<String, dynamic> data) async {
    final db = await database;
    return db.update('medications', data, where: 'id = ?', whereArgs: [data['id']]);
  }

  Future<int> deleteMedication(String id) async {
    final db = await database;
    return db.delete('medications', where: 'id = ?', whereArgs: [id]);
  }

  // ── Schedules ─────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getSchedules(String medicationId) async {
    final db = await database;
    return db.query('schedules', where: 'medication_id = ?', whereArgs: [medicationId]);
  }

  Future<List<Map<String, dynamic>>> getAllActiveSchedules() async {
    final db = await database;
    return db.rawQuery('''
      SELECT s.*, m.name as med_name, m.color_hex, m.dosage_amount, m.dosage_unit
      FROM schedules s
      JOIN medications m ON s.medication_id = m.id
      WHERE s.is_active = 1 AND m.is_active = 1
    ''');
  }

  Future<int> insertSchedule(Map<String, dynamic> data) async {
    final db = await database;
    return db.insert('schedules', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> deleteSchedule(String id) async {
    final db = await database;
    return db.delete('schedules', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteSchedulesForMedication(String medicationId) async {
    final db = await database;
    await db.delete('schedules', where: 'medication_id = ?', whereArgs: [medicationId]);
  }

  Future<int> updateSchedule(Map<String, dynamic> data) async {
    final db = await database;
    return db.update('schedules', data, where: 'id = ?', whereArgs: [data['id']]);
  }

  // ── Dose Logs ─────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getLogsForDate(DateTime date) async {
    final db = await database;
    final dateStr = date.toIso8601String().substring(0, 10);
    return db.rawQuery('''
      SELECT dl.*, m.name as med_name, m.color_hex, m.image_path, m.dosage_amount, m.dosage_unit, s.label as schedule_label
      FROM dose_logs dl
      JOIN medications m ON dl.medication_id = m.id
      LEFT JOIN schedules s ON dl.schedule_id = s.id
      WHERE dl.scheduled_time LIKE ?
      ORDER BY dl.scheduled_time ASC
    ''', ['$dateStr%']);
  }

  Future<int> updatePendingDoseTime(String scheduleId, String dateStr, String newTime) async {
    final db = await database;
    return db.update(
      'dose_logs',
      {'scheduled_time': newTime},
      where: 'schedule_id = ? AND status = "pending" AND scheduled_time LIKE ?',
      whereArgs: [scheduleId, '$dateStr%'],
    );
  }

  Future<List<Map<String, dynamic>>> getTodayPendingDoses() async {
    return getLogsForDate(DateTime.now());
  }

  Future<int> insertDoseLog(Map<String, dynamic> data) async {
    final db = await database;
    return db.insert('dose_logs', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateDoseLog(String id, String status, String? actionTime) async {
    final db = await database;
    return db.update(
      'dose_logs',
      {'status': status, 'action_time': actionTime},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<bool> doseLogExists(String scheduleId, String dateStr) async {
    final db = await database;
    final res = await db.query(
      'dose_logs',
      where: 'schedule_id = ? AND scheduled_time LIKE ?',
      whereArgs: [scheduleId, '$dateStr%'],
    );
    return res.isNotEmpty;
  }

  Future<Map<String, dynamic>> getAdherenceStats(String medicationId) async {
    final db = await database;
    final total = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM dose_logs WHERE medication_id = ?', [medicationId])) ?? 0;
    final taken = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM dose_logs WHERE medication_id = ? AND status = "taken"', [medicationId])) ?? 0;
    return {'total': total, 'taken': taken};
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('dose_logs');
    await db.delete('schedules');
    await db.delete('medications');
  }
}
