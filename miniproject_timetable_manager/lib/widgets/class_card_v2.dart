// ──────────────────────────────────────────────
// SchedIQ — Smart Timetable Manager V2
// Enhanced Class Card (V2)
// ──────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../models/class_entry_model.dart';
import '../utils/theme.dart';

class ClassCardV2 extends StatelessWidget {
  final ClassEntry classEntry;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onAttendance;
  final bool showAttendanceButton;

  const ClassCardV2({
    super.key,
    required this.classEntry,
    this.onTap,
    this.onDelete,
    this.onAttendance,
    this.showAttendanceButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final isOngoing = classEntry.isOngoing;
    final theme = Theme.of(context);
    final typeColor = AppTheme.getTypeColor(classEntry.type);

    return GestureDetector(
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
                        width: 1,
                      ),
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
                    // Top row: Time + type badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
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
                              '${classEntry.startTime} – ${classEntry.endTime}',
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
                              Icon(AppTheme.getTypeIcon(classEntry.type),
                                  size: 14, color: typeColor),
                              const SizedBox(width: 4),
                              Text(
                                classEntry.type,
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
                      classEntry.subjectCourse ?? '',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 2),

                    // Subject code
                    Text(
                      classEntry.subjectCode ?? '',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withAlpha(150),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Bottom row: Faculty + Location + Attendance
                    Row(
                      children: [
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
                                  classEntry.subjectFaculty ?? '',
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
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 16,
                                color: theme.colorScheme.onSurface
                                    .withAlpha(150)),
                            const SizedBox(width: 4),
                            Text(
                              classEntry.location,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withAlpha(180),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        if (showAttendanceButton && onAttendance != null) ...[
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: onAttendance,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer
                                    .withAlpha(80),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.fact_check_outlined,
                                size: 18,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                        if (onDelete != null) ...[
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () async {
                              final result = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  title: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(color: Colors.red.withAlpha(30), borderRadius: BorderRadius.circular(12)),
                                        child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 24),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text('Delete Class'),
                                    ],
                                  ),
                                  content: Text('Are you sure you want to delete "${classEntry.subjectCourse}"? This action cannot be undone.', style: theme.textTheme.bodyMedium),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('Cancel', style: TextStyle(color: theme.colorScheme.onSurface))),
                                    FilledButton(onPressed: () => Navigator.of(ctx).pop(true), style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('Delete', style: TextStyle(color: Colors.white))),
                                  ],
                                ),
                              );
                              if (result == true) onDelete?.call();
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.red.withAlpha(20),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
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
    );
  }
}
