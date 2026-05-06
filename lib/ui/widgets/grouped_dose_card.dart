import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/medication_provider.dart';
import '../../ui/theme/app_theme.dart';

class GroupedDoseCard extends StatelessWidget {
  final String label;
  final String time;
  final List<Map<String, dynamic>> doses;
  final bool urgent;

  const GroupedDoseCard({
    super.key,
    required this.label,
    required this.time,
    required this.doses,
    this.urgent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: urgent ? AppTheme.accent : Colors.grey.shade200,
          width: urgent ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _getIconForLabel(label),
                      color: urgent ? AppTheme.accent : AppTheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: urgent ? AppTheme.accent : AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            ...doses.map((dose) => _buildDoseRow(context, dose)),
          ],
        ),
      ),
    );
  }

  Widget _buildDoseRow(BuildContext context, Map<String, dynamic> dose) {
    final medColor = AppTheme.colorFromHex(dose['color_hex'] ?? '#1A8FE3');
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _buildTinyImage(dose['image_path'], medColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dose['med_name'] ?? 'Medication',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  '${dose['dosage_amount']} ${dose['dosage_unit']}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          _ActionIcon(
            icon: Icons.check_circle_rounded,
            color: AppTheme.success,
            onTap: () => context.read<MedicationProvider>().markDose(dose['id'], 'taken'),
          ),
          const SizedBox(width: 8),
          _ActionIcon(
            icon: Icons.skip_next_rounded,
            color: AppTheme.textSecondary.withValues(alpha: 0.5),
            onTap: () => context.read<MedicationProvider>().markDose(dose['id'], 'skipped'),
          ),
        ],
      ),
    );
  }

  Widget _buildTinyImage(String? path, Color color) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: path != null && File(path).existsSync()
          ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(File(path), fit: BoxFit.cover),
            )
          : Icon(Icons.medication_rounded, color: color, size: 18),
    );
  }

  IconData _getIconForLabel(String label) {
    if (label.contains('Breakfast')) return Icons.wb_twilight;
    if (label.contains('Lunch')) return Icons.wb_sunny_rounded;
    if (label.contains('Dinner')) return Icons.restaurant_rounded;
    if (label.contains('Bed')) return Icons.bedtime_rounded;
    return Icons.access_time_filled_rounded;
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionIcon({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: color, size: 26),
      ),
    );
  }
}
