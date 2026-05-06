class MedSchedule {
  final String id;
  final String medicationId;
  final String timeOfDay; // HH:mm
  final String label;
  final bool isActive;
  final String daysOfWeek; // "1,2,3,4,5,6,7"
  final int notifyBeforeMinutes;
  final String createdAt;

  MedSchedule({
    required this.id,
    required this.medicationId,
    required this.timeOfDay,
    required this.label,
    required this.isActive,
    required this.daysOfWeek,
    required this.notifyBeforeMinutes,
    required this.createdAt,
  });

  factory MedSchedule.fromMap(Map<String, dynamic> map) => MedSchedule(
        id: map['id'],
        medicationId: map['medication_id'],
        timeOfDay: map['time_of_day'],
        label: map['label'],
        isActive: map['is_active'] == 1,
        daysOfWeek: map['days_of_week'] ?? '1,2,3,4,5,6,7',
        notifyBeforeMinutes: map['notify_before_minutes'] ?? 10,
        createdAt: map['created_at'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'medication_id': medicationId,
        'time_of_day': timeOfDay,
        'label': label,
        'is_active': isActive ? 1 : 0,
        'days_of_week': daysOfWeek,
        'notify_before_minutes': notifyBeforeMinutes,
        'created_at': createdAt,
      };

  List<int> get activeDays =>
      daysOfWeek.split(',').map(int.parse).toList();

  DateTime nextOccurrence({DateTime? from}) {
    final now = from ?? DateTime.now();
    final parts = timeOfDay.split(':');
    final h = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    var candidate = DateTime(now.year, now.month, now.day, h, m);
    for (var i = 0; i < 8; i++) {
      final d = candidate.add(Duration(days: i));
      final wd = d.weekday; // 1=Mon..7=Sun
      if (activeDays.contains(wd) && d.isAfter(now)) return d;
    }
    return candidate.add(const Duration(days: 1));
  }

  MedSchedule copyWith({
    String? id,
    String? medicationId,
    String? timeOfDay,
    String? label,
    bool? isActive,
    String? daysOfWeek,
    int? notifyBeforeMinutes,
    String? createdAt,
    String? updatedAt,
  }) =>
      MedSchedule(
        id: id ?? this.id,
        medicationId: medicationId ?? this.medicationId,
        timeOfDay: timeOfDay ?? this.timeOfDay,
        label: label ?? this.label,
        isActive: isActive ?? this.isActive,
        daysOfWeek: daysOfWeek ?? this.daysOfWeek,
        notifyBeforeMinutes: notifyBeforeMinutes ?? this.notifyBeforeMinutes,
        createdAt: createdAt ?? this.createdAt,
      );
}
