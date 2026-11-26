import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/utils/form_validators.dart';
import '../../../models/complaint_model.dart';
import '../../../services/category_service.dart';
import '../../../services/complaint_service.dart';
import '../../../widgets/primary_button.dart';

class CreateComplaintScreen extends StatefulWidget {
  const CreateComplaintScreen({super.key, this.initialCategoryTitle});

  final String? initialCategoryTitle;

  @override
  State<CreateComplaintScreen> createState() => _CreateComplaintScreenState();
}

class _CreateComplaintScreenState extends State<CreateComplaintScreen> {
  static const int _maxTitleLength = 50;
  static const int _maxDescriptionLength = 500;
  static const int _maxLocationLength = 150;
  static const int _maxPhotos = 5;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _imagePicker = ImagePicker();

  final List<Uint8List> _selectedImages = [];
  List<Map<String, String>> _categories = AppCategories.items
      .map((item) => {'id': item.id, 'name': item.title})
      .toList();

  String? _selectedCategoryId;
  String? _selectedCategoryName;
  bool _didApplyRouteArg = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didApplyRouteArg) return;
    _didApplyRouteArg = true;

    final arg = ModalRoute.of(context)?.settings.arguments;
    final preselectedTitle =
        arg is String ? arg : widget.initialCategoryTitle;
    if (preselectedTitle != null && preselectedTitle.isNotEmpty) {
      _applyCategorySelectionByName(preselectedTitle);
    }
  }

  void _applyCategorySelectionByName(String categoryTitle) {
    final match = _categories.where(
      (cat) => cat['name']?.toLowerCase() == categoryTitle.toLowerCase(),
    );
    if (match.isNotEmpty) {
      _selectedCategoryId = match.first['id'];
      _selectedCategoryName = match.first['name'];
    }
  }

  Future<void> _loadCategories() async {
    if (Firebase.apps.isEmpty) return;
    try {
      final remote = await CategoryService().getActiveCategories();
      if (!mounted || remote.isEmpty) return;

      final mapped = remote
          .map((cat) => {
                'id': cat['id']?.toString() ?? '',
                'name': cat['name']?.toString() ?? '',
              })
          .where((cat) => cat['id']!.isNotEmpty && cat['name']!.isNotEmpty)
          .toList();

      if (mapped.isEmpty) return;
      setState(() {
        _categories = mapped;
        if (_selectedCategoryName != null) {
          _applyCategorySelectionByName(_selectedCategoryName!);
        }
      });
    } catch (_) {
      // Tetap gunakan daftar kategori default dari Beranda jika Firestore gagal.
    }
  }

  Future<void> _pickImages() async {
    final remaining = _maxPhotos - _selectedImages.length;
    if (remaining <= 0) {
      _showMessage('Maksimal $_maxPhotos foto sudah tercapai.');
      return;
    }

    try {
      final images = await _imagePicker.pickMultiImage(
        imageQuality: 75,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (images.isEmpty) return;

      final selected = images.take(remaining).toList();
      final bytesList = await Future.wait(
        selected.map((file) => file.readAsBytes()),
      );

      if (!mounted) return;

      setState(() {
        _selectedImages.addAll(bytesList);
      });

      if (images.length > remaining) {
        _showMessage(
          'Hanya $remaining foto yang ditambahkan (maksimal $_maxPhotos foto).',
        );
      }
    } catch (e) {
      _showMessage('Gagal memilih foto: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitComplaint() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('Silakan login terlebih dahulu.');
      return;
    }

    if (_selectedImages.isEmpty) {
      _showMessage('Minimal 1 foto bukti wajib dilampirkan.');
      return;
    }

    if (_selectedCategoryId == null || _selectedCategoryName == null) {
      _showMessage('Silakan pilih kategori pengaduan.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final complaint = ComplaintModel(
        userId: user.uid,
        userName: user.displayName ?? '',
        title: _titleController.text.trim(),
        categoryId: _selectedCategoryId!,
        categoryName: _selectedCategoryName!,
        description: _descriptionController.text.trim(),
        locationAddress: _locationController.text.trim(),
      );

      // TODO: Perbarui ComplaintService jika backend sudah mendukung multi-foto.
      final complaintId = await ComplaintService().createComplaint(
        complaint: complaint,
        imageBytes: _selectedImages.first,
      );

      if (!mounted) return;
      _showMessage('Pengaduan berhasil dikirim! ID: $complaintId');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showMessage('Gagal mengirim pengaduan: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final photoCount = _selectedImages.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Pengaduan'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sampaikan Pengaduan', style: textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                'Lengkapi informasi berikut agar pengaduan dapat diproses.',
                style: textTheme.bodySmall,
              ),
              const SizedBox(height: 24),

              _buildLabel('Judul Pengaduan'),
              TextFormField(
                controller: _titleController,
                maxLength: _maxTitleLength,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'Contoh: Jalan rusak di sekitar rumah',
                  prefixIcon: Icon(Icons.edit_outlined),
                ),
                validator: (v) =>
                    FormValidators.requiredField(v, 'Judul pengaduan'),
              ),
              const SizedBox(height: 16),

              _buildLabel('Kategori Pengaduan'),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategoryId,
                isExpanded: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.category_outlined),
                  hintText: 'Pilih kategori',
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category['id'],
                    child: Text(
                      category['name'] ?? '',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                    final selected = _categories.firstWhere(
                      (cat) => cat['id'] == value,
                    );
                    _selectedCategoryName = selected['name'];
                  });
                },
                validator: (value) =>
                    value == null ? 'Silakan pilih kategori.' : null,
              ),
              const SizedBox(height: 20),

              _buildLabel('Deskripsi Pengaduan'),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                maxLength: _maxDescriptionLength,
                decoration: const InputDecoration(
                  hintText: 'Jelaskan permasalahan secara detail...',
                  alignLabelWithHint: true,
                ),
                validator: (v) =>
                    FormValidators.requiredField(v, 'Deskripsi pengaduan'),
              ),
              const SizedBox(height: 16),

              _buildLabel('Lokasi Kejadian'),
              TextFormField(
                controller: _locationController,
                maxLength: _maxLocationLength,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  hintText: 'Masukkan alamat atau lokasi kejadian',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (v) =>
                    FormValidators.requiredField(v, 'Lokasi kejadian'),
              ),
              const SizedBox(height: 16),

              _buildLabel('Foto Bukti'),
              Text(
                'Unggah maksimal $_maxPhotos foto sebagai bukti pengaduan.',
                style: textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Anda sudah menambahkan $photoCount/$_maxPhotos foto',
                style: textTheme.bodySmall?.copyWith(
                  color: photoCount >= _maxPhotos
                      ? AppColors.statusWaiting
                      : AppColors.primaryDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed:
                    _isLoading || photoCount >= _maxPhotos ? null : _pickImages,
                icon: const Icon(Icons.add_a_photo_outlined),
                label: Text(
                  photoCount >= _maxPhotos
                      ? 'Maksimal Foto Tercapai'
                      : 'Pilih Foto',
                ),
              ),
              if (_selectedImages.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: List.generate(_selectedImages.length, (index) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(
                            _selectedImages[index],
                            width: 96,
                            height: 96,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          right: 2,
                          top: 2,
                          child: InkWell(
                            onTap: _isLoading ? null : () => _removeImage(index),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.cancel,
                                color: AppColors.error,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ],
              const SizedBox(height: 32),

              PrimaryButton(
                label: 'Kirim Pengaduan',
                isLoading: _isLoading,
                onPressed: _submitComplaint,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 15),
      ),
    );
  }
}
