import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Link navigasi di bagian bawah halaman Auth (mis. "Belum punya akun? Daftar di sini").
class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({
    super.key,
    required this.promptText,
    required this.actionText,
    required this.onTap,
  });

  final String promptText;
  final String actionText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.primaryDark,
        );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(promptText, style: textStyle),
        GestureDetector(
          onTap: onTap,
          child: Text(
            actionText,
            style: textStyle?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
