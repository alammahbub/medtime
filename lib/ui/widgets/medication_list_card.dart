import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/models/medication.dart';
import '../../core/models/schedule.dart';
import '../theme/app_theme.dart';

class MedicationListCard extends StatelessWidget {
  final Medication medication;
  final List<MedSchedule> schedules;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const MedicationListCard({
    super.key,
    required this.medication,
    required this.schedules,
    required this.onToggle,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final medColor = AppTheme.colorFromHex(medication.colorHex);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 6), // Reduced margin between items
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), // Tightened padding
          child: Row(
            children: [
              _buildImage(medication.imagePath, medColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: RichText(
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                              children: [
                                TextSpan(text: medication.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                                TextSpan(text: '  •  ${medication.dosageAmount} ${medication.dosageUnit}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Transform.scale(
                          scale: 0.7,
                          child: Switch(
                            value: medication.isActive,
                            onChanged: (_) => onToggle(),
                            activeColor: medColor,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppTheme.error),
                          onPressed: () => _confirmDelete(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    if (schedules.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: schedules.map((s) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: medColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            s.label.contains('|') ? s.label.split('|')[0] : s.label,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: medColor,
                            ),
                          ),
                        )).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Remove "${medication.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      onDelete();
    }
  }

  Widget _buildImage(String? path, Color color) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: path != null && File(path).existsSync()
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(File(path), fit: BoxFit.cover),
            )
          : Icon(Icons.medication_rounded, color: color, size: 22),
    );
  }
}
