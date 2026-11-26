import 'package:flutter/material.dart';

import '../../core/constants/app_routes.dart';
import '../../core/utils/form_validators.dart';
import '../../services/auth_service.dart';
import '../../services/category_service.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/primary_button.dart';
import '../user/complaint/complaint_history_screen.dart';
import '../user/complaint/create_complaint_screen.dart';
import 'widgets/auth_footer_link.dart';

/// Halaman Login untuk Masyarakat (User) dan Petugas (Admin).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final user = await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (user == null) {
        throw Exception('Pengguna tidak ditemukan.');
      }

      final userSnapshot = await _authService.getUserData(user.uid);

      if (!userSnapshot.exists) {
        throw Exception('Data profil pengguna tidak ditemukan.');
      }

      final userData = userSnapshot.data();

      if (userData == null) {
        throw Exception('Data profil pengguna kosong.');
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoginSuccessScreen(
            name: userData['name'] ?? 'Pengguna',
            role: userData['role'] ?? 'masyarakat',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login gagal: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Form(
              key: _formKey,
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
                  const SizedBox(height: 32),
                  CustomInput(
                    controller: _emailController,
                    hintText: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: FormValidators.email,
                  ),
                  const SizedBox(height: 16),
                  CustomInput(
                    controller: _passwordController,
                    hintText: 'Kata Sandi',
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    validator: FormValidators.password,
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Masuk',
                    isLoading: _isLoading,
                    onPressed: _handleLogin,
                  ),
                  const SizedBox(height: 48),
                  AuthFooterLink(
                    promptText: 'Belum punya akun? ',
                    actionText: 'Daftar di sini',
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.register),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// HALAMAN LOGIN BERHASIL
// ==========================================

class LoginSuccessScreen extends StatefulWidget {
  final String name;
  final String role;

  const LoginSuccessScreen({
    super.key,
    required this.name,
    required this.role,
  });

  @override
  State<LoginSuccessScreen> createState() => _LoginSuccessScreenState();
}

class _LoginSuccessScreenState extends State<LoginSuccessScreen> {
  final AuthService _authService = AuthService();
  final CategoryService _categoryService = CategoryService();

  late Future<List<Map<String, dynamic>>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() {
    _categoriesFuture = _categoryService.getActiveCategories();
  }

  Future<void> _logout() async {
    try {
      await _authService.logout();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout gagal: $e')),
      );
    }
  }

  void _openComplaintForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateComplaintScreen(),
      ),
    );
  }

  // NAVIGASI KE RIWAYAT LAPORAN
  void _openComplaintHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ComplaintHistoryScreen(),
      ),
    );
  }

  void _openCategory(Map<String, dynamic> category) {
    if (widget.role != 'masyarakat') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Fitur pengaduan hanya tersedia untuk masyarakat.',
          ),
        ),
      );
      return;
    }

    _openComplaintForm();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LaporKita'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 70,
                ),
                const SizedBox(height: 16),
                Text(
                  'Selamat datang, ${widget.name}!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Role: ${widget.role}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Login berhasil.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'Daftar Kategori Pengaduan',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _categoriesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Column(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 40,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Gagal mengambil kategori: ${snapshot.error}',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(_loadCategories);
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Coba Lagi'),
                          ),
                        ],
                      );
                    }

                    final categories = snapshot.data ?? [];

                    if (categories.isEmpty) {
                      return const Center(
                        child: Text(
                          'Belum ada kategori yang tersedia.',
                        ),
                      );
                    }

                    return Column(
                      children: [
                        Text(
                          'Jumlah kategori: ${categories.length}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...categories.map((category) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => _openCategory(category),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.category,
                                      color: Colors.blue,
                                      size: 28,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            category['name'] ?? 'Tanpa nama',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            category['description'] ??
                                                'Tidak ada deskripsi',
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),

                // TOMBOL UNTUK MASYARAKAT
                if (widget.role == 'masyarakat') ...[
                  ElevatedButton.icon(
                    onPressed: _openComplaintForm,
                    icon: const Icon(Icons.add),
                    label: const Text('Buat Pengaduan'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _openComplaintHistory,
                    icon: const Icon(Icons.history),
                    label: const Text('Riwayat Laporan'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
