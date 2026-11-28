import 'package:flutter/material.dart';

/// Enum peran pengguna sesuai PRD Section 4A.
enum UserRole {
  user('user', 'Warga'),
  admin('admin', 'Petugas / Admin');

  const UserRole(this.value, this.label);

  final String value;
  final String label;
}

/// Representasi kategori pengaduan yang digunakan bersama di Beranda & Form Aduan.
class ComplaintCategoryItem {
  const ComplaintCategoryItem({
    required this.id,
    required this.title,
    required this.icon,
  });

  final String id;
  final String title;
  final IconData icon;
}

/// Daftar 8 kategori resmi pengaduan Masyarakat.
abstract final class AppCategories {
  static const List<ComplaintCategoryItem> items = [
    ComplaintCategoryItem(
      id: 'infrastruktur',
      title: 'Infrastruktur & Fasilitas Umum',
      icon: Icons.construction_outlined,
    ),
    ComplaintCategoryItem(
      id: 'kebersihan',
      title: 'Kebersihan & Lingkungan',
      icon: Icons.cleaning_services_outlined,
    ),
    ComplaintCategoryItem(
      id: 'transportasi',
      title: 'Transportasi & Lalu Lintas',
      icon: Icons.directions_bus_outlined,
    ),
    ComplaintCategoryItem(
      id: 'penerangan_jalan',
      title: 'Penerangan Jalan',
      icon: Icons.lightbulb_outlined,
    ),
    ComplaintCategoryItem(
      id: 'pelayanan_publik',
      title: 'Pelayanan Publik',
      icon: Icons.apartment_outlined,
    ),
    ComplaintCategoryItem(
      id: 'keamanan',
      title: 'Keamanan & Ketertiban',
      icon: Icons.shield_outlined,
    ),
    ComplaintCategoryItem(
      id: 'sosial',
      title: 'Sosial',
      icon: Icons.people_outline,
    ),
    ComplaintCategoryItem(
      id: 'lainnya',
      title: 'Lainnya',
      icon: Icons.more_horiz_outlined,
    ),
  ];

  /// Mencari ikon kategori berdasarkan [categoryId] atau [categoryName] agar
  /// konsisten dengan ikon pada Beranda User.
  static IconData iconFor({
    String categoryId = '',
    String categoryName = '',
  }) {
    final normalizedId = categoryId.trim().toLowerCase();
    final normalizedName =
        categoryName.trim().toLowerCase().replaceAll(' dan ', ' & ');

    for (final item in items) {
      if (normalizedId.isNotEmpty && item.id == normalizedId) {
        return item.icon;
      }
      if (normalizedName.isNotEmpty &&
          item.title.toLowerCase() == normalizedName) {
        return item.icon;
      }
    }
    return Icons.category_outlined;
  }
}
