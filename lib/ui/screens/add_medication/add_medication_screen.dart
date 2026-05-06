import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../core/models/medication.dart';
import '../../../core/models/schedule.dart';
import '../../../core/providers/medication_provider.dart';
import '../../../core/services/settings_service.dart';
import '../../../ui/theme/app_theme.dart';

class AddMedicationScreen extends StatefulWidget {
  final Medication? medication;
  const AddMedicationScreen({super.key, this.medication});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _uuid = const Uuid();
  final _formKey = GlobalKey<FormState>();
  
  String? _imagePath;
  final _nameCtrl = TextEditingController();
  final _doseAmtCtrl = TextEditingController(text: '1');
  String _doseUnit = 'tablet(s)';
  final String _colorHex = '#1A8FE3';
  final Set<String> _selectedPresets = {};
  final DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _ongoing = true;
  final _instrCtrl = TextEditingController();
  
  bool _saving = false;
  static const _units = ['tablet(s)', 'capsule(s)', 'ml', 'mg', 'drop(s)', 'puff(s)', 'patch(es)'];

  @override
  void initState() {
    super.initState();
    if (widget.medication != null) {
      final m = widget.medication!;
      _nameCtrl.text = m.name;
      _doseAmtCtrl.text = m.dosageAmount;
      _doseUnit = m.dosageUnit;
      _imagePath = m.imagePath;
      _instrCtrl.text = m.instructions ?? '';
      if (m.endDate != null) {
        _ongoing = false;
        _endDate = DateTime.parse(m.endDate!);
      }
      _loadExistingPresets(m.id);
    }
  }

