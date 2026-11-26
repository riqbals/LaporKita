import 'package:flutter/material.dart';

import '../../core/constants/app_routes.dart';
import '../../core/utils/form_validators.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/primary_button.dart';
import 'login_screen.dart';
import 'widgets/auth_footer_link.dart';

/// Halaman registrasi akun baru (role otomatis "masyarakat").
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  late final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ==========================================
  // REGISTRASI PENGGUNA
  // ==========================================

  Future<void> _handleRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      // Membuat akun baru.
      // Firebase otomatis membuat pengguna dalam keadaan login.
      final user = await _authService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: 'masyarakat',
      );

      if (user == null) {
        throw Exception('Gagal mendapatkan data pengguna.');
      }

      // Mengambil profil pengguna dari Firestore.
      final userDoc = await _authService.getUserData(user.uid);

      if (!userDoc.exists || userDoc.data() == null) {
        throw Exception('Profil pengguna tidak ditemukan.');
      }

      final userData = userDoc.data()!;
      final String name = userData['name'] ?? 'Pengguna';
      final String role = userData['role'] ?? 'masyarakat';

      if (!mounted) return;

      // Langsung masuk ke halaman utama.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => LoginSuccessScreen(
            name: name,
            role: role,
          ),
        ),
        (route) => false,
      );
    } catch (e, stackTrace) {
      debugPrint('REGISTRASI ERROR: $e');
      debugPrint('STACK TRACE: $stackTrace');

      if (!mounted) return;

      String message = 'Registrasi gagal. Silakan coba lagi.';

      if (e.toString().contains('email-already-in-use')) {
        message = 'Email sudah terdaftar.';
      } else if (e.toString().contains('weak-password')) {
        message = 'Password terlalu lemah.';
      } else if (e.toString().contains('invalid-email')) {
        message = 'Format email tidak valid.';
      } else if (e.toString().contains('permission-denied')) {
        message = 'Akses database ditolak. Periksa Firestore Rules.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _goToLogin() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: _goToLogin,
          icon: const Icon(Icons.arrow_back_outlined),
          tooltip: 'Kembali',
        ),
        title: const Text('Daftar Akun'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                CustomInput(
                  controller: _nameController,
                  hintText: 'Nama Lengkap',
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      FormValidators.requiredField(v, 'Nama lengkap'),
                ),
                const SizedBox(height: 16),
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
                  textInputAction: TextInputAction.next,
                  validator: FormValidators.password,
                ),
                const SizedBox(height: 16),
                CustomInput(
                  controller: _confirmPasswordController,
                  hintText: 'Konfirmasi Kata Sandi',
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  validator: (v) => FormValidators.confirmPassword(
                    v,
                    _passwordController.text,
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Daftar',
                  isLoading: _isLoading,
                  onPressed: _handleRegister,
                ),
                const SizedBox(height: 40),
                AuthFooterLink(
                  promptText: 'Sudah punya akun? ',
                  actionText: 'Masuk',
                  onTap: _goToLogin,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
