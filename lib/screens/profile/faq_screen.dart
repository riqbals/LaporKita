import 'package:flutter/material.dart';

/// Halaman FAQ statis mengenai penggunaan aplikasi LaporKita.
class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  static const _items = [
    (
      question: 'Bagaimana cara membuat pengaduan baru?',
      answer:
          'Masuk sebagai masyarakat, tekan tombol "Buat Aduan" di beranda, isi judul, pilih kategori, tulis deskripsi & alamat lengkap, lalu lampirkan foto bukti.',
    ),
    (
      question: 'Apa arti status Menunggu, Diproses, Selesai, dan Ditolak?',
      answer:
          'Menunggu berarti laporan baru dikirim dan belum ditinjau. Diproses berarti petugas sedang menindaklanjuti. Selesai atau Ditolak adalah status akhir disertai tanggapan resmi petugas.',
    ),
    (
      question: 'Apakah pengaduan bisa dibatalkan?',
      answer:
          'Ya, pengaduan dapat dibatalkan/dihapus selama statusnya masih "Menunggu". Jika sudah Diproses, Selesai, atau Ditolak, pengaduan tidak dapat dihapus.',
    ),
    (
      question: 'Apa ketentuan foto bukti pengaduan?',
      answer:
          'Foto wajib dilampirkan dengan ukuran maksimal 5 MB dan akan dikompresi otomatis sebelum diunggah.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQ & Bantuan'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = _items[index];
          return Card(
            child: ExpansionTile(
              title: Text(
                item.question,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                Text(
                  item.answer,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
