import 'package:flutter_test/flutter_test.dart';
import 'package:laporkita/main.dart';

void main() {
  testWidgets('LaporKita app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LaporKitaApp());
    expect(find.text('LaporKita Design System Ready'), findsOneWidget);
  });
}
