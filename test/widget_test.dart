import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:estudio_forge/main.dart';

void main() {
  testWidgets('Smoke test EstudioForgeApp', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: EstudioForgeApp()));
    await tester.pumpAndSettle();

    // Verify app loads
    expect(find.text('Inicio'), findsOneWidget);
  });
}
