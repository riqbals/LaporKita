import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/utils/form_validators.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/primary_button.dart';
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

  String _selectedRole = UserModel.roleUser;
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
      final userData = userSnapshot.data();

      if (!userSnapshot.exists || userData == null) {
        await _authService.logout();
        throw Exception('Data profil pengguna tidak ditemukan.');
      }

      final actualRole = userData['role'] as String? ?? UserModel.roleUser;
      final isActualAdmin = actualRole == UserModel.roleAdmin;
      final wantsAdmin = _selectedRole == UserModel.roleAdmin;

      if (wantsAdmin && !isActualAdmin) {
        await _authService.logout();
        throw Exception(
          'Akun ini bukan akun Admin. Silakan masuk sebagai Masyarakat.',
        );
      }

      if (!wantsAdmin && isActualAdmin) {
        await _authService.logout();
        throw Exception(
          'Akun ini terdaftar sebagai Admin. Silakan pilih masuk sebagai Admin.',
        );
      }

      if (!mounted) return;

      final targetRoute = isActualAdmin
          ? AppRoutes.dashboardAdmin
          : AppRoutes.homeUser;

      Navigator.pushNamedAndRemoveUntil(
        context,
        targetRoute,
        (route) => false,
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
                  const SizedBox(height: 24),
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
                  const SizedBox(height: 40),
                  if (_selectedRole == UserModel.roleUser)
                    AuthFooterLink(
                      promptText: 'Belum punya akun? ',
                      actionText: 'Daftar di sini',
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.register),
                    )
                  else
                    Text(
                      'Akun Admin dibuat oleh pengelola sistem.',
                      style: textTheme.bodySmall,
                      textAlign: TextAlign.center,
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