  Future<void> _loadExistingPresets(String medId) async {
    final prov = context.read<MedicationProvider>();
    final schedules = await prov.getSchedules(medId);
    setState(() {
      for (final s in schedules) {
        _selectedPresets.add(s.label);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.medication == null ? 'Add Medicine' : 'Edit Medicine'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Medicine Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.primary)),
                    const SizedBox(height: 20),
                    _buildMainRow(),
                    const SizedBox(height: 24),
                    _buildDosageRow(),
                    const SizedBox(height: 40),
                    const Center(child: Text('When to take?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
                    const SizedBox(height: 8),
                    const Center(child: Text('Select meal times or set a custom time:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
                    const SizedBox(height: 24),
                    _buildCenteredSchedule(),
                    const SizedBox(height: 40),
                    _buildDurationSection(),
                  ],
                ),
              ),
            ),
          ),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildCenteredSchedule() => Column(
    children: [
      _presetRow(['Before Breakfast', 'After Breakfast']),
      const SizedBox(height: 12),
      _presetRow(['Before Lunch', 'After Lunch']),
      const SizedBox(height: 12),
      _presetRow(['Before Dinner', 'After Dinner']),
      const SizedBox(height: 12),
      _presetRow(['Before Bed', 'Custom Time']),
    ],
  );

  Widget _presetRow(List<String> labels) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: labels.map((l) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: _timingChip(l),
    )).toList(),
  );

  Widget _timingChip(String label) {
    final isCustom = label == 'Custom Time';
    final isAlreadySelectedCustom = label.contains('|');
    final displayLabel = isAlreadySelectedCustom ? label.split('|')[0] : label;
    final isSelected = _selectedPresets.contains(label);

    return FilterChip(
      label: Text(displayLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      selected: isSelected,
      onSelected: (val) async {
        if (isCustom) {
          final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
          if (t != null) {
            final timeStr = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
            setState(() => _selectedPresets.add('at ${t.format(context)}|$timeStr'));
          }
          return;
        }
        setState(() {
          if (val) {
            _selectedPresets.add(label);
          } else {
            _selectedPresets.remove(label);
          }
        });
      },
      selectedColor: AppTheme.primary.withValues(alpha: 0.15),
      checkmarkColor: AppTheme.primary,
      labelStyle: TextStyle(color: isSelected ? AppTheme.primary : AppTheme.textPrimary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isSelected ? AppTheme.primary : Colors.grey.shade300, width: isSelected ? 2 : 1),
      ),
    );
  }

  Widget _buildMainRow() => Row(children: [
    _buildImagePicker(), const SizedBox(width: 16),
    Expanded(child: TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Name *', hintText: 'e.g. Aspirin'), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null)),
  ]);

  Widget _buildDosageRow() => Row(children: [
    Expanded(child: TextFormField(controller: _doseAmtCtrl, decoration: const InputDecoration(labelText: 'Amount *'), keyboardType: TextInputType.number)),
    const SizedBox(width: 12),
    Expanded(child: DropdownButtonFormField<String>(value: _doseUnit, items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(), onChanged: (v) => setState(() => _doseUnit = v!))),
  ]);

  Widget _buildDurationSection() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.calendar_today, color: AppTheme.primary), title: const Text('Starts Today', style: TextStyle(fontWeight: FontWeight.bold)), subtitle: const Text('Ongoing (no end date)'), trailing: const Icon(Icons.chevron_right), onTap: () {}),
    TextFormField(controller: _instrCtrl, decoration: const InputDecoration(labelText: 'Instructions', hintText: 'With water...')),
  ]);

  Widget _buildSaveButton() => Container(
    padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppTheme.surface, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))]),
    child: ElevatedButton(onPressed: _saving ? null : _save, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, minimumSize: const Size(double.infinity, 60)), child: _saving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Medicine', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
  );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPresets.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least one time'))); return; }

    setState(() => _saving = true);
    try {
      final prov = context.read<MedicationProvider>();
      final mealTimes = await SettingsService.instance.getMealTimes();
      final now = DateTime.now().toIso8601String();
      final medId = widget.medication?.id ?? _uuid.v4();

      final med = Medication(
        id: medId,
        name: _nameCtrl.text.trim(),
        description: '',
        imagePath: _imagePath,
        colorHex: _colorHex,
        dosageAmount: _doseAmtCtrl.text.trim(),
        dosageUnit: _doseUnit,
        instructions: _instrCtrl.text.trim(),
        startDate: widget.medication?.startDate ?? _startDate.toIso8601String(),
        endDate: _ongoing ? null : _endDate?.toIso8601String(),
        isActive: widget.medication?.isActive ?? true,
        createdAt: widget.medication?.createdAt ?? now,
        updatedAt: now,
      );

      final schedules = _buildSchedules(medId, _selectedPresets, mealTimes, now);
      
      if (widget.medication == null) {
        await prov.addMedication(med, schedules);
      } else {
        await prov.updateMedication(med, schedules);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
    finally { if (mounted) setState(() => _saving = false); }
  }

  List<MedSchedule> _buildSchedules(String medId, Set<String> presets, Map<String, TimeOfDay> mealTimes, String now) {
    return presets.map((label) {
      TimeOfDay baseTime; int offset = 0;
      if (label.contains('|')) {
        final timePart = label.split('|')[1];
        final parts = timePart.split(':');
        baseTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        offset = 0;
      } else if (label.contains('Breakfast')) { baseTime = mealTimes['Breakfast']!; offset = label.startsWith('Before') ? -30 : 30; }
      else if (label.contains('Lunch')) { baseTime = mealTimes['Lunch']!; offset = label.startsWith('Before') ? -30 : 30; }
      else if (label.contains('Dinner')) { baseTime = mealTimes['Dinner']!; offset = label.startsWith('Before') ? -30 : 30; }
      else { baseTime = const TimeOfDay(hour: 22, minute: 0); offset = 0; }

      final totalMinutes = baseTime.hour * 60 + baseTime.minute + offset;
      final finalTime = TimeOfDay(hour: (totalMinutes ~/ 60) % 24, minute: totalMinutes % 60);
      final timeStr = '${finalTime.hour.toString().padLeft(2, '0')}:${finalTime.minute.toString().padLeft(2, '0')}';

      return MedSchedule(id: _uuid.v4(), medicationId: medId, timeOfDay: timeStr, label: label, isActive: true, daysOfWeek: '1,2,3,4,5,6,7', notifyBeforeMinutes: 10, createdAt: now);
    }).toList();
  }

  Widget _buildImagePicker() => GestureDetector(onTap: _pickImage, child: Container(width: 60, height: 60, decoration: BoxDecoration(color: AppTheme.colorFromHex(_colorHex).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: AppTheme.colorFromHex(_colorHex), width: 2)), child: _imagePath != null && File(_imagePath!).existsSync() ? ClipRRect(borderRadius: BorderRadius.circular(13), child: Image.file(File(_imagePath!), fit: BoxFit.cover)) : Icon(Icons.camera_alt_outlined, size: 24, color: AppTheme.colorFromHex(_colorHex))));

  Future<void> _pickImage() async {
    final xFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (xFile == null) return;
    final appDir = await getApplicationDocumentsDirectory();
    final filename = '${_uuid.v4()}${p.extension(xFile.path)}';
    final saved = await File(xFile.path).copy('${appDir.path}/$filename');
    setState(() => _imagePath = saved.path);
  }
}
