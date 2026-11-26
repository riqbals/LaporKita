import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/complaint_model.dart';

/// Badge warna status pengaduan sesuai palet warna di PRD Section 4B.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    final (Color textColor, Color bgColor) = switch (status) {
      ComplaintModel.statusMenunggu => (
          AppColors.statusWaiting,
          AppColors.statusWaitingSoft,
        ),
      ComplaintModel.statusDiproses => (
          AppColors.statusInProgress,
          AppColors.statusInProgressSoft,
        ),
      ComplaintModel.statusSelesai => (
          AppColors.statusDone,
          AppColors.statusDoneSoft,
        ),
      ComplaintModel.statusDitolak => (
          AppColors.statusRejected,
          AppColors.statusRejectedSoft,
        ),
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
