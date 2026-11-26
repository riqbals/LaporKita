import 'package:flutter_test/flutter_test.dart';
import 'package:laporkita/main.dart';
import 'package:laporkita/widgets/app_logo.dart';

void main() {
  testWidgets('LoginScreen renders and navigates to RegisterScreen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const LaporKitaApp());

    expect(find.byType(AppLogo), findsOneWidget);
    expect(find.text('Layanan Pengaduan Masyarakat'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);

    await tester.tap(find.text('Daftar di sini'));
    await tester.pumpAndSettle();

    expect(find.text('Daftar Akun'), findsOneWidget);
    expect(find.text('Daftar'), findsOneWidget);
  });
}
