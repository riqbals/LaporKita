import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/complaint_model.dart';
import '../../../services/complaint_service.dart';
import '../../../services/category_service.dart';

class CreateComplaintScreen extends StatefulWidget {
  const CreateComplaintScreen({super.key});

  @override
  State<CreateComplaintScreen> createState() =>
      _CreateComplaintScreenState();
}

class _CreateComplaintScreenState
    extends State<CreateComplaintScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  final ComplaintService _complaintService =
      ComplaintService();

  final CategoryService _categoryService =
      CategoryService();

  final ImagePicker _imagePicker = ImagePicker();

  Uint8List? _selectedImageBytes;

  List<Map<String, dynamic>> _categories = [];

  String? _selectedCategoryId;
  String? _selectedCategoryName;

  bool _isLoading = false;
  bool _isLoadingCategories = true;

  // =====================================================
  // MEMUAT KATEGORI DARI FIRESTORE
  // =====================================================

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories =
          await _categoryService.getActiveCategories();

      if (!mounted) return;

      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingCategories = false;
      });

      _showMessage('Gagal memuat kategori: $e');
    }
  }

  // =====================================================
  // MEMILIH FOTO DARI GALERI
  // =====================================================

  Future<void> _pickImage() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (image == null) return;

      final imageBytes = await image.readAsBytes();

      if (!mounted) return;

      setState(() {
        _selectedImageBytes = imageBytes;
      });
    } catch (e) {
      _showMessage('Gagal memilih foto: $e');
    }
  }

  // =====================================================
  // MENGHAPUS FOTO
  // =====================================================

  void _removeImage() {
    setState(() {
      _selectedImageBytes = null;
    });
  }

  // =====================================================
  // MENYIMPAN PENGADUAN
  // =====================================================

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Silakan login terlebih dahulu.');
      return;
    }

    if (_selectedImageBytes == null) {
      _showMessage('Foto bukti wajib dilampirkan.');
      return;
    }

    if (_selectedCategoryId == null ||
        _selectedCategoryName == null) {
      _showMessage('Silakan pilih kategori pengaduan.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Membuat model pengaduan
      final complaint = ComplaintModel(
        userId: user.uid,
        userName: user.displayName ?? '',
        title: _titleController.text.trim(),
        categoryId: _selectedCategoryId!,
        categoryName: _selectedCategoryName!,
        description: _descriptionController.text.trim(),
        locationAddress: _locationController.text.trim(),
      );

      // Menyimpan pengaduan sekaligus mengunggah foto
      // melalui Firebase Storage
      final complaintId =
          await _complaintService.createComplaint(
        complaint: complaint,
        imageBytes: _selectedImageBytes!,
      );

      if (!mounted) return;

      _showMessage(
        'Pengaduan berhasil dikirim! ID: $complaintId',
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      _showMessage('Gagal mengirim pengaduan: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // =====================================================
  // MENAMPILKAN PESAN
  // =====================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // =====================================================
  // MEMBERSIHKAN CONTROLLER
  // =====================================================

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();

    super.dispose();
  }

  // =====================================================
  // TAMPILAN HALAMAN
  // =====================================================

  @override
  Widget build(BuildContext context) {
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

              const Text(
                'Sampaikan Pengaduan',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Lengkapi informasi berikut agar '
                'pengaduan dapat diproses.',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 24),

              // JUDUL PENGADUAN
              _buildLabel('Judul Pengaduan'),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText:
                      'Contoh: Jalan rusak di sekitar rumah',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit),
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Judul pengaduan wajib diisi.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 20),

              // KATEGORI
              _buildLabel('Kategori Pengaduan'),

              if (_isLoadingCategories)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_categories.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.red.shade300,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Kategori belum tersedia. '
                    'Silakan coba kembali nanti.',
                    style: TextStyle(
                      color: Colors.red,
                    ),
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategoryId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                    hintText: 'Pilih kategori',
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category['id'] as String,
                      child: Text(
                        category['name']?.toString() ?? '',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryId = value;

                      final selectedCategory =
                          _categories.firstWhere(
                        (category) =>
                            category['id'] == value,
                      );

                      _selectedCategoryName =
                          selectedCategory['name']
                              ?.toString();
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Silakan pilih kategori.';
                    }

                    return null;
                  },
                ),

              const SizedBox(height: 20),

              // DESKRIPSI
              _buildLabel('Deskripsi Pengaduan'),

              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText:
                      'Jelaskan permasalahan secara detail...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Deskripsi pengaduan wajib diisi.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 20),

              // LOKASI
              _buildLabel('Lokasi Kejadian'),

              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  hintText:
                      'Masukkan alamat atau lokasi kejadian',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Lokasi kejadian wajib diisi.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 20),

              // FOTO BUKTI
              _buildLabel('Foto Bukti'),

              const Text(
                'Pilih satu foto sebagai bukti pengaduan.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: _isLoading
                    ? null
                    : _pickImage,
                icon: const Icon(Icons.add_a_photo),
                label: const Text('Pilih Foto'),
              ),

              const SizedBox(height: 12),

              if (_selectedImageBytes != null)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(10),
                      child: Image.memory(
                        _selectedImageBytes!,
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    ),

                    Positioned(
                      right: 0,
                      top: 0,
                      child: IconButton(
                        onPressed: _isLoading
                            ? null
                            : _removeImage,
                        icon: const Icon(
                          Icons.cancel,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 32),

              // TOMBOL KIRIM
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ||
                          _isLoadingCategories
                      ? null
                      : _submitComplaint,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Kirim Pengaduan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================
  // WIDGET LABEL FORM
  // =====================================================

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    );
  }
}
