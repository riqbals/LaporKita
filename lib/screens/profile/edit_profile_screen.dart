import 'package:flutter/material.dart';

import '../../core/utils/form_validators.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/primary_button.dart';

/// Halaman ubah profil (`name` dan `phone` sesuai RBAC PRD).
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  late final AuthService _authService = AuthService();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  Future<void> _loadCurrentProfile() async {
    try {
      final profile = await _authService.getCurrentUserProfile();
      if (!mounted) return;
      if (profile != null) {
        _nameController.text = profile.name;
        _phoneController.text = profile.phone;
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    try {
      await _authService.updateProfile(
        name: _nameController.text,
        phone: _phoneController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui profil: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    CustomInput(
                      controller: _nameController,
                      labelText: 'Nama Lengkap',
                      hintText: 'Masukkan nama lengkap',
                      validator: (v) =>
                          FormValidators.requiredField(v, 'Nama lengkap'),
                    ),
                    const SizedBox(height: 16),
                    CustomInput(
                      controller: _phoneController,
                      labelText: 'Nomor Telepon',
                      hintText: 'Contoh: 08123456789',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Simpan Perubahan',
                      isLoading: _isSaving,
                      onPressed: _saveProfile,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
