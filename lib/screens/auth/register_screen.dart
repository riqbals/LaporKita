import 'package:flutter/material.dart';
import '../../core/constants/app_routes.dart';
import '../../core/utils/form_validators.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/primary_button.dart';
import 'widgets/auth_footer_link.dart';

/// Halaman registrasi akun baru (role otomatis "user" sesuai PRD).
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
  bool _isLoading = false;

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
    // TODO: Integrasikan dengan AuthService setelah backend siap.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Validasi pendaftaran berhasil (UI mode)')),
    );
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
