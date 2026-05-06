import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/providers/medication_provider.dart';
import '../../ui/theme/app_theme.dart';

class DoseCard extends StatelessWidget {
  final Map<String, dynamic> dose;
  final bool urgent;

  const DoseCard({super.key, required this.dose, this.urgent = false});

  @override
  Widget build(BuildContext context) {
    final scheduledTime = DateTime.parse(dose['scheduled_time']);
    final timeStr = DateFormat.jm().format(scheduledTime);
    final medColor = AppTheme.colorFromHex(dose['color_hex'] ?? '#1A8FE3');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: urgent ? BorderSide(color: AppTheme.accent.withValues(alpha: 0.5), width: 2) : BorderSide.none,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border(left: BorderSide(color: medColor, width: 8)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildImage(dose['image_path'], medColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: urgent ? AppTheme.accent : AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      dose['med_name'] ?? 'Medication',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${dose['dosage_amount']} ${dose['dosage_unit']}',
                      style: const TextStyle(fontSize: 15, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  _ActionButton(
                    icon: Icons.check_circle,
                    label: 'Taken',
                    color: AppTheme.success,
                    onTap: () => context.read<MedicationProvider>().markDose(dose['id'], 'taken'),
                  ),
                  const SizedBox(height: 8),
                  _ActionButton(
                    icon: Icons.skip_next,
                    label: 'Skip',
                    color: AppTheme.textSecondary,
                    onTap: () => context.read<MedicationProvider>().markDose(dose['id'], 'skipped'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String? path, Color color) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: path != null && File(path).existsSync()
          ? ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.file(File(path), fit: BoxFit.cover),
            )
          : Icon(Icons.medication, color: color, size: 30),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
