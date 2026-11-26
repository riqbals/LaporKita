import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_enums.dart';
import '../../core/constants/app_routes.dart';
import '../../widgets/app_logo.dart';

/// Halaman pemilihan persona (Warga atau Petugas/Admin) sebelum masuk ke Login.
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  void _navigateToLogin(BuildContext context, UserRole role) {
    Navigator.pushNamed(context, AppRoutes.login, arguments: role);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLogo(width: 150),
                const SizedBox(height: 6),
                Text(
                  'Layanan Pengaduan Masyarakat',
                  style: textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Pilih Peran Masuk',
                    style: textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 12),
                _RoleOptionCard(
                  icon: Icons.person_outlined,
                  title: 'Warga',
                  subtitle: 'Laporkan keluhan & pantau progres aduan',
                  onTap: () => _navigateToLogin(context, UserRole.user),
                ),
                const SizedBox(height: 12),
                _RoleOptionCard(
                  icon: Icons.admin_panel_settings_outlined,
                  title: 'Petugas / Admin',
                  subtitle: 'Kelola, verifikasi, dan tanggapi laporan warga',
                  onTap: () => _navigateToLogin(context, UserRole.admin),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleOptionCard extends StatelessWidget {
  const _RoleOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primaryDark, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(subtitle, style: textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_outlined,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
