import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/providers/medication_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/medication_list_card.dart';
import '../add_medication/add_medication_screen.dart';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  String _filter = 'All';
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Medicines'),
      ),
      body: Consumer<MedicationProvider>(
        builder: (context, prov, _) {
          var meds = prov.medications;
          if (_search.isNotEmpty) {
            meds = meds.where((m) => m.name.toLowerCase().contains(_search.toLowerCase())).toList();
          }
          if (_filter == 'Active') meds = meds.where((m) => m.isActive).toList();
          if (_filter == 'Inactive') meds = meds.where((m) => !m.isActive).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: const InputDecoration(
                    hintText: 'Search medicines...',
                    prefixIcon: Icon(Icons.search, size: 26),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: ['All', 'Active', 'Inactive'].map((f) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(f, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                      selectedColor: AppTheme.primary,
                      labelStyle: TextStyle(color: _filter == f ? Colors.white : AppTheme.textPrimary),
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: meds.isEmpty
                    ? const EmptyState(
                        icon: Icons.medication_outlined,
                        title: 'No medicines yet',
                        subtitle: 'Tap + to add your first medicine',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                        itemCount: meds.length,
                        itemBuilder: (ctx, i) {
                          final med = meds[i];
                          return FadeInUp(
                            delay: Duration(milliseconds: i * 60),
                            child: MedicationListCard(
                              medication: med,
                              schedules: prov.allSchedules[med.id] ?? [],
                              onToggle: () => prov.toggleActive(med.id),
                              onDelete: () => prov.deleteMedication(med.id),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => AddMedicationScreen(medication: med)),
                                );
                                if (!mounted) return;
                                prov.loadAll();
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final prov = context.read<MedicationProvider>();
          await Navigator.push(
            context, MaterialPageRoute(builder: (_) => const AddMedicationScreen()),
          );
          if (!mounted) return;
          prov.loadAll();
        },
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Medicine', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
      ),
    );
  }
}
