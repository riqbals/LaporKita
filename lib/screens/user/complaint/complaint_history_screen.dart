import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/complaint_model.dart';
import '../../../services/complaint_service.dart';
import '../../../widgets/status_badge.dart';

class ComplaintHistoryScreen extends StatefulWidget {
  const ComplaintHistoryScreen({super.key, this.initialComplaints});

  /// Opsional untuk pengujian UI tanpa Firebase.
  final List<ComplaintModel>? initialComplaints;

  @override
  State<ComplaintHistoryScreen> createState() => _ComplaintHistoryScreenState();
}

class _ComplaintHistoryScreenState extends State<ComplaintHistoryScreen> {
  static const List<String> _statusFilters = [
    'Semua',
    ComplaintModel.statusMenunggu,
    ComplaintModel.statusDiproses,
    ComplaintModel.statusSelesai,
    ComplaintModel.statusDitolak,
  ];

  late final Stream<List<ComplaintModel>> _complaintsStream;
  String _selectedStatus = 'Semua';

  @override
  void initState() {
    super.initState();
    if (widget.initialComplaints != null) {
      _complaintsStream = Stream.value(widget.initialComplaints!);
    } else if (Firebase.apps.isEmpty) {
      _complaintsStream = Stream.value(const []);
    } else {
      _complaintsStream = ComplaintService().getMyComplaintsStream();
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Tanggal belum tersedia';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _confirmAndCancelComplaint(ComplaintModel complaint) async {
    final complaintId = complaint.complaintId;
    if (complaintId == null || complaintId.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _CancelConfirmationDialog(),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ComplaintService().deleteMyComplaint(complaintId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengaduan berhasil dibatalkan.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membatalkan pengaduan: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showComplaintDetail(ComplaintModel complaint) {
    final canCancel =
        complaint.status == ComplaintModel.statusMenunggu &&
        (complaint.complaintId?.isNotEmpty ?? false);

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Detail Pengaduan'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (complaint.imageUrl.isNotEmpty) ...[
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
              ],
              StatusBadge(status: complaint.status),
              const SizedBox(height: 10),
              Text(
                complaint.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('Kategori: ${complaint.categoryName}'),
              const SizedBox(height: 6),
              Text('Deskripsi: ${complaint.description}'),
              const SizedBox(height: 6),
              Text('Lokasi: ${complaint.locationAddress}'),
              const SizedBox(height: 6),
              Text('Tanggal: ${_formatDate(complaint.createdAt)}'),
              if (complaint.adminResponse.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Tanggapan Admin:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(complaint.adminResponse),
              ],
            ],
          ),
        ),
        actions: [
          if (canCancel)
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _confirmAndCancelComplaint(complaint);
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Batalkan Pengaduan'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Laporan'), centerTitle: true),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _statusFilters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final status = _statusFilters[index];
                final isSelected = _selectedStatus == status;
                return ChoiceChip(
                  label: Text(status),
                  selected: isSelected,
                  selectedColor: AppColors.primarySoft,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? AppColors.primaryDark
                        : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 13,
                  ),
                  onSelected: (_) => setState(() => _selectedStatus = status),
                );
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ComplaintModel>>(
              stream: _complaintsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
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

                final allComplaints = snapshot.data ?? [];
                final complaints = _selectedStatus == 'Semua'
                    ? allComplaints
                    : allComplaints
                          .where((c) => c.status == _selectedStatus)
                          .toList();

                if (complaints.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.inbox_outlined,
                          size: 70,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _selectedStatus == 'Semua'
                              ? 'Belum ada laporan'
                              : 'Belum ada laporan "$_selectedStatus"',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Laporan yang Anda buat akan muncul di sini.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: complaints.length,
                  itemBuilder: (context, index) {
                    final complaint = complaints[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => _showComplaintDetail(complaint),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 95,
                                  height: 105,
                                  child: complaint.imageUrl.isNotEmpty
                                      ? Image.network(
                                          complaint.imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                    StatusBadge(status: complaint.status),
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
          ),
        ],
      ),
    );
  }
}

/// Dialog konfirmasi pembatalan pengaduan dengan countdown 5 detik.
class _CancelConfirmationDialog extends StatefulWidget {
  const _CancelConfirmationDialog();

  @override
  State<_CancelConfirmationDialog> createState() =>
      _CancelConfirmationDialogState();
}

class _CancelConfirmationDialogState extends State<_CancelConfirmationDialog> {
  int _secondsRemaining = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
      } else {
        setState(() => _secondsRemaining -= 1);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = _secondsRemaining > 0;

    return AlertDialog(
      title: const Text('Batalkan Pengaduan?'),
      content: const Text(
        'Pengaduan yang dibatalkan akan dihapus permanen dan tidak dapat dipulihkan.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Kembali'),
        ),
        ElevatedButton(
          onPressed: isLocked ? null : () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 42),
          ),
          child: Text(
            isLocked ? 'Ya, Batalkan (${_secondsRemaining}s)' : 'Ya, Batalkan',
          ),
        ),
      ],
    );
  }
}
