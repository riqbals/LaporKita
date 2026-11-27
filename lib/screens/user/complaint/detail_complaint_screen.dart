import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/complaint_model.dart';
import '../../../services/complaint_service.dart';
import '../../../widgets/complaint_photo_gallery.dart';
import '../../../widgets/status_badge.dart';

/// Halaman detail pengaduan untuk User, termasuk tanggapan admin dan aksi batalkan.
class DetailComplaintScreen extends StatefulWidget {
  const DetailComplaintScreen({
    super.key,
    required this.complaint,
  });

  final ComplaintModel complaint;

  @override
  State<DetailComplaintScreen> createState() => _DetailComplaintScreenState();
}

class _DetailComplaintScreenState extends State<DetailComplaintScreen> {
  late final ComplaintService _complaintService = ComplaintService();
  bool _isDeleting = false;

  String _formatDate(DateTime? date) {
    if (date == null) return 'Baru saja';
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

  Future<void> _confirmCancel() async {
    final complaintId = widget.complaint.complaintId;
    if (complaintId == null || complaintId.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Pengaduan?'),
        content: const Text(
          'Pengaduan berstatus Menunggu akan dihapus secara permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await _complaintService.deleteMyComplaint(complaintId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengaduan berhasil dibatalkan.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membatalkan pengaduan: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final complaint = widget.complaint;
    final textTheme = Theme.of(context).textTheme;
    final canCancel = complaint.status == ComplaintModel.statusMenunggu;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pengaduan'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (complaint.allImages.isNotEmpty)
            ComplaintPhotoGallery(imageUrls: complaint.allImages),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  complaint.title,
                  style: textTheme.titleLarge,
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(status: complaint.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${complaint.categoryName} • ${_formatDate(complaint.createdAt)}',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          _InfoTile(
            icon: Icons.location_on_outlined,
            label: 'Lokasi',
            value: complaint.locationAddress,
          ),
          const SizedBox(height: 12),
          _InfoTile(
            icon: Icons.description_outlined,
            label: 'Deskripsi',
            value: complaint.description,
          ),
          if (complaint.adminResponse.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primarySoft.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primarySoft),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tanggapan Petugas',
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(complaint.adminResponse, style: textTheme.bodyMedium),
                ],
              ),
            ),
          ],
          if (canCancel) ...[
            const SizedBox(height: 28),
            OutlinedButton.icon(
              onPressed: _isDeleting ? null : _confirmCancel,
              icon: _isDeleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline),
              label: const Text('Batalkan / Hapus Pengaduan'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                minimumSize: const Size(double.infinity, 48),
                shape: const StadiumBorder(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primaryDark),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(value, style: textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
