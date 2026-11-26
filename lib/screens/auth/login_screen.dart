import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_enums.dart';
import '../../core/constants/app_routes.dart';
import '../../core/utils/form_validators.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/primary_button.dart';
import 'widgets/auth_footer_link.dart';

/// Halaman Login untuk Masyarakat (User) dan Petugas (Admin).
/// Untuk persona [UserRole.admin], opsi pendaftaran disembunyikan sesuai PRD.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.role = UserRole.user});

  final UserRole role;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final AuthService _authService = AuthService();

  bool _isLoading = false;

  UserRole get _selectedRole {
    final arg = ModalRoute.of(context)?.settings.arguments;
    return arg is UserRole ? arg : widget.role;
  }

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
      final wantsAdmin = _selectedRole == UserRole.admin;

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
    final selectedRole = _selectedRole;
    final isAdmin = selectedRole == UserRole.admin;

    return Scaffold(
      appBar: Navigator.canPop(context)
          ? AppBar(
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_outlined),
                tooltip: 'Ganti peran',
              ),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppLogo(width: 150),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Masuk sebagai ${selectedRole.label}',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
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
                  if (isAdmin)
                    Text(
                      'Akun petugas dikelola oleh administrator sistem.',
                      style: textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    )
                  else
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
