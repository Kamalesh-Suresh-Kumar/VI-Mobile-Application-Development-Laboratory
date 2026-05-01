import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../providers/holiday_provider.dart';
import '../../widgets/live_clock.dart';
import '../../widgets/day_status_chip.dart';
import '../../widgets/class_card_v2.dart';
import '../../utils/theme.dart';

class HomeScreenV2 extends StatefulWidget {
  const HomeScreenV2({super.key});
  @override
  State<HomeScreenV2> createState() => _HomeScreenV2State();
}

class _HomeScreenV2State extends State<HomeScreenV2> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Refresh every 60 seconds for current/next class updates
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _showDayStatusDialog(BuildContext context) async {
    final result = await showDialog<String>(context: context, builder: (_) => const DayStatusDialog());
    if (result != null && context.mounted) {
      await Provider.of<AppProvider>(context, listen: false).setTodayStatus(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer2<AppProvider, HolidayProvider>(
      builder: (context, appProvider, holidayProvider, _) {
        final current = appProvider.currentClass;
        final next = appProvider.nextClass;
        final isHoliday = holidayProvider.isTodayHoliday();
        final todayStatus = appProvider.todayStatus;

        return Scaffold(
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () => appProvider.loadAll(),
              child: ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 24), children: [
                // Greeting
                Text(_getGreeting(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.colorScheme.primary, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text('SchedIQ', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
                const SizedBox(height: 16),

                // Live Clock
                const LiveClock(),
                const SizedBox(height: 16),

                // Day Status
                Row(children: [
                  Text("Today's Status", style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  if (isHoliday) Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFF59E0B).withAlpha(20), borderRadius: BorderRadius.circular(8)),
                    child: const Text('🎉 Holiday Today', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFF59E0B))),
                  ),
                ]),
                const SizedBox(height: 8),
                DayStatusChip(status: todayStatus, onTap: () => _showDayStatusDialog(context)),
                const SizedBox(height: 20),

                // Current Class
                _sectionHeader(theme, 'Currently In', Icons.play_circle_rounded, AppTheme.labColor),
                const SizedBox(height: 8),
                if (current != null)
                  ClassCardV2(classEntry: current, showAttendanceButton: false)
                else
                  _emptyCard(context, 'No class right now', Icons.free_breakfast_rounded),
                const SizedBox(height: 16),

                // Next Class
                _sectionHeader(theme, 'Coming Up Next', Icons.skip_next_rounded, theme.colorScheme.primary),
                const SizedBox(height: 8),
                if (next != null)
                  ClassCardV2(classEntry: next, showAttendanceButton: false)
                else
                  _emptyCard(context, 'No more classes today', Icons.check_circle_outline_rounded),

                // Today's schedule
                const SizedBox(height: 20),
                _sectionHeader(theme, "Today's Schedule", Icons.view_agenda_rounded, const Color(0xFF8B5CF6)),
                const SizedBox(height: 8),
                ..._buildTodaySchedule(appProvider, todayStatus),
              ]),
            ),
          ),
        );
      },
    );
  }

  Widget _sectionHeader(ThemeData theme, String title, IconData icon, Color color) {
    return Row(children: [
      Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: color)),
      const SizedBox(width: 8),
      Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
    ]);
  }

  Widget _emptyCard(BuildContext context, String msg, IconData icon) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(40),
        border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(40)),
      ),
      child: Row(children: [
        Icon(icon, size: 28, color: theme.colorScheme.onSurface.withAlpha(100)),
        const SizedBox(width: 12),
        Text(msg, style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(150), fontWeight: FontWeight.w500)),
      ]),
    );
  }

  List<Widget> _buildTodaySchedule(AppProvider provider, dynamic status) {
    final dayName = DateFormat('EEEE').format(DateTime.now());
    final classes = provider.getClassesByDay(dayName);

    if (status != null && (status.status == 'holiday' || status.status == 'leave')) {
      return [_emptyCard(context, status.status == 'holiday' ? 'Enjoy your holiday! 🎉' : 'Rest well! 🏠', Icons.celebration_rounded)];
    }

    if (classes.isEmpty) return [_emptyCard(context, 'No classes scheduled today', Icons.event_available_rounded)];

    return classes.map((c) => ClassCardV2(classEntry: c, showAttendanceButton: false)).toList();
  }
}
