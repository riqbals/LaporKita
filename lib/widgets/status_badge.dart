import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// Badge warna status pengaduan sesuai palet warna di PRD Section 4B.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toLowerCase();
    final (Color textColor, Color bgColor) = switch (normalized) {
      'menunggu' || 'menunggu verifikasi' => (
        AppColors.statusWaiting,
        AppColors.statusWaitingSoft,
      ),
      'diproses' => (
        AppColors.statusInProgress,
        AppColors.statusInProgressSoft,
      ),
      'selesai' => (AppColors.statusDone, AppColors.statusDoneSoft),
      'ditolak' => (AppColors.statusRejected, AppColors.statusRejectedSoft),
      _ => (AppColors.textSecondary, AppColors.divider),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
