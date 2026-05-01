import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/holiday_model.dart';
import '../../providers/holiday_provider.dart';
import '../../utils/constants.dart';

class HolidayScreen extends StatefulWidget {
  const HolidayScreen({super.key});
  @override
  State<HolidayScreen> createState() => _HolidayScreenState();
}

class _HolidayScreenState extends State<HolidayScreen> {
  @override
  void initState() { super.initState(); Future.microtask(() { if (mounted) Provider.of<HolidayProvider>(context, listen: false).fetchHolidays(); }); }

  void _addEditHoliday({Holiday? holiday}) async {
    String type = holiday?.type ?? 'Holiday';
    String desc = holiday?.description ?? '';
    DateTime start = holiday != null ? DateTime.parse(holiday.startDate) : DateTime.now();
    DateTime end = holiday != null ? DateTime.parse(holiday.endDate) : DateTime.now();
    final descCtrl = TextEditingController(text: desc);

    final result = await showDialog<Holiday>(context: context, builder: (c) => StatefulBuilder(builder: (c, ss) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(holiday == null ? 'Add Holiday' : 'Edit Holiday'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<String>(initialValue: type, decoration: InputDecoration(labelText: 'Type', border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
          items: AppConstants.holidayTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (v) => ss(() => type = v!)),
        const SizedBox(height: 12),
        TextField(controller: descCtrl, decoration: InputDecoration(labelText: 'Description', hintText: 'e.g. Republic Day', border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
          onChanged: (v) => desc = v),
        const SizedBox(height: 12),
        ListTile(title: Text('Start: ${DateFormat('dd MMM yyyy').format(start)}'), leading: const Icon(Icons.calendar_today), contentPadding: EdgeInsets.zero,
          onTap: () async { final d = await showDatePicker(context: c, initialDate: start, firstDate: DateTime(2020), lastDate: DateTime(2030)); if (d != null) ss(() => start = d); }),
        ListTile(title: Text('End: ${DateFormat('dd MMM yyyy').format(end)}'), leading: const Icon(Icons.calendar_today), contentPadding: EdgeInsets.zero,
          onTap: () async { final d = await showDatePicker(context: c, initialDate: end, firstDate: DateTime(2020), lastDate: DateTime(2030)); if (d != null) ss(() => end = d); }),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
        FilledButton(onPressed: () { Navigator.pop(c, Holiday(id: holiday?.id, startDate: start.toIso8601String().substring(0, 10), endDate: end.toIso8601String().substring(0, 10), type: type, description: desc.trim())); }, child: Text(holiday == null ? 'Add' : 'Update'))],
    )));

    if (result != null && mounted) {
      final provider = Provider.of<HolidayProvider>(context, listen: false);
      if (holiday != null) { await provider.updateHoliday(result); } else { await provider.addHoliday(result); }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Holidays', style: TextStyle(fontWeight: FontWeight.w700)), elevation: 0),
      body: Consumer<HolidayProvider>(builder: (ctx, provider, _) {
        if (provider.isLoading) return const Center(child: CircularProgressIndicator());
        if (provider.holidays.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: const Color(0xFFF59E0B).withAlpha(30), shape: BoxShape.circle),
            child: const Icon(Icons.beach_access_rounded, size: 56, color: Color(0xFFF59E0B))),
          const SizedBox(height: 24), Text('No holidays added', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8), Text('Tap + to add holidays', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withAlpha(120))),
        ]));

        return ListView.builder(padding: const EdgeInsets.fromLTRB(16, 12, 16, 100), itemCount: provider.holidays.length, itemBuilder: (ctx, i) {
          final h = provider.holidays[i];
          final color = h.type == 'Exam' ? const Color(0xFFEF4444) : h.type == 'Event' ? const Color(0xFF6366F1) : const Color(0xFFF59E0B);
          return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(12)),
              child: Icon(h.type == 'Exam' ? Icons.quiz_rounded : h.type == 'Event' ? Icons.celebration_rounded : Icons.beach_access_rounded, color: color)),
            title: Text(h.description.isNotEmpty ? h.description : h.type, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${h.startDate} → ${h.endDate}  •  ${h.type}', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withAlpha(150))),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(Icons.edit_rounded, size: 20), onPressed: () => _addEditHoliday(holiday: h)),
              IconButton(icon: Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red.shade400), onPressed: () async {
                final confirm = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('Delete Holiday'), content: const Text('Delete this holiday?'),
                  actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(c, true), style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('Delete', style: TextStyle(color: Colors.white)))]));
                if (confirm == true && mounted) provider.deleteHoliday(h.id!);
              }),
            ]),
          ));
        });
      }),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _addEditHoliday(), icon: const Icon(Icons.add_rounded), label: const Text('Add Holiday', style: TextStyle(fontWeight: FontWeight.w600))),
    );
  }
}
