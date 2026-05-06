import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/medication_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/grouped_dose_card.dart';
import '../../widgets/adherence_ring.dart';
import '../../widgets/empty_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MedicationProvider>().loadAll();
    });
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning! 🌅';
    if (h < 17) return 'Good Afternoon! ☀️';
    return 'Good Evening! 🌙';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<MedicationProvider>(
        builder: (context, prov, _) {
          final doses = prov.todayDoses;
          final now = DateTime.now();

          // Grouping logic
          final Map<String, List<Map<String, dynamic>>> groupedDoses = {};
          for (final d in doses) {
            if (d['status'] != 'pending') continue;
            final label = d['schedule_label'] ?? 'General';
            groupedDoses.putIfAbsent(label, () => []).add(d);
          }

          // Sort groups by time
          final sortedLabels = groupedDoses.keys.toList()..sort((a, b) {
            final timeA = DateTime.parse(groupedDoses[a]![0]['scheduled_time']);
            final timeB = DateTime.parse(groupedDoses[b]![0]['scheduled_time']);
            return timeA.compareTo(timeB);
          });

          final taken = doses.where((d) => d['status'] == 'taken').length;
          final total = doses.length;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 160,
                pinned: true,
                backgroundColor: AppTheme.surface,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppTheme.primary, AppTheme.secondary],
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 56, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeInDown(
                          child: Text(_greeting(), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
                        ),
                        const SizedBox(height: 4),
                        FadeInDown(
                          delay: const Duration(milliseconds: 100),
                          child: Text(DateFormat('EEEE, MMMM d').format(now), style: const TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeInUp(child: AdherenceRing(taken: taken, total: total)),
                      const SizedBox(height: 24),

                      if (prov.loading)
                        const Center(child: CircularProgressIndicator())
                      else if (doses.isEmpty)
                        const EmptyState(icon: Icons.medication_outlined, title: 'No medicines today', subtitle: 'Add a medication to get started')
                      else ...[
                        _sectionLabel('🕐 Your Schedule', AppTheme.primary),
                        const SizedBox(height: 12),
                        ...sortedLabels.asMap().entries.map((e) {
                          final groupItems = groupedDoses[e.value]!;
                          final scheduledTime = DateTime.parse(groupItems[0]['scheduled_time']);
                          final isUrgent = scheduledTime.isBefore(now.add(const Duration(minutes: 30)));

                          return FadeInUp(
                            delay: Duration(milliseconds: e.key * 50),
                            child: GroupedDoseCard(
                              label: e.value,
                              time: DateFormat.jm().format(scheduledTime),
                              doses: groupItems,
                              urgent: isUrgent,
                            ),
                          );
                        }),
                      ],
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionLabel(String text, Color color) => Row(
    children: [
      Container(width: 4, height: 20, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(text, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
    ],
  );
}
