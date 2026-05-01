import 'package:flutter/material.dart';

class WeeklySummary extends StatelessWidget {
  final int totalClasses;
  final String totalHours;
  final Map<String, int> dayCounts;
  const WeeklySummary({super.key, required this.totalClasses, required this.totalHours, required this.dayCounts});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [theme.colorScheme.primary.withAlpha(15), theme.colorScheme.tertiary.withAlpha(10)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withAlpha(30)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Weekly Overview', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Row(children: [
          _stat(context, Icons.class_rounded, '$totalClasses', 'Classes', theme.colorScheme.primary),
          const SizedBox(width: 16),
          _stat(context, Icons.timer_rounded, totalHours, 'Total Hours', const Color(0xFF10B981)),
        ]),
      ]),
    );
  }

  Widget _stat(BuildContext ctx, IconData icon, String value, String label, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withAlpha(15), borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: color)),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: TextStyle(fontSize: 11, color: color.withAlpha(180))),
        ]),
      ]),
    ));
  }
}
