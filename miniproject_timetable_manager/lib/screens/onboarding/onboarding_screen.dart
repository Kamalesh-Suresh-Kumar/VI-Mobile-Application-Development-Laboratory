import 'package:flutter/material.dart';
import '../../services/preferences_service.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({super.key, required this.onComplete});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _current = 0;

  final _pages = const [
    _OnboardPage(icon: Icons.home_rounded, color: Color(0xFF6366F1), title: 'Home Dashboard', desc: 'See your live clock, current & upcoming classes, and set your daily status — all at a glance.'),
    _OnboardPage(icon: Icons.calendar_month_rounded, color: Color(0xFF10B981), title: 'Smart Timetable', desc: 'Create subjects first, then add classes. View your weekly schedule organized by day with full CRUD support.'),
    _OnboardPage(icon: Icons.fact_check_rounded, color: Color(0xFFF59E0B), title: 'Attendance Tracking', desc: 'Track attendance per class. Color-coded indicators show your standing — green, orange, or red.'),
    _OnboardPage(icon: Icons.settings_rounded, color: Color(0xFF8B5CF6), title: 'Settings & More', desc: 'Manage notifications, holidays, export your timetable as PDF, and customize your experience.'),
  ];

  void _next() {
    if (_current < _pages.length - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _finish();
    }
  }

  void _finish() async {
    await PreferencesService().setOnboardingDone(true);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          // Skip button
          Align(alignment: Alignment.topRight, child: Padding(
            padding: const EdgeInsets.all(16),
            child: TextButton(onPressed: _finish, child: Text('Skip', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600))),
          )),
          // Pages
          Expanded(child: PageView.builder(
            controller: _controller,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) => _buildPage(_pages[i]),
          )),
          // Indicators
          Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pages.length, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _current == i ? 28 : 8, height: 8,
              decoration: BoxDecoration(
                color: _current == i ? _pages[i].color : _pages[i].color.withAlpha(60),
                borderRadius: BorderRadius.circular(4),
              ),
            )),
          )),
          // Next / Get Started button
          Padding(padding: const EdgeInsets.fromLTRB(24, 0, 24, 32), child: SizedBox(
            width: double.infinity, height: 54,
            child: FilledButton(
              onPressed: _next,
              style: FilledButton.styleFrom(
                backgroundColor: _pages[_current].color,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(_current == _pages.length - 1 ? 'Get Started' : 'Next',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          )),
        ]),
      ),
    );
  }

  Widget _buildPage(_OnboardPage page) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 40), child: Column(
      mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(padding: const EdgeInsets.all(32), decoration: BoxDecoration(
          color: page.color.withAlpha(20), shape: BoxShape.circle,
          border: Border.all(color: page.color.withAlpha(40), width: 2),
        ), child: Icon(page.icon, size: 72, color: page.color)),
        const SizedBox(height: 40),
        Text(page.title, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: page.color), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Text(page.desc, style: TextStyle(fontSize: 15, color: Colors.grey.shade600, height: 1.5), textAlign: TextAlign.center),
      ],
    ));
  }
}

class _OnboardPage {
  final IconData icon;
  final Color color;
  final String title;
  final String desc;
  const _OnboardPage({required this.icon, required this.color, required this.title, required this.desc});
}
