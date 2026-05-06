// Core models
class Medication {
  final String id;
  final String name;
  final String? description;
  final String? imagePath;
  final String colorHex;
  final String dosageAmount;
  final String dosageUnit;
  final String? instructions;
  final String startDate;
  final String? endDate;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  Medication({
    required this.id,
    required this.name,
    this.description,
    this.imagePath,
    required this.colorHex,
    required this.dosageAmount,
    required this.dosageUnit,
    this.instructions,
    required this.startDate,
    this.endDate,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Medication.fromMap(Map<String, dynamic> map) => Medication(
        id: map['id'],
        name: map['name'],
        description: map['description'],
        imagePath: map['image_path'],
        colorHex: map['color_hex'] ?? '#1A8FE3',
        dosageAmount: map['dosage_amount'],
        dosageUnit: map['dosage_unit'] ?? 'tablet(s)',
        instructions: map['instructions'],
        startDate: map['start_date'],
        endDate: map['end_date'],
        isActive: map['is_active'] == 1,
        createdAt: map['created_at'],
        updatedAt: map['updated_at'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'image_path': imagePath,
        'color_hex': colorHex,
        'dosage_amount': dosageAmount,
        'dosage_unit': dosageUnit,
        'instructions': instructions,
        'start_date': startDate,
        'end_date': endDate,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  Medication copyWith({
    String? name,
    String? description,
    String? imagePath,
    String? colorHex,
    String? dosageAmount,
    String? dosageUnit,
    String? instructions,
    String? startDate,
    String? endDate,
    bool? isActive,
    String? updatedAt,
  }) =>
      Medication(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        imagePath: imagePath ?? this.imagePath,
        colorHex: colorHex ?? this.colorHex,
        dosageAmount: dosageAmount ?? this.dosageAmount,
        dosageUnit: dosageUnit ?? this.dosageUnit,
        instructions: instructions ?? this.instructions,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
