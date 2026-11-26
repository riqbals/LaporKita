
import 'package:flutter/material.dart';
import '../../../models/complaint_model.dart';
import '../../../services/complaint_service.dart';

class ComplaintHistoryScreen extends StatefulWidget {
  const ComplaintHistoryScreen({super.key});

  @override
  State<ComplaintHistoryScreen> createState() =>
      _ComplaintHistoryScreenState();
}

class _ComplaintHistoryScreenState
    extends State<ComplaintHistoryScreen> {
  final ComplaintService _complaintService =
      ComplaintService();

  late final Stream<List<ComplaintModel>> _complaintsStream;

  @override
  void initState() {
    super.initState();
    _complaintsStream =
        _complaintService.getMyComplaintsStream();
  }

  Color _statusColor(String status) {
    switch (status) {
      case ComplaintModel.statusMenunggu:
        return Colors.orange;
      case ComplaintModel.statusDiproses:
        return Colors.blue;
      case ComplaintModel.statusSelesai:
        return Colors.green;
      case ComplaintModel.statusDitolak:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Tanggal belum tersedia';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _showComplaintDetail(ComplaintModel complaint) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detail Pengaduan'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (complaint.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    complaint.imageUrl,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Text('Foto tidak dapat ditampilkan.'),
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                complaint.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('Kategori: ${complaint.categoryName}'),
              const SizedBox(height: 8),
              Text('Deskripsi: ${complaint.description}'),
              const SizedBox(height: 8),
              Text('Lokasi: ${complaint.locationAddress}'),
              const SizedBox(height: 8),
              Text('Tanggal: ${_formatDate(complaint.createdAt)}'),
              const SizedBox(height: 8),
              Text('Status: ${complaint.status}'),
              if (complaint.adminResponse.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Tanggapan Admin:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(complaint.adminResponse),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Laporan'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<ComplaintModel>>(
        stream: _complaintsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Gagal mengambil riwayat laporan:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final complaints = snapshot.data ?? [];

          if (complaints.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 70,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Belum ada laporan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Laporan yang kamu buat akan muncul di sini.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              final complaint = complaints[index];
              final statusColor =
                  _statusColor(complaint.status);

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () =>
                      _showComplaintDetail(complaint),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(8),
                          child: SizedBox(
                            width: 95,
                            height: 105,
                            child: complaint.imageUrl.isNotEmpty
                                ? Image.network(
                                    complaint.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (
                                      context,
                                      error,
                                      stackTrace,
                                    ) =>
                                        const Icon(
                                      Icons.broken_image,
                                      size: 35,
                                    ),
                                  )
                                : const Icon(
                                    Icons.image_not_supported,
                                    size: 35,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                complaint.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                complaint.categoryName,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                _formatDate(complaint.createdAt),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(20),
                                ),
                                child: Text(
                                  complaint.status,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
