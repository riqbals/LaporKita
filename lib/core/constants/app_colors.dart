import 'package:flutter/material.dart';

/// Palet warna terpusat untuk aplikasi LaporKita.
/// Mengacu pada wireframe UI serta status aduan di PRD.
abstract final class AppColors {
  // Brand & Action
  static const Color primary = Color(0xFF4285F4);
  static const Color primaryDark = Color(0xFF1A56DB);
  static const Color primarySoft = Color(0xFFCCE0FF);

  // Neutral & Surface
  static const Color background = Color(0xF7F7F5FF);
  static const Color surface = Color(0xFFF8FAFC);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFD1D5DB);
  static const Color divider = Color(0xFFE5E7EB);

  // Semantic
  static const Color error = Color(0xFFDC2626);
  static const Color errorSoft = Color(0xFFFEE2E2);
  static const Color success = Color(0xFF16A34A);
  static const Color successSoft = Color(0xFFDCFCE7);

  // Status Aduan (PRD Section 4B)
  static const Color statusWaiting = Color(0xFFD97706);
  static const Color statusWaitingSoft = Color(0xFFFEF3C7);

  static const Color statusInProgress = Color(0xFF2563EB);
  static const Color statusInProgressSoft = Color(0xFFDBEAFE);

  static const Color statusDone = Color(0xFF16A34A);
  static const Color statusDoneSoft = Color(0xFFDCFCE7);

  static const Color statusRejected = Color(0xFFDC2626);
  static const Color statusRejectedSoft = Color(0xFFFEE2E2);
}
