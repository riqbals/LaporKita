import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../models/complaint_model.dart';
import '../../services/complaint_service.dart';
import '../../widgets/complaint_card.dart';
import 'detail_admin_screen.dart';

/// Dashboard Petugas (Admin) untuk memantau ringkasan dan daftar semua aduan.
class DashboardAdminScreen extends StatefulWidget {
  const DashboardAdminScreen({super.key, this.initialComplaints});

  /// Opsional untuk pengujian UI tanpa Firebase.
  final List<ComplaintModel>? initialComplaints;

  @override
  State<DashboardAdminScreen> createState() => _DashboardAdminScreenState();
}

class _DashboardAdminScreenState extends State<DashboardAdminScreen> {
  late final Stream<List<ComplaintModel>> _complaintsStream;
  String? _selectedStatus;

  static const _filters = <String?>[
    null,
    ComplaintModel.statusMenunggu,
    ComplaintModel.statusDiproses,
    ComplaintModel.statusSelesai,
    ComplaintModel.statusDitolak,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialComplaints != null) {
      _complaintsStream = Stream.value(widget.initialComplaints!);
    } else if (Firebase.apps.isEmpty) {
      _complaintsStream = Stream.value(const []);
    } else {
      _complaintsStream = ComplaintService().getAllComplaintsStream();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Petugas'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
              borderRadius: BorderRadius.circular(20),
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primarySoft,
                child: Text(
                  'P',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<ComplaintModel>>(
        stream: _complaintsStream,
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
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      label: 'Menunggu',
                      count: allComplaints
                          .where(
                            (c) => c.status == ComplaintModel.statusMenunggu,
                          )
                          .length,
                      color: AppColors.statusWaiting,
                      backgroundColor: AppColors.statusWaitingSoft,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryCard(
                      label: 'Diproses',
                      count: allComplaints
                          .where(
                            (c) => c.status == ComplaintModel.statusDiproses,
                          )
                          .length,
                      color: AppColors.statusInProgress,
                      backgroundColor: AppColors.statusInProgressSoft,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryCard(
                      label: 'Selesai',
                      count: allComplaints
                          .where(
                            (c) => c.status == ComplaintModel.statusSelesai,
                          )
                          .length,
                      color: AppColors.statusDone,
                      backgroundColor: AppColors.statusDoneSoft,
                    ),
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
                        selectedColor: AppColors.primarySoft,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppColors.primaryDark
                              : AppColors.textSecondary,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          fontSize: 13,
                        ),
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
                  child: Center(
                    child: Text('Tidak ada pengaduan pada filter ini.'),
                  ),
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
    required this.backgroundColor,
  });

  final String label;
  final int count;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
