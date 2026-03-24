import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:la_facu/main.dart';

void main() {
  testWidgets('Smoke test LaFacuApp', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: LaFacuApp()));
    await tester.pump(const Duration(milliseconds: 100));

    // Verify splash screen renders while the app initializes.
    expect(find.text('La Facu'), findsOneWidget);
  });
}
