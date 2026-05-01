import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/class_entry_model.dart';
import '../../models/subject_model.dart';
import '../../providers/app_provider.dart';
import '../../providers/subject_provider.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';

class AddEditClassScreen extends StatefulWidget {
  final ClassEntry? classEntry;
  const AddEditClassScreen({super.key, this.classEntry});
  @override
  State<AddEditClassScreen> createState() => _AddEditClassScreenState();
}

class _AddEditClassScreenState extends State<AddEditClassScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _locationCtrl, _durationCtrl;
  Subject? _selectedSubject;
  String _selectedDay = 'Monday';
  String _selectedType = 'Theory';
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  bool _saving = false;
  bool get isEditing => widget.classEntry != null;

  @override
  void initState() {
    super.initState();
    _locationCtrl = TextEditingController(text: widget.classEntry?.location ?? '');
    _durationCtrl = TextEditingController(text: widget.classEntry?.duration ?? '');
    if (widget.classEntry != null) {
      _selectedDay = widget.classEntry!.day;
      _selectedType = widget.classEntry!.type;
      _startTime = _parseTime(widget.classEntry!.startTime);
      _endTime = _parseTime(widget.classEntry!.endTime);
    }
    Future.microtask(() {
      if (!mounted) return;
      final subProvider = Provider.of<SubjectProvider>(context, listen: false);
      subProvider.fetchSubjects().then((_) {
        if (widget.classEntry != null && mounted) {
          setState(() { _selectedSubject = subProvider.getSubjectById(widget.classEntry!.subjectId); });
        }
      });
    });
  }

  @override
  void dispose() { _locationCtrl.dispose(); _durationCtrl.dispose(); super.dispose(); }

  TimeOfDay _parseTime(String t) {
    try { final dt = DateFormat.jm().parse(t); return TimeOfDay.fromDateTime(dt); } catch (_) { return const TimeOfDay(hour: 9, minute: 0); }
  }

  String _formatTime(TimeOfDay t) {
    final now = DateTime.now();
    return DateFormat('hh:mm a').format(DateTime(now.year, now.month, now.day, t.hour, t.minute));
  }

  void _calcDuration() {
    final s = _startTime.hour * 60 + _startTime.minute;
    final e = _endTime.hour * 60 + _endTime.minute;
    if (e > s) {
      final d = e - s;
      final h = d ~/ 60, m = d % 60;
      _durationCtrl.text = h > 0 && m > 0 ? '${h}h ${m}m' : h > 0 ? '${h}h' : '${m}m';
    } else { _durationCtrl.text = ''; }
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(context: context, initialTime: isStart ? _startTime : _endTime,
      builder: (c, child) => Theme(data: Theme.of(c).copyWith(timePickerTheme: TimePickerThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)))), child: child!));
    if (picked != null) { setState(() { if (isStart) _startTime = picked; else _endTime = picked; _calcDuration(); }); }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSubject == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a subject'), behavior: SnackBarBehavior.floating)); return; }
    final s = _startTime.hour * 60 + _startTime.minute;
    final e = _endTime.hour * 60 + _endTime.minute;
    if (e <= s) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('End time must be after start'), behavior: SnackBarBehavior.floating)); return; }

    setState(() => _saving = true);
    try {
      final provider = Provider.of<AppProvider>(context, listen: false);
      final entry = ClassEntry(
        id: widget.classEntry?.id, subjectId: _selectedSubject!.id!, day: _selectedDay,
        startTime: _formatTime(_startTime), endTime: _formatTime(_endTime), type: _selectedType,
        location: _locationCtrl.text.trim(), duration: _durationCtrl.text.trim(),
        subjectCode: _selectedSubject!.code, subjectCourse: _selectedSubject!.course, subjectFaculty: _selectedSubject!.faculty,
      );
      if (isEditing) { await provider.updateClass(entry); } else { await provider.addClass(entry); }
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEditing ? 'Class updated' : 'Class added'), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(16))); Navigator.pop(context); }
    } catch (e2) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e2'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
    } finally { if (mounted) setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Class' : 'Add Class', style: const TextStyle(fontWeight: FontWeight.w700)), elevation: 0),
      body: Form(key: _formKey, child: Consumer<SubjectProvider>(builder: (ctx, subProv, _) {
        return ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 100), children: [
          _section(theme, 'Subject', Icons.school_rounded), const SizedBox(height: 12),
          DropdownButtonFormField<Subject>(
            initialValue: _selectedSubject,
            decoration: InputDecoration(labelText: 'Select Subject', prefixIcon: const Icon(Icons.book_rounded, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)), filled: true, fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha(80)),
            borderRadius: BorderRadius.circular(14),
            items: subProv.subjects.map((s) => DropdownMenuItem(value: s, child: Text('${s.code} — ${s.course}'))).toList(),
            onChanged: (v) => setState(() => _selectedSubject = v),
            validator: (_) => _selectedSubject == null ? 'Select a subject' : null,
          ),
          const SizedBox(height: 20),

          _section(theme, 'Schedule', Icons.calendar_month_rounded), const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedDay,
            decoration: InputDecoration(labelText: 'Day', prefixIcon: const Icon(Icons.calendar_today_rounded, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)), filled: true, fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha(80)),
            borderRadius: BorderRadius.circular(14),
            items: AppConstants.weekDays.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
            onChanged: (v) => setState(() => _selectedDay = v!),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _timePicker(context, 'Start', _startTime, () => _pickTime(true), Icons.play_circle_outline_rounded)),
            const SizedBox(width: 14),
            Expanded(child: _timePicker(context, 'End', _endTime, () => _pickTime(false), Icons.stop_circle_outlined)),
          ]),
          const SizedBox(height: 14),
          TextFormField(controller: _locationCtrl, decoration: InputDecoration(labelText: 'Room / Location', hintText: 'e.g. Room 301', prefixIcon: const Icon(Icons.location_on_rounded, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)), filled: true, fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha(80)),
            validator: (v) => v == null || v.trim().isEmpty ? 'Enter location' : null),
          const SizedBox(height: 14),
          TextFormField(controller: _durationCtrl, readOnly: true, decoration: InputDecoration(labelText: 'Duration (auto)', prefixIcon: const Icon(Icons.timer_rounded, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)), filled: true, fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha(80))),
          const SizedBox(height: 20),

          _section(theme, 'Class Type', Icons.category_rounded), const SizedBox(height: 12),
          _typeSelector(theme),
          const SizedBox(height: 32),
          SizedBox(height: 54, child: FilledButton.icon(onPressed: _saving ? null : _save,
            icon: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(isEditing ? Icons.save_rounded : Icons.add_rounded),
            label: Text(_saving ? 'Saving...' : (isEditing ? 'Update Class' : 'Add Class'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))),
        ]);
      })),
    );
  }

  Widget _section(ThemeData theme, String title, IconData icon) => Row(children: [
    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: theme.colorScheme.primaryContainer.withAlpha(80), borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, size: 18, color: theme.colorScheme.primary)),
    const SizedBox(width: 10),
    Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
  ]);

  Widget _timePicker(BuildContext ctx, String label, TimeOfDay time, VoidCallback onTap, IconData icon) {
    final theme = Theme.of(ctx);
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14), child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(border: Border.all(color: theme.colorScheme.outline.withAlpha(100)), borderRadius: BorderRadius.circular(14), color: theme.colorScheme.surfaceContainerHighest.withAlpha(80)),
      child: Row(children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary), const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withAlpha(150), fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(_formatTime(time), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ]),
      ]),
    ));
  }

  Widget _typeSelector(ThemeData theme) {
    return Row(children: AppConstants.classTypes.map((type) {
      final sel = _selectedType == type;
      final color = AppTheme.getTypeColor(type);
      return Expanded(child: GestureDetector(onTap: () => setState(() => _selectedType = type),
        child: AnimatedContainer(duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.only(right: type != AppConstants.classTypes.last ? 10 : 0),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(color: sel ? color.withAlpha(25) : Colors.transparent,
            border: Border.all(color: sel ? color : theme.colorScheme.outlineVariant.withAlpha(120), width: sel ? 2 : 1), borderRadius: BorderRadius.circular(14)),
          child: Column(children: [
            Icon(AppTheme.getTypeIcon(type), color: sel ? color : theme.colorScheme.onSurface.withAlpha(150), size: 24),
            const SizedBox(height: 6),
            Text(type, style: TextStyle(color: sel ? color : theme.colorScheme.onSurface.withAlpha(180), fontWeight: sel ? FontWeight.w700 : FontWeight.w500, fontSize: 13)),
          ]),
        ),
      ));
    }).toList());
  }
}
