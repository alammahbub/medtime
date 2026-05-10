import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/providers/medication_provider.dart';
import '../../../core/services/settings_service.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer<MedicationProvider>(
        builder: (context, prov, _) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const _SectionHeader(title: 'App Settings'),
              _SettingTile(
                icon: Icons.notifications_active_outlined,
                title: 'Reminder Alerts',
                subtitle: 'Remind 10 minutes before each dose',
                trailing: Switch(
                  value: true,
                  onChanged: (v) {},
                  activeColor: AppTheme.primary,
                ),
              ),
              _SettingTile(
                icon: Icons.vibration,
                title: 'Vibration',
                trailing: Switch(
                  value: true,
                  onChanged: (v) {},
                  activeColor: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              const _SectionHeader(title: 'Meal Times'),
              FutureBuilder<Map<String, TimeOfDay>>(
                // Re-fetch when provider notifies
                future: SettingsService.instance.getMealTimes(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();
                  final times = snapshot.data!;
                  return Column(
                    children: times.entries
                        .map(
                          (e) => _SettingTile(
                            icon: Icons.restaurant_menu,
                            title: e.key,
                            subtitle: 'Current: ${e.value.format(context)}',
                            onTap: () async {
                              final t = await showTimePicker(
                                context: context,
                                initialTime: e.value,
                              );
                              if (t != null) {
                                final newTimes = Map<String, TimeOfDay>.from(
                                  times,
                                );
                                newTimes[e.key] = t;
                                await SettingsService.instance.setMealTimes(
                                  breakfast: newTimes['Breakfast']!,
                                  lunch: newTimes['Lunch']!,
                                  dinner: newTimes['Dinner']!,
                                );

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Updating schedules...'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                  await context
                                      .read<MedicationProvider>()
                                      .recalculateMealSchedules();
                                }
                              }
                            },
                          ),
                        )
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 24),
              const _SectionHeader(title: 'Onboarding'),
              _SettingTile(
                icon: Icons.refresh,
                title: 'Reset Onboarding',
                subtitle: 'Re-set meal times and permissions',
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('App reset. Please restart the app.'),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 24),
              const _SectionHeader(title: 'Data Management'),
              _SettingTile(
                icon: Icons.delete_forever_outlined,
                title: 'Clear All Data',
                subtitle: 'Reset app and remove all medications',
                color: AppTheme.error,
                onTap: () => _confirmClear(context),
              ),
              const SizedBox(height: 40),
              Center(
                child: Text(
                  'MedTime v1.0.0\nOffline Mode Enabled',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete all your medications and history. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Clear Everything'),
          ),
        ],
      ),
    );
    if (ok == true) {
      if (!context.mounted) return;
      final prov = context.read<MedicationProvider>();
      await prov.clearAll();
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('All data cleared')));
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: AppTheme.primary,
      ),
    ),
  );
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? color;

  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon, color: color ?? AppTheme.primary, size: 28),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: trailing,
      ),
    );
  }
}
