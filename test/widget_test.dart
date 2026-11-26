import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laporkita/main.dart';
import 'package:laporkita/widgets/app_logo.dart';

void main() {
  testWidgets(
    'RoleSelection routes to Warga (with register) and Admin (login only)',
    (WidgetTester tester) async {
      await tester.pumpWidget(const LaporKitaApp());

      expect(find.byType(AppLogo), findsOneWidget);
      expect(find.text('Warga'), findsOneWidget);
      expect(find.text('Petugas / Admin'), findsOneWidget);

      // Pilih Warga -> harus ada opsi Daftar di sini -> bisa ke RegisterScreen
      await tester.tap(find.text('Warga'));
      await tester.pumpAndSettle();

      expect(find.text('Masuk sebagai Warga'), findsOneWidget);
      expect(find.text('Daftar di sini'), findsOneWidget);

      await tester.tap(find.text('Daftar di sini'));
      await tester.pumpAndSettle();
      expect(find.text('Daftar Akun'), findsOneWidget);

      // Kembali ke RoleSelection -> pilih Petugas / Admin -> tanpa opsi daftar
      await tester.tap(find.byIcon(Icons.arrow_back_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_back_outlined));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Petugas / Admin'));
      await tester.pumpAndSettle();

      expect(find.text('Masuk sebagai Petugas / Admin'), findsOneWidget);
      expect(find.text('Daftar di sini'), findsNothing);
    },
  );
}
