import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../models/complaint_model.dart';
import '../../services/complaint_service.dart';
import '../../widgets/complaint_card.dart';
import 'detail_admin_screen.dart';

/// Dashboard Petugas (Admin) untuk memantau ringkasan dan daftar semua aduan.
class DashboardAdminScreen extends StatefulWidget {
  const DashboardAdminScreen({super.key});

  @override
  State<DashboardAdminScreen> createState() => _DashboardAdminScreenState();
}

class _DashboardAdminScreenState extends State<DashboardAdminScreen> {
  late final ComplaintService _complaintService = ComplaintService();
  String? _selectedStatus;

  static const _filters = <String?>[
    null,
    ComplaintModel.statusMenunggu,
    ComplaintModel.statusDiproses,
    ComplaintModel.statusSelesai,
    ComplaintModel.statusDitolak,
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        actions: [
          IconButton(
            tooltip: 'Profil',
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
          ),
        ],
      ),
      body: StreamBuilder<List<ComplaintModel>>(
        stream: _complaintService.getAllComplaintsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Gagal memuat data admin:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final allComplaints = snapshot.data ?? [];
          final filtered = _selectedStatus == null
              ? allComplaints
              : allComplaints
                  .where((c) => c.status == _selectedStatus)
                  .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.2,
                children: [
                  _SummaryCard(
                    label: 'Menunggu',
                    count: allComplaints
                        .where((c) => c.status == ComplaintModel.statusMenunggu)
                        .length,
                    color: AppColors.statusWaiting,
                  ),
                  _SummaryCard(
                    label: 'Diproses',
                    count: allComplaints
                        .where((c) => c.status == ComplaintModel.statusDiproses)
                        .length,
                    color: AppColors.statusInProgress,
                  ),
                  _SummaryCard(
                    label: 'Selesai',
                    count: allComplaints
                        .where((c) => c.status == ComplaintModel.statusSelesai)
                        .length,
                    color: AppColors.statusDone,
                  ),
                  _SummaryCard(
                    label: 'Ditolak',
                    count: allComplaints
                        .where((c) => c.status == ComplaintModel.statusDitolak)
                        .length,
                    color: AppColors.statusRejected,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filters.map((status) {
                    final isSelected = _selectedStatus == status;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(status ?? 'Semua'),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() => _selectedStatus = status);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Daftar Pengaduan (${filtered.length})',
                style: textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              if (filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: Text('Tidak ada pengaduan pada filter ini.')),
                )
              else
                ...filtered.map(
                  (complaint) => ComplaintCard(
                    complaint: complaint,
                    showReporter: true,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailAdminScreen(complaint: complaint),
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
