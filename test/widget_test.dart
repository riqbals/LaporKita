import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laporkita/core/theme/app_theme.dart';
import 'package:laporkita/main.dart';
import 'package:laporkita/models/complaint_model.dart';
import 'package:laporkita/screens/admin/dashboard_admin_screen.dart';
import 'package:laporkita/screens/admin/detail_admin_screen.dart';
import 'package:laporkita/screens/user/complaint/complaint_history_screen.dart';
import 'package:laporkita/screens/user/complaint/create_complaint_screen.dart';
import 'package:laporkita/screens/user/home_user_screen.dart';
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

  testWidgets(
    'HomeUserScreen renders 3 nav items, 8 categories, and + Lapor button',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.lightTheme, home: const HomeUserScreen()),
      );

      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Riwayat'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);
      expect(find.text('Lapor'), findsOneWidget);

      expect(find.text('Infrastruktur & Fasilitas Umum'), findsOneWidget);
      expect(find.text('Kebersihan & Lingkungan'), findsOneWidget);
      expect(find.text('Transportasi & Lalu Lintas'), findsOneWidget);
      expect(find.text('Penerangan Jalan'), findsOneWidget);
      expect(find.text('Pelayanan Publik'), findsOneWidget);
      expect(find.text('Keamanan & Ketertiban'), findsOneWidget);
      expect(find.text('Sosial'), findsOneWidget);
      expect(find.text('Lainnya'), findsOneWidget);
    },
  );

  testWidgets(
    'CreateComplaintScreen shows char limits, 8 categories dropdown, and 0/5 photo counter',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CreateComplaintScreen(),
        ),
      );

      expect(find.text('Buat Pengaduan'), findsOneWidget);
      expect(find.text('0/50'), findsOneWidget);
      expect(find.text('0/500'), findsOneWidget);
      expect(find.text('0/150'), findsOneWidget);
      expect(
        find.text('Unggah maksimal 5 foto sebagai bukti pengaduan.'),
        findsOneWidget,
      );
      expect(
        find.text('Anda sudah menambahkan 0/5 foto'),
        findsOneWidget,
      );

      // Buka dropdown kategori & pastikan kategori dari Beranda tersedia
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      expect(find.text('Infrastruktur & Fasilitas Umum'), findsWidgets);
      expect(find.text('Penerangan Jalan'), findsWidgets);
    },
  );

  testWidgets(
    'ComplaintHistoryScreen filters status, opens detail popup, and enforces 5s cancel countdown',
    (WidgetTester tester) async {
      final dummyComplaints = [
        ComplaintModel(
          complaintId: 'c1',
          userId: 'u1',
          userName: 'Budi',
          title: 'Jalan berlubang',
          categoryId: 'infrastruktur',
          categoryName: 'Infrastruktur & Fasilitas Umum',
          description: 'Berlubang cukup dalam',
          locationAddress: 'Jl. Merdeka',
          status: ComplaintModel.statusMenunggu,
        ),
        ComplaintModel(
          complaintId: 'c2',
          userId: 'u1',
          userName: 'Budi',
          title: 'Lampu mati',
          categoryId: 'penerangan_jalan',
          categoryName: 'Penerangan Jalan',
          description: 'Gelap di malam hari',
          locationAddress: 'Gang Mawar',
          status: ComplaintModel.statusSelesai,
          adminResponse: 'Sudah diperbaiki',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ComplaintHistoryScreen(initialComplaints: dummyComplaints),
        ),
      );
      await tester.pumpAndSettle();

      // Filter chips tampil
      expect(find.text('Semua'), findsOneWidget);
      expect(find.text('Menunggu'), findsWidgets);
      expect(find.text('Diproses'), findsOneWidget);
      expect(find.text('Selesai'), findsWidgets);
      expect(find.text('Ditolak'), findsOneWidget);

      // Filter ke Selesai -> hanya Lampu mati yang tampil
      await tester.tap(find.widgetWithText(ChoiceChip, 'Selesai'));
      await tester.pumpAndSettle();
      expect(find.text('Lampu mati'), findsOneWidget);
      expect(find.text('Jalan berlubang'), findsNothing);

      // Buka detail Selesai -> tidak ada tombol Batalkan Pengaduan
      await tester.tap(find.text('Lampu mati'));
      await tester.pumpAndSettle();
      expect(find.text('Detail Pengaduan'), findsOneWidget);
      expect(find.text('Batalkan Pengaduan'), findsNothing);
      await tester.tap(find.text('Tutup'));
      await tester.pumpAndSettle();

      // Filter ke Menunggu -> buka detail -> ada tombol Batalkan Pengaduan
      await tester.tap(find.widgetWithText(ChoiceChip, 'Menunggu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Jalan berlubang'));
      await tester.pumpAndSettle();
      expect(find.text('Batalkan Pengaduan'), findsOneWidget);

      // Tap Batalkan Pengaduan -> muncul dialog konfirmasi dengan countdown 5 detik
      await tester.tap(find.text('Batalkan Pengaduan'));
      await tester.pumpAndSettle();
      expect(find.text('Ya, Batalkan (5s)'), findsOneWidget);

      // Tunggu 5 detik -> tombol aktif dengan teks 'Ya, Batalkan'
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('Ya, Batalkan'), findsOneWidget);
    },
  );

  testWidgets(
    'DashboardAdminScreen renders 3 summary cards, 5 status filters, and complaint list',
    (WidgetTester tester) async {
      final dummyComplaints = [
        ComplaintModel(
          complaintId: 'a1',
          userId: 'u1',
          userName: 'Budi Santoso',
          title: 'Jalan berlubang di Jl. Merdeka',
          categoryId: 'infrastruktur',
          categoryName: 'Infrastruktur & Fasilitas Umum',
          description: 'Berlubang',
          locationAddress: 'Jl. Merdeka',
          status: ComplaintModel.statusMenunggu,
        ),
        ComplaintModel(
          complaintId: 'a2',
          userId: 'u2',
          userName: 'Siti Rahma',
          title: 'Lampu jalan mati',
          categoryId: 'penerangan_jalan',
          categoryName: 'Penerangan Jalan',
          description: 'Gelap',
          locationAddress: 'Gang Mawar',
          status: ComplaintModel.statusDitolak,
          adminResponse: 'Lokasi di luar wilayah',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: DashboardAdminScreen(initialComplaints: dummyComplaints),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dashboard Petugas'), findsOneWidget);
      expect(find.text('Daftar Pengaduan (2)'), findsOneWidget);
      expect(find.text('Semua'), findsOneWidget);
      expect(find.text('Ditolak'), findsWidgets);

      // Filter Ditolak -> hanya 1 pengaduan
      await tester.tap(find.widgetWithText(ChoiceChip, 'Ditolak'));
      await tester.pumpAndSettle();
      expect(find.text('Daftar Pengaduan (1)'), findsOneWidget);
      expect(find.text('Lampu jalan mati'), findsOneWidget);
      expect(find.text('Jalan berlubang di Jl. Merdeka'), findsNothing);

      // Tap kartu untuk membuka DetailAdminScreen (Kelola Aduan)
      await tester.tap(find.text('Lampu jalan mati'));
      await tester.pumpAndSettle();
      expect(find.text('Kelola Aduan'), findsOneWidget);
      expect(find.text('Status Final (Ditolak)'), findsOneWidget);
    },
  );

  testWidgets(
    'DetailAdminScreen renders Kelola Aduan form for Menunggu complaint',
    (WidgetTester tester) async {
      final complaint = ComplaintModel(
        complaintId: 'a1',
        userId: 'u1',
        userName: 'Budi Santoso',
        title: 'Jalan berlubang di Jl. Merdeka',
        categoryId: 'infrastruktur',
        categoryName: 'Infrastruktur & Fasilitas Umum',
        description: 'Lubang besar membahayakan pengendara.',
        locationAddress: 'Jl. Merdeka No. 12, Bandung',
        status: ComplaintModel.statusMenunggu,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: DetailAdminScreen(complaint: complaint),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kelola Aduan'), findsOneWidget);
      expect(find.text('Foto Aduan'), findsOneWidget);
      expect(find.text('Pelapor: Budi Santoso'), findsOneWidget);
      expect(find.text('Jl. Merdeka No. 12, Bandung'), findsOneWidget);
      expect(find.text('Tindak Lanjut Petugas'), findsOneWidget);
      expect(find.text('Diproses'), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(find.text('Simpan Perubahan'), findsOneWidget);
    },
  );
}
