import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/utils/form_validators.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/primary_button.dart';
import 'widgets/auth_footer_link.dart';

/// Halaman registrasi akun baru (Masyarakat / Admin).
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

  String _selectedRole = UserModel.roleUser;
  bool _roleInitialized = false;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_roleInitialized) {
      final arg = ModalRoute.of(context)?.settings.arguments;
      if (arg is String &&
          (arg == UserModel.roleUser || arg == UserModel.roleAdmin)) {
        _selectedRole = arg;
      }
      _roleInitialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final user = await _authService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
      );

      if (user == null) {
        throw Exception('Gagal mendapatkan data pengguna.');
      }

      if (!mounted) return;

      final targetRoute = _selectedRole == UserModel.roleAdmin
          ? AppRoutes.dashboardAdmin
          : AppRoutes.homeUser;

      Navigator.pushNamedAndRemoveUntil(
        context,
        targetRoute,
        (route) => false,
      );
    } catch (e) {
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
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment<String>(
                        value: UserModel.roleUser,
                        label: Text('Masyarakat'),
                        icon: Icon(Icons.person_outline),
                      ),
                      ButtonSegment<String>(
                        value: UserModel.roleAdmin,
                        label: Text('Admin'),
                        icon: Icon(Icons.admin_panel_settings_outlined),
                      ),
                    ],
                    selected: {_selectedRole},
                    onSelectionChanged: (selection) {
                      setState(() => _selectedRole = selection.first);
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected)
                            ? AppColors.primarySoft
                            : AppColors.surface,
                      ),
                      foregroundColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected)
                            ? AppColors.primaryDark
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
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
