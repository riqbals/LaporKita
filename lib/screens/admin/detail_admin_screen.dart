import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/complaint_model.dart';
import '../../services/complaint_service.dart';
import '../../widgets/complaint_photo_gallery.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/status_badge.dart';

/// Halaman detail & penanganan aduan oleh Admin sesuai State Machine PRD.
class DetailAdminScreen extends StatefulWidget {
  const DetailAdminScreen({
    super.key,
    required this.complaint,
  });

  final ComplaintModel complaint;

  @override
  State<DetailAdminScreen> createState() => _DetailAdminScreenState();
}

class _DetailAdminScreenState extends State<DetailAdminScreen> {
  late final ComplaintService _complaintService = ComplaintService();
  late final TextEditingController _responseController;
  String? _selectedNextStatus;
  bool _isSubmitting = false;

  List<String> get _allowedNextStatuses {
    return switch (widget.complaint.status) {
      ComplaintModel.statusMenunggu => const [
          ComplaintModel.statusDiproses,
          ComplaintModel.statusDitolak,
        ],
      ComplaintModel.statusDiproses => const [
          ComplaintModel.statusSelesai,
        ],
      _ => const [],
    };
  }

  @override
  void initState() {
    super.initState();
    _responseController =
        TextEditingController(text: widget.complaint.adminResponse);
    final options = _allowedNextStatuses;
    if (options.isNotEmpty) {
      _selectedNextStatus = options.first;
    }
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _submitUpdate() async {
    final complaintId = widget.complaint.complaintId;
    final nextStatus = _selectedNextStatus;
    if (complaintId == null || nextStatus == null) return;

    final responseText = _responseController.text.trim();
    if ((nextStatus == ComplaintModel.statusSelesai ||
            nextStatus == ComplaintModel.statusDitolak) &&
        responseText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tanggapan admin wajib diisi untuk status Selesai atau Ditolak.',
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _complaintService.updateComplaintStatus(
        complaintId: complaintId,
        newStatus: nextStatus,
        adminResponse: responseText,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status pengaduan berhasil diperbarui.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui status: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final complaint = widget.complaint;
    final textTheme = Theme.of(context).textTheme;
    final nextOptions = _allowedNextStatuses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tindak Lanjut Aduan'),
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
                child: Text(complaint.title, style: textTheme.titleLarge),
              ),
              const SizedBox(width: 8),
              StatusBadge(status: complaint.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Pelapor: ${complaint.userName} • ${complaint.categoryName}',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Text('Lokasi: ${complaint.locationAddress}', style: textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(complaint.description, style: textTheme.bodyMedium),
          const Divider(height: 32),
          if (nextOptions.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status Final (${complaint.status})',
                      style: textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    complaint.adminResponse.isNotEmpty
                        ? complaint.adminResponse
                        : 'Tidak ada tanggapan tambahan.',
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          else ...[
            Text('Ubah Status', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedNextStatus,
              items: nextOptions
                  .map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Text(status),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedNextStatus = value);
              },
            ),
            const SizedBox(height: 16),
            Text('Tanggapan Resmi Petugas', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            CustomInput(
              controller: _responseController,
              hintText: 'Tulis tindak lanjut atau alasan penolakan...',
              maxLines: 4,
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Simpan Perubahan',
              isLoading: _isSubmitting,
              onPressed: _submitUpdate,
            ),
          ],
        ],
      ),
    );
  }
}
