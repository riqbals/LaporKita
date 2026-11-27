import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_enums.dart';
import '../../core/constants/app_routes.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../profile/profile_screen.dart';
import 'complaint/complaint_history_screen.dart';

/// Beranda Masyarakat (User) dengan 3 tab navigasi: Beranda, Riwayat, dan Profil.
class HomeUserScreen extends StatefulWidget {
  const HomeUserScreen({super.key});

  @override
  State<HomeUserScreen> createState() => _HomeUserScreenState();
}

class _HomeUserScreenState extends State<HomeUserScreen> {
  int _currentIndex = 0;
  UserModel? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (Firebase.apps.isEmpty) return;
    try {
      final profile = await AuthService().getCurrentUserProfile();
      if (!mounted) return;
      setState(() => _profile = profile);
    } catch (_) {
      // Abaikan jika gagal memuat nama; fallback ke teks default.
    }
  }

  void _openCreateComplaint([String? categoryTitle]) {
    Navigator.pushNamed(
      context,
      AppRoutes.createComplaint,
      arguments: categoryTitle,
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _CitizenHomeTab(
          userName: _profile?.name ?? '',
          categories: AppCategories.items,
          onFaqTap: () => Navigator.pushNamed(context, AppRoutes.faq),
          onAvatarTap: () => setState(() => _currentIndex = 2),
          onCategoryTap: (category) => _openCreateComplaint(category.title),
        );
      case 1:
        return const ComplaintHistoryScreen();
      case 2:
        return const ProfileScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      floatingActionButton: _currentIndex == 2
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openCreateComplaint(),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Lapor'),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: AppColors.background,
        indicatorColor: AppColors.primarySoft,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          if (index == 0) _loadProfile();
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.primaryDark),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history, color: AppColors.primaryDark),
            label: 'Riwayat',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.primaryDark),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class _CitizenHomeTab extends StatelessWidget {
  const _CitizenHomeTab({
    required this.userName,
    required this.categories,
    required this.onFaqTap,
    required this.onAvatarTap,
    required this.onCategoryTap,
  });

  final String userName;
  final List<ComplaintCategoryItem> categories;
  final VoidCallback onFaqTap;
  final VoidCallback onAvatarTap;
  final ValueChanged<ComplaintCategoryItem> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final trimmedName = userName.trim();
    final greetingText = trimmedName.isNotEmpty ? 'Halo, $trimmedName' : 'Halo!';

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(greetingText, style: textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Pilih kategori pengaduan Anda',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'FAQ',
                onPressed: onFaqTap,
                icon: const Icon(
                  Icons.info_outline,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: onAvatarTap,
                borderRadius: BorderRadius.circular(20),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primarySoft,
                  child: trimmedName.isNotEmpty
                      ? Text(
                          trimmedName[0].toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : const Icon(
                          Icons.person_outline,
                          color: AppColors.primaryDark,
                          size: 20,
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Kategori Pengaduan', style: textTheme.titleMedium),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.18,
            ),
            itemBuilder: (context, index) {
              final item = categories[index];
              return _CategoryCard(
                item: item,
                onTap: () => onCategoryTap(item),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.item, required this.onTap});

  final ComplaintCategoryItem item;
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
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, color: AppColors.primaryDark, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
