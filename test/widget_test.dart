import 'package:bus_conductor/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App boots to the splash screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: BusConductorApp()));
    await tester.pump();
    // Splash screen renders the brand name.
    expect(find.text('Bus Conductor'), findsOneWidget);
  });
}
