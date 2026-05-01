import 'package:flutter/material.dart';
import '../models/day_status_model.dart';

class DayStatusChip extends StatelessWidget {
  final DayStatus? status;
  final VoidCallback onTap;
  const DayStatusChip({super.key, this.status, required this.onTap});

  Color _getColor(String? s) {
    switch (s) {
      case 'going': return const Color(0xFF10B981);
      case 'holiday': return const Color(0xFFF59E0B);
      case 'leave': return const Color(0xFFEF4444);
      case 'od': return const Color(0xFF6366F1);
      default: return const Color(0xFF6B7280);
    }
  }

  IconData _getIcon(String? s) {
    switch (s) {
      case 'going': return Icons.school_rounded;
      case 'holiday': return Icons.beach_access_rounded;
      case 'leave': return Icons.home_rounded;
      case 'od': return Icons.work_rounded;
      default: return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor(status?.status);
    final icon = _getIcon(status?.status);
    final label = status?.label ?? 'Set Today\'s Status';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(60), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Flexible(child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13), overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 6),
            Icon(Icons.edit_rounded, size: 14, color: color.withAlpha(150)),
          ],
        ),
      ),
    );
  }
}

class DayStatusDialog extends StatelessWidget {
  const DayStatusDialog({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = [
      ('going', 'Going to College', Icons.school_rounded, const Color(0xFF10B981)),
      ('holiday', 'Holiday', Icons.beach_access_rounded, const Color(0xFFF59E0B)),
      ('leave', 'Leave', Icons.home_rounded, const Color(0xFFEF4444)),
      ('od', 'On Duty (OD)', Icons.work_rounded, const Color(0xFF6366F1)),
    ];
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: theme.colorScheme.primaryContainer.withAlpha(80), borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.today_rounded, size: 22, color: theme.colorScheme.primary)),
        const SizedBox(width: 12),
        const Flexible(child: Text('Are you going to\ncollege today?', style: TextStyle(fontSize: 18))),
      ]),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: options.map((opt) {
          return Padding(padding: const EdgeInsets.only(bottom: 8), child: InkWell(
            onTap: () => Navigator.of(context).pop(opt.$1),
            borderRadius: BorderRadius.circular(14),
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: opt.$4.withAlpha(60)), color: opt.$4.withAlpha(15)),
              child: Row(children: [
                Icon(opt.$3, color: opt.$4, size: 24), const SizedBox(width: 14),
                Expanded(child: Text(opt.$2, style: TextStyle(color: opt.$4, fontWeight: FontWeight.w700, fontSize: 15))),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: opt.$4.withAlpha(120)),
              ]),
            ),
          ));
        }).toList(),
      ),
    );
  }
}
