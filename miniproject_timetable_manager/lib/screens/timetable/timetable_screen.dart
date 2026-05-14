import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../models/attendance_model.dart';
import '../../widgets/class_card_v2.dart';
import '../../widgets/weekly_summary.dart';
import '../../utils/constants.dart';
import 'subject_list_screen.dart';
import 'add_edit_class.dart';

import '../../providers/settings_provider.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});
  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> with TickerProviderStateMixin {
  TabController? _tabController;
  List<String> _days = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      _updateTabs(settings.workingDays);
    });
  }

  void _updateTabs(List<String> workingDays) {
    if (_days.length == workingDays.length && _days.every((d) => workingDays.contains(d))) return;
    setState(() {
      _days = workingDays;
      _tabController?.dispose();
      _tabController = TabController(length: _days.length, vsync: this);
      final today = DateTime.now().weekday - 1; // 0 for Monday
      final dayName = AppConstants.allDays.length > today ? AppConstants.allDays[today] : '';
      int idx = _days.indexOf(dayName);
      if (idx != -1) _tabController!.index = idx;
    });
  }

  @override
  void dispose() { _tabController?.dispose(); super.dispose(); }

  void _markAttendance(BuildContext ctx, int classId) async {
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final result = await showDialog<AttendanceStatus>(context: ctx, builder: (c) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Mark Attendance'),
      content: const Text('What was your attendance status for this class?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, AttendanceStatus.missed), child: const Text('Absent', style: TextStyle(color: Colors.red))),
        TextButton(onPressed: () => Navigator.pop(c, AttendanceStatus.od), child: const Text('OD (On Duty)', style: TextStyle(color: Colors.blue))),
        FilledButton(onPressed: () => Navigator.pop(c, AttendanceStatus.attended), child: const Text('Present')),
      ],
    ));
    if (result != null && ctx.mounted) {
      await Provider.of<AttendanceProvider>(ctx, listen: false).markAttendance(classId: classId, date: date, status: result);
      String msg = 'Marked absent ❌';
      if (result == AttendanceStatus.attended) msg = 'Marked present ✅';
      else if (result == AttendanceStatus.od) msg = 'Marked On Duty (OD) 🛡️';
      
      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(16)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final todayName = DateFormat('EEEE').format(DateTime.now());

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(expandedHeight: 120, floating: true, pinned: true, elevation: 0,
            backgroundColor: theme.colorScheme.surface, surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 60, right: 20),
              title: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Timetable', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
              ]),
            ),
            actions: [
              Container(margin: const EdgeInsets.only(right: 8, top: 8), decoration: BoxDecoration(color: theme.colorScheme.primaryContainer.withAlpha(60), borderRadius: BorderRadius.circular(14)),
                child: IconButton(icon: Icon(Icons.subject_rounded, color: theme.colorScheme.primary), tooltip: 'Manage Subjects',
                  onPressed: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => const SubjectListScreen()));
                    if (context.mounted) Provider.of<AppProvider>(context, listen: false).loadAll();
                  })),
              Container(margin: const EdgeInsets.only(right: 12, top: 8), decoration: BoxDecoration(color: theme.colorScheme.primaryContainer.withAlpha(60), borderRadius: BorderRadius.circular(14)),
                child: IconButton(icon: Icon(Icons.today_rounded, color: theme.colorScheme.primary), tooltip: 'Go to today',
                  onPressed: () { final todayName = AppConstants.allDays[DateTime.now().weekday - 1]; int idx = _days.indexOf(todayName); if (idx != -1) _tabController?.animateTo(idx); })),
            ],
            bottom: PreferredSize(preferredSize: const Size.fromHeight(52), child: Container(
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(60)))),
              child: Consumer<SettingsProvider>(
                builder: (ctx, settings, _) {
                  _updateTabs(settings.workingDays);
                  if (_tabController == null || _days.isEmpty) return const SizedBox(height: 52);
                  return TabBar(controller: _tabController, isScrollable: true, tabAlignment: TabAlignment.start,
                    labelColor: theme.colorScheme.primary, unselectedLabelColor: theme.colorScheme.onSurface.withAlpha(150),
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                    indicatorSize: TabBarIndicatorSize.label,
                    indicator: BoxDecoration(border: Border(bottom: BorderSide(color: theme.colorScheme.primary, width: 3))),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    tabs: _days.map((day) {
                      final isToday = day == todayName;
                      return Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(day.substring(0, 3)),
                        if (isToday) ...[const SizedBox(width: 6), Container(width: 7, height: 7, decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle))],
                      ]));
                    }).toList(),
                  );
                },
              ),
            )),
          ),
        ],
        body: Consumer<AppProvider>(builder: (context, provider, _) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator());
          return Column(children: [
            Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: WeeklySummary(totalClasses: provider.totalWeeklyClasses, totalHours: provider.totalWeeklyHours, dayCounts: provider.weeklySummary)),
            Expanded(child: _tabController == null || _days.isEmpty ? const Center(child: Text('No working days configured')) : TabBarView(controller: _tabController, children: _days.map((day) {
              final classes = provider.getClassesByDay(day);
              if (classes.isEmpty) return _buildEmptyState(context, day);
              return RefreshIndicator(onRefresh: () => provider.loadAll(),
                child: ListView.builder(padding: const EdgeInsets.only(top: 8, bottom: 100), itemCount: classes.length, itemBuilder: (ctx, i) {
                  final c = classes[i];
                  return ClassCardV2(classEntry: c,
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditClassScreen(classEntry: c)));
                      if (context.mounted) provider.loadAll();
                    },
                    onDelete: () { provider.deleteClass(c.id!); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"${c.subjectCourse}" deleted'), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(16))); },
                    onAttendance: () => _markAttendance(context, c.id!),
                  );
                }),
              );
            }).toList())),
          ]);
        }),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditClassScreen()));
          if (context.mounted) Provider.of<AppProvider>(context, listen: false).loadAll();
        },
        icon: const Icon(Icons.add_rounded), label: const Text('Add Class', style: TextStyle(fontWeight: FontWeight.w600)), elevation: 4,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext ctx, String day) {
    final theme = Theme.of(ctx);
    return Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: theme.colorScheme.primaryContainer.withAlpha(50), shape: BoxShape.circle),
        child: Icon(Icons.event_available_rounded, size: 56, color: theme.colorScheme.primary.withAlpha(120))),
      const SizedBox(height: 24),
      Text('No classes on $day', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withAlpha(180))),
      const SizedBox(height: 8),
      Text('Tap + to add a new class', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withAlpha(120)), textAlign: TextAlign.center),
    ])));
  }
}
