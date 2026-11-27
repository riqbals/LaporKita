import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/complaint_model.dart';
import '../../services/complaint_service.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/status_badge.dart';

/// Halaman detail & penanganan aduan oleh Admin sesuai State Machine PRD.
class DetailAdminScreen extends StatefulWidget {
  const DetailAdminScreen({super.key, required this.complaint});

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
      ComplaintModel.statusDiproses => const [ComplaintModel.statusSelesai],
      _ => const [],
    };
  }

  @override
  void initState() {
    super.initState();
    _responseController = TextEditingController(
      text: widget.complaint.adminResponse,
    );
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
      appBar: AppBar(title: const Text('Kelola Aduan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: complaint.imageUrl.isNotEmpty
                ? Image.network(
                    complaint.imageUrl,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _photoPlaceholder(),
                  )
                : _photoPlaceholder(),
          ),
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
          Text('Pelapor: ${complaint.userName}', style: textTheme.bodySmall),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                complaint.categoryName,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: AppColors.error,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  complaint.locationAddress,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
                  Text(
                    'Status Final (${complaint.status})',
                    style: textTheme.titleMedium,
                  ),
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
            Text('Tindak Lanjut Petugas', style: textTheme.titleMedium),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedNextStatus,
              decoration: const InputDecoration(hintText: 'Ubah Status'),
              items: nextOptions
                  .map(
                    (status) =>
                        DropdownMenuItem(value: status, child: Text(status)),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedNextStatus = value);
              },
            ),
            const SizedBox(height: 16),
            CustomInput(
              controller: _responseController,
              hintText: 'Catatan Tanggapan Resmi',
              maxLines: 4,
              maxLength: 500,
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

  Widget _photoPlaceholder() {
    return Container(
      height: 180,
      width: double.infinity,
      color: AppColors.divider,
      alignment: Alignment.center,
      child: const Text(
        'Foto Aduan',
        style: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}
