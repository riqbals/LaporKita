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

  final List<Uint8List> _selectedImages = [];

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
  // MEMILIH FOTO DARI GALERI (MAKSIMAL 5 FOTO)
  // =====================================================

  Future<void> _pickImages() async {
    try {
      final remaining = ComplaintService.maxImages - _selectedImages.length;
      if (remaining <= 0) {
        _showMessage(
          'Maksimal ${ComplaintService.maxImages} foto yang dapat dilampirkan.',
        );
        return;
      }

      final images = await _imagePicker.pickMultiImage(
        imageQuality: 75,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (images.isEmpty) return;

      final toAdd = images.take(remaining).toList();
      final bytesList = <Uint8List>[];
      for (final img in toAdd) {
        bytesList.add(await img.readAsBytes());
      }

      if (!mounted) return;

      setState(() {
        _selectedImages.addAll(bytesList);
      });

      if (images.length > remaining) {
        _showMessage(
          'Hanya ${ComplaintService.maxImages} foto pertama yang diambil (maksimal ${ComplaintService.maxImages} foto).',
        );
      }
    } catch (e) {
      _showMessage('Gagal memilih foto: $e');
    }
  }

  // =====================================================
  // MENGHAPUS FOTO
  // =====================================================

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
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

    if (_selectedImages.isEmpty) {
      _showMessage('Minimal 1 foto bukti wajib dilampirkan.');
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

      // Menyimpan pengaduan sekaligus mengunggah foto ke Cloudinary
      final complaintId = await _complaintService.createComplaint(
        complaint: complaint,
        imageBytesList: _selectedImages,
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
              _buildLabel(
                'Foto Bukti (${_selectedImages.length}/${ComplaintService.maxImages})',
              ),

              const Text(
                'Pilih minimal 1 dan maksimal 5 foto sebagai bukti pengaduan.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: _isLoading ||
                        _selectedImages.length >= ComplaintService.maxImages
                    ? null
                    : _pickImages,
                icon: const Icon(Icons.add_a_photo),
                label: Text(
                  _selectedImages.length >= ComplaintService.maxImages
                      ? 'Maksimal ${ComplaintService.maxImages} Foto'
                      : 'Pilih Foto',
                ),
              ),

              const SizedBox(height: 12),

              if (_selectedImages.isNotEmpty)
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
                            width: 110,
                            height: 110,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: IconButton(
                            onPressed: _isLoading
                                ? null
                                : () => _removeImage(index),
                            icon: const Icon(
                              Icons.cancel,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
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
