import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/medication_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Map<String, dynamic>> _dayLogs = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    if (_selectedDay == null) return;
    final prov = context.read<MedicationProvider>();
    final logs = await prov.getLogsForDate(_selectedDay!);
    if (!mounted) return;
    setState(() => _dayLogs = logs);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: TableCalendar(
              firstDay: DateTime.now().subtract(const Duration(days: 365)),
              lastDay: DateTime.now().add(const Duration(days: 30)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                _loadLogs();
              },
              calendarStyle: CalendarStyle(
                selectedDecoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                todayDecoration: BoxDecoration(color: AppTheme.secondary.withValues(alpha: 0.5), shape: BoxShape.circle),
              ),
              headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
            ),
          ),
          Expanded(
            child: _dayLogs.isEmpty
                ? const EmptyState(
                    icon: Icons.history,
                    title: 'No logs for this day',
                    subtitle: 'Medications taken or skipped will appear here',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _dayLogs.length,
                    itemBuilder: (ctx, i) {
                      final log = _dayLogs[i];
                      final time = DateFormat.jm().format(DateTime.parse(log['scheduled_time']));
                      final status = log['status'];
                      final color = status == 'taken'
                          ? AppTheme.success
                          : status == 'skipped'
                              ? AppTheme.textSecondary
                              : AppTheme.error;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.colorFromHex(log['color_hex']).withValues(alpha: 0.1),
                            child: Icon(Icons.medication, color: AppTheme.colorFromHex(log['color_hex'])),
                          ),
                          title: Text(log['med_name'], style: const TextStyle(fontWeight: FontWeight.w800)),
                          subtitle: Text('$time • ${log['dosage_amount']} ${log['dosage_unit']}'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
