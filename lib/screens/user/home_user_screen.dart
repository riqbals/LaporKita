import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../models/complaint_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/complaint_service.dart';
import '../../widgets/complaint_card.dart';
import 'complaint/detail_complaint_screen.dart';

/// Beranda Masyarakat (User) dengan daftar aduan pribadi real-time.
class HomeUserScreen extends StatefulWidget {
  const HomeUserScreen({super.key});

  @override
  State<HomeUserScreen> createState() => _HomeUserScreenState();
}

class _HomeUserScreenState extends State<HomeUserScreen> {
  late final AuthService _authService = AuthService();
  late final ComplaintService _complaintService = ComplaintService();

  UserModel? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _authService.getCurrentUserProfile();
      if (!mounted) return;
      setState(() => _profile = profile);
    } catch (_) {
      // Abaikan jika gagal memuat nama; fallback ke teks default.
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LaporKita'),
        actions: [
          IconButton(
            tooltip: 'FAQ',
            icon: const Icon(Icons.help_outline),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.faq),
          ),
          IconButton(
            tooltip: 'Profil',
            icon: const Icon(Icons.person_outline),
            onPressed: () async {
              await Navigator.pushNamed(context, AppRoutes.profile);
              _loadProfile();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.pushNamed(context, AppRoutes.createComplaint),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Buat Aduan'),
      ),
      body: StreamBuilder<List<ComplaintModel>>(
        stream: _complaintService.getMyComplaintsStream(),
        builder: (context, snapshot) {
          final complaints = snapshot.data ?? [];

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, ${_profile?.name.isNotEmpty == true ? _profile!.name : 'Warga'}!',
                      style: textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pantau status pengaduan Anda secara real-time.',
                      style: textTheme.bodySmall,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _StatMini(
                          label: 'Menunggu',
                          count: complaints
                              .where(
                                (c) => c.status == ComplaintModel.statusMenunggu,
                              )
                              .length,
                          color: AppColors.statusWaiting,
                        ),
                        const SizedBox(width: 8),
                        _StatMini(
                          label: 'Diproses',
                          count: complaints
                              .where(
                                (c) => c.status == ComplaintModel.statusDiproses,
                              )
                              .length,
                          color: AppColors.statusInProgress,
                        ),
                        const SizedBox(width: 8),
                        _StatMini(
                          label: 'Selesai',
                          count: complaints
                              .where(
                                (c) => c.status == ComplaintModel.statusSelesai,
                              )
                              .length,
                          color: AppColors.statusDone,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('Aduan Saya', style: textTheme.titleMedium),
              const SizedBox(height: 12),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (snapshot.hasError)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    'Gagal memuat pengaduan: ${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                )
              else if (complaints.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Belum ada pengaduan',
                        style: textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tekan tombol "Buat Aduan" untuk mengirim laporan baru.',
                        style: textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ...complaints.map(
                  (complaint) => ComplaintCard(
                    complaint: complaint,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            DetailComplaintScreen(complaint: complaint),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StatMini extends StatelessWidget {
  const _StatMini({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
