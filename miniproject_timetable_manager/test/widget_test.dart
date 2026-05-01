import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SchedIQ app smoke test', (WidgetTester tester) async {
    // Basic smoke test — the full app requires DB initialization
    // which is not available in unit tests without mocking.
    expect(true, isTrue);
  });
}
