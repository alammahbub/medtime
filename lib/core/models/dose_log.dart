class DoseLog {
  final String id;
  final String medicationId;
  final String scheduleId;
  final String scheduledTime;
  final String? actionTime;
  final String status; // pending, taken, skipped, missed
  final String? notes;
  final String createdAt;

  DoseLog({
    required this.id,
    required this.medicationId,
    required this.scheduleId,
    required this.scheduledTime,
    this.actionTime,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  factory DoseLog.fromMap(Map<String, dynamic> map) => DoseLog(
        id: map['id'],
        medicationId: map['medication_id'],
        scheduleId: map['schedule_id'],
        scheduledTime: map['scheduled_time'],
        actionTime: map['action_time'],
        status: map['status'],
        notes: map['notes'],
        createdAt: map['created_at'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'medication_id': medicationId,
        'schedule_id': scheduleId,
        'scheduled_time': scheduledTime,
        'action_time': actionTime,
        'status': status,
        'notes': notes,
        'created_at': createdAt,
      };
}
