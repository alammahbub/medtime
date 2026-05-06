import 'package:flutter/material.dart';
import 'ui/theme/app_theme.dart';
import 'ui/screens/home/home_screen.dart';
import 'ui/screens/medications/medications_screen.dart';
import 'ui/screens/history/history_screen.dart';
import 'ui/screens/settings/settings_screen.dart';
import 'core/services/settings_service.dart';
import 'core/services/notification_service.dart';

class MedTimeApp extends StatefulWidget {
  const MedTimeApp({super.key});

  @override
  State<MedTimeApp> createState() => _MedTimeAppState();
}

class _MedTimeAppState extends State<MedTimeApp> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const MedicationsScreen(),
    const HistoryScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MedTime',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: Builder(
        builder: (context) {
          // Check meal times within the MaterialApp context
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            final set = await SettingsService.instance.areMealTimesSet();
            if (!set && context.mounted) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) => const MealSetupDialog(),
              );
            }
          });

          return Scaffold(
            body: _screens[_currentIndex],
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_rounded),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.medication_rounded),
                  label: 'Meds',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.history_rounded),
                  label: 'History',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_rounded),
                  label: 'Settings',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class MealSetupDialog extends StatefulWidget {
  const MealSetupDialog({super.key});

  @override
  State<MealSetupDialog> createState() => _MealSetupDialogState();
}

class _MealSetupDialogState extends State<MealSetupDialog> {
  TimeOfDay _breakfast = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _lunch = const TimeOfDay(hour: 13, minute: 0);
  TimeOfDay _dinner = const TimeOfDay(hour: 20, minute: 0);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Welcome to MedTime!', style: TextStyle(fontWeight: FontWeight.w800)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('To help you schedule your medications, please set your usual meal times:'),
            const SizedBox(height: 20),
            _timeTile('Breakfast', _breakfast, (t) => setState(() => _breakfast = t)),
            _timeTile('Lunch', _lunch, (t) => setState(() => _lunch = t)),
            _timeTile('Dinner', _dinner, (t) => setState(() => _dinner = t)),
            const Divider(height: 32),
            const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('We need permission to alert you when it is time to take your medicine.', style: TextStyle(fontSize: 13)),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () async {
            // First request notifications
            await NotificationService.instance.requestPermissions();
            
            // Then save meal times
            await SettingsService.instance.setMealTimes(
              breakfast: _breakfast,
              lunch: _lunch,
              dinner: _dinner,
            );
            if (!context.mounted) return;
            Navigator.pop(context);
          },
          child: const Text('Save Times'),
        ),
      ],
    );
  }

  Widget _timeTile(String title, TimeOfDay time, Function(TimeOfDay) onSelect) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: Text(time.format(context), style: const TextStyle(fontSize: 18, color: AppTheme.primary, fontWeight: FontWeight.bold)),
      onTap: () async {
        final t = await showTimePicker(context: context, initialTime: time);
        if (t != null) onSelect(t);
      },
    );
  }
}
