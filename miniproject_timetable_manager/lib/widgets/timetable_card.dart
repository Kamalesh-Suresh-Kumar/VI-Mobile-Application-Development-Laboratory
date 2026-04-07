import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/timetable_model.dart';

class TimetableCard extends StatelessWidget {
  final Timetable timetable;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const TimetableCard({
    super.key,
    required this.timetable,
    required this.onTap,
    required this.onDelete,
  });

  bool _isCurrentClass() {
    final now = DateTime.now();
    final dayName = DateFormat('EEEE').format(now);
    if (timetable.day != dayName) return false;

    try {
      final startTime = DateFormat('hh:mm a').parse(timetable.time);
      final endTime = DateFormat('hh:mm a').parse(timetable.endTime);

      final currentMinutes = now.hour * 60 + now.minute;
      final startMinutes = startTime.hour * 60 + startTime.minute;
      final endMinutes = endTime.hour * 60 + endTime.minute;

      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    } catch (e) {
      return false;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Theory':
        return const Color(0xFF6366F1); // Indigo
      case 'Lab':
        return const Color(0xFF10B981); // Emerald
      case 'Aptitude':
        return const Color(0xFFF59E0B); // Amber
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'Theory':
        return Icons.menu_book_rounded;
      case 'Lab':
        return Icons.science_rounded;
      case 'Aptitude':
        return Icons.psychology_rounded;
      default:
        return Icons.class_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOngoing = _isCurrentClass();
    final theme = Theme.of(context);
    final typeColor = _getTypeColor(timetable.type);

    return Dismissible(
      key: Key(timetable.id.toString()),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        final result = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: Colors.red, size: 24),
                ),
                const SizedBox(width: 12),
                const Text('Delete Class'),
              ],
            ),
            content: Text(
              'Are you sure you want to delete "${timetable.course}"? This action cannot be undone.',
              style: theme.textTheme.bodyMedium,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text('Cancel',
                    style: TextStyle(color: theme.colorScheme.onSurface)),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child:
                    const Text('Delete', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
        return result ?? false;
      },
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_rounded, color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text('Delete',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
          child: Material(
            elevation: isOngoing ? 8 : 1,
            shadowColor: isOngoing
                ? typeColor.withAlpha(100)
                : Colors.black.withAlpha(15),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: isOngoing
                    ? Border.all(color: typeColor, width: 2)
                    : Border.all(
                        color: theme.colorScheme.outlineVariant.withAlpha(80),
                        width: 1),
                gradient: isOngoing
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          typeColor.withAlpha(15),
                          typeColor.withAlpha(5),
                        ],
                      )
                    : null,
                color: isOngoing ? null : theme.colorScheme.surface,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: Time range + type badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Time with icon
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: typeColor.withAlpha(25),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.access_time_rounded,
                                  size: 16, color: typeColor),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${timetable.time} – ${timetable.endTime}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: isOngoing
                                    ? typeColor
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        // Type badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: typeColor.withAlpha(30),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_getTypeIcon(timetable.type),
                                  size: 14, color: typeColor),
                              const SizedBox(width: 4),
                              Text(
                                timetable.type,
                                style: TextStyle(
                                  color: typeColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Course name
                    Text(
                      timetable.course,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 2),

                    // Course code
                    Text(
                      timetable.code,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withAlpha(150),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Bottom row: Faculty + Location
                    Row(
                      children: [
                        // Faculty
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.person_outline_rounded,
                                  size: 16,
                                  color: theme.colorScheme.onSurface
                                      .withAlpha(150)),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  timetable.faculty,
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface
                                        .withAlpha(180),
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Location
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 16,
                                color: theme.colorScheme.onSurface
                                    .withAlpha(150)),
                            const SizedBox(width: 4),
                            Text(
                              timetable.location,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withAlpha(180),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Ongoing indicator
                    if (isOngoing) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: typeColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: typeColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'ONGOING',
                              style: TextStyle(
                                color: typeColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
