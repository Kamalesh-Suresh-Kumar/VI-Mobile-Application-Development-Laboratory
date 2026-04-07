// Basic Flutter widget test for TimetableManagerApp.

import 'package:flutter_test/flutter_test.dart';

import 'package:miniproject_timetable_manager/main.dart';

void main() {
  testWidgets('App launches and shows title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TimetableManagerApp());
    await tester.pumpAndSettle();

    // Verify the app title is present.
    expect(find.text('TimeTable Manager'), findsOneWidget);
  });
}
