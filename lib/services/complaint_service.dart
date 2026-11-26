
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../models/complaint_model.dart';

class ComplaintService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // =========================================
  // KONFIGURASI CLOUDINARY
  // =========================================

  static const String cloudName = 'i2zjtpik';
  static const String uploadPreset = 'laporkita_upload';

  static const String uploadUrl =
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

  static const int maxImageSize = 5 * 1024 * 1024;

  CollectionReference<Map<String, dynamic>> get _complaints =>
      _firestore.collection('complaints');

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  // =========================================
  // VALIDASI LOGIN DAN ROLE
  // =========================================

  User _requireLogin() {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Pengguna belum login.');
    }

    return user;
  }

  Future<void> _requireAdmin() async {
    final user = _requireLogin();

    final userDoc = await _users.doc(user.uid).get();

    if (!userDoc.exists ||
        userDoc.data()?['role'] != 'admin') {
      throw Exception('Akses hanya untuk admin.');
    }
  }

  // =========================================
  // UPLOAD FOTO KE CLOUDINARY
  // =========================================

  Future<String> uploadComplaintPhoto({
    required Uint8List imageBytes,
    required String complaintId,
  }) async {
    try {
      final user = _requireLogin();

      if (imageBytes.isEmpty) {
        throw Exception('Foto tidak boleh kosong.');
      }

      if (imageBytes.length > maxImageSize) {
        throw Exception(
          'Ukuran foto maksimal 5 MB.',
        );
      }

      // Memastikan pengaduan sudah dibuat
      // dan merupakan milik pengguna yang login.
      final complaintDoc =
          await _complaints.doc(complaintId).get();

      if (!complaintDoc.exists) {
        throw Exception('Pengaduan tidak ditemukan.');
      }

      final complaintData = complaintDoc.data()!;

      if (complaintData['userId'] != user.uid) {
        throw Exception(
          'Kamu tidak memiliki akses ke pengaduan ini.',
        );
      }

      if (complaintData['status'] !=
          ComplaintModel.statusMenunggu) {
        throw Exception(
          'Foto hanya dapat diunggah untuk pengaduan berstatus Menunggu.',
        );
      }

      // Menyiapkan request multipart ke Cloudinary.
      final uri = Uri.parse(uploadUrl);

      final request = http.MultipartRequest(
        'POST',
        uri,
      );

      request.fields['upload_preset'] = uploadPreset;
      request.fields['folder'] = 'complaint_images';

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: '$complaintId.jpg',
        ),
      );

      // Menampilkan isi request untuk pemeriksaan.
      debugPrint('CLOUDINARY FIELDS: ${request.fields}');
    
      // Mengirim foto ke Cloudinary.
      final streamedResponse = await request
          .send()
          .timeout(const Duration(seconds: 60));

      final response =
          await http.Response.fromStream(streamedResponse);
          debugPrint('CLOUDINARY URL: $uploadUrl');
          debugPrint('CLOUDINARY STATUS: ${response.statusCode}');
          debugPrint('CLOUDINARY RESPONSE: ${response.body}');

      final dynamic decodedResponse =
          jsonDecode(response.body);

      if (response.statusCode != 200 &&
          response.statusCode != 201) {
        String errorMessage =
            'Upload foto ke Cloudinary gagal.';

        if (decodedResponse is Map) {
          final errorData = decodedResponse['error'];

          if (errorData is Map &&
              errorData['message'] != null) {
            errorMessage =
                errorData['message'].toString();
          }
        }

        throw Exception(errorMessage);
      }

      if (decodedResponse is! Map ||
          decodedResponse['secure_url'] == null) {
        throw Exception(
          'Cloudinary tidak mengembalikan URL foto.',
        );
      }

      // Mengambil URL HTTPS dari Cloudinary.
      return decodedResponse['secure_url'].toString();
    } on FirebaseException {
      rethrow;
    } catch (e) {
      throw Exception('Gagal mengunggah foto: $e');
    }
  }

  // =========================================
  // MEMBUAT PENGADUAN BARU
  // =========================================

  Future<String> createComplaint({
    required ComplaintModel complaint,
    required Uint8List imageBytes,
  }) async {
    DocumentReference<Map<String, dynamic>>? docRef;

    try {
      final user = _requireLogin();

      // Memastikan UID sesuai.
      if (complaint.userId != user.uid) {
        throw Exception('UID pengguna tidak sesuai.');
      }

      // Memvalidasi data pengaduan.
      if (complaint.title.trim().isEmpty ||
          complaint.description.trim().isEmpty ||
          complaint.locationAddress.trim().isEmpty) {
        throw Exception(
          'Data pengaduan belum lengkap.',
        );
      }

      if (imageBytes.isEmpty) {
        throw Exception(
          'Foto bukti wajib dilampirkan.',
        );
      }

      if (imageBytes.length > maxImageSize) {
        throw Exception(
          'Ukuran foto maksimal 5 MB.',
        );
      }

      // Mengambil profil pengguna.
      final userDoc = await _users.doc(user.uid).get();

      if (!userDoc.exists) {
        throw Exception(
          'Profil pengguna tidak ditemukan.',
        );
      }

      final userData = userDoc.data()!;
      final userName = userData['name'] as String? ?? '';

      if (userName.trim().isEmpty) {
        throw Exception(
          'Nama pengguna belum tersedia.',
        );
      }

      // Memastikan hanya masyarakat/user yang dapat mengadu.
      final role = userData['role'];
      if (role != 'user' && role != 'masyarakat') {
        throw Exception(
          'Hanya masyarakat yang dapat membuat pengaduan.',
        );
      }

      // 1. Membuat ID dokumen Firestore.
      docRef = _complaints.doc();

      final complaintId = docRef.id;

      // 2. Menyimpan dokumen awal ke Firestore.
      // imageUrl dikosongkan sementara.
      final newComplaint = complaint.copyWith(
        complaintId: complaintId,
        userId: user.uid,
        userName: userName,
        imageUrl: '',
        status: ComplaintModel.statusMenunggu,
        adminResponse: '',
      );

      await docRef.set(newComplaint.toMap());

      // 3. Mengunggah foto ke Cloudinary.
      final imageUrl = await uploadComplaintPhoto(
        imageBytes: imageBytes,
        complaintId: complaintId,
      );

      // 4. Memperbarui URL foto di Firestore.
      await docRef.update({
        'imageUrl': imageUrl,
      });

      return complaintId;
    } catch (e) {
      // Jika proses gagal, hapus dokumen awal
      // yang sudah dibuat di Firestore.
      if (docRef != null) {
        try {
          await docRef.delete();
        } catch (_) {
          // Abaikan jika dokumen belum dibuat
          // atau penghapusan ditolak oleh Rules.
        }
      }

      throw Exception(
        'Gagal membuat pengaduan: $e',
      );
    }
  }

  // =========================================
  // MASYARAKAT: REAL-TIME PENGADUAN SENDIRI
  // =========================================

  Stream<List<ComplaintModel>> getMyComplaintsStream() {
    final user = _requireLogin();

    return _complaints
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ComplaintModel.fromMap(
          doc.data(),
          doc.id,
        );
      }).toList();
    });
  }

  // =========================================
  // MASYARAKAT: MENGAMBIL PENGADUAN SEKALI
  // =========================================

  Future<List<ComplaintModel>> getMyComplaints() async {
    try {
      final user = _requireLogin();

      final snapshot = await _complaints
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return ComplaintModel.fromMap(
          doc.data(),
          doc.id,
        );
      }).toList();
    } catch (e) {
      throw Exception(
        'Gagal mengambil pengaduan: $e',
      );
    }
  }

  // =========================================
  // MASYARAKAT: DETAIL PENGADUAN
  // =========================================

  Future<ComplaintModel?> getComplaintById(
    String complaintId,
  ) async {
    try {
      final user = _requireLogin();

      final doc = await _complaints.doc(complaintId).get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data()!;

      if (data['userId'] != user.uid) {
        throw Exception(
          'Kamu tidak memiliki akses ke pengaduan ini.',
        );
      }

      return ComplaintModel.fromMap(
        data,
        doc.id,
      );
    } catch (e) {
      throw Exception(
        'Gagal mengambil detail pengaduan: $e',
      );
    }
  }

  // =========================================
  // MASYARAKAT: MENGHAPUS PENGADUAN
  // =========================================

  Future<void> deleteMyComplaint(
    String complaintId,
  ) async {
    try {
      final user = _requireLogin();

      final docRef = _complaints.doc(complaintId);
      final doc = await docRef.get();

      if (!doc.exists) {
        throw Exception(
          'Pengaduan tidak ditemukan.',
        );
      }

      final data = doc.data()!;

      if (data['userId'] != user.uid) {
        throw Exception(
          'Kamu tidak memiliki akses ke pengaduan ini.',
        );
      }

      if (data['status'] !=
          ComplaintModel.statusMenunggu) {
        throw Exception(
          'Pengaduan hanya dapat dihapus saat berstatus Menunggu.',
        );
      }

      // Menghapus dokumen Firestore.
      await docRef.delete();

      // Catatan:
      // Foto di Cloudinary tidak ikut terhapus.
      // Penghapusan aset Cloudinary membutuhkan
      // autentikasi server-side yang aman.
    } catch (e) {
      throw Exception(
        'Gagal menghapus pengaduan: $e',
      );
    }
  }

  // =========================================
  // ADMIN: QUERY SEMUA PENGADUAN
  // =========================================

  Query<Map<String, dynamic>> _adminComplaintsQuery({
    String? status,
  }) {
    Query<Map<String, dynamic>> query = _complaints;

    if (status != null && status.isNotEmpty) {
      query = query.where(
        'status',
        isEqualTo: status,
      );
    }

    return query.orderBy(
      'createdAt',
      descending: true,
    );
  }

  // =========================================
  // ADMIN: REAL-TIME SEMUA PENGADUAN
  // =========================================

  Stream<List<ComplaintModel>> getAllComplaintsStream({
    String? status,
  }) async* {
    await _requireAdmin();

    yield* _adminComplaintsQuery(status: status)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ComplaintModel.fromMap(
          doc.data(),
          doc.id,
        );
      }).toList();
    });
  }

  // =========================================
  // ADMIN: MENGAMBIL SEMUA PENGADUAN SEKALI
  // =========================================

  Future<List<ComplaintModel>> getAllComplaints({
    String? status,
  }) async {
    try {
      await _requireAdmin();

      final snapshot =
          await _adminComplaintsQuery(status: status).get();

      return snapshot.docs.map((doc) {
        return ComplaintModel.fromMap(
          doc.data(),
          doc.id,
        );
      }).toList();
    } catch (e) {
      throw Exception(
        'Gagal mengambil semua pengaduan: $e',
      );
    }
  }

  // =========================================
  // ADMIN: MEMPERBARUI STATUS DAN TANGGAPAN
  // =========================================

  Future<void> updateComplaintStatus({
    required String complaintId,
    required String newStatus,
    required String adminResponse,
  }) async {
    try {
      await _requireAdmin();

      const allowedStatuses = [
        ComplaintModel.statusDiproses,
        ComplaintModel.statusSelesai,
        ComplaintModel.statusDitolak,
      ];

      if (!allowedStatuses.contains(newStatus)) {
        throw Exception(
          'Status pengaduan tidak valid.',
        );
      }

      if ((newStatus == ComplaintModel.statusSelesai ||
              newStatus == ComplaintModel.statusDitolak) &&
          adminResponse.trim().isEmpty) {
        throw Exception(
          'Tanggapan admin wajib diisi untuk status Selesai atau Ditolak.',
        );
      }

      final docRef = _complaints.doc(complaintId);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);

        if (!doc.exists) {
          throw Exception(
            'Pengaduan tidak ditemukan.',
          );
        }

        final currentStatus = doc.data()?['status'];

        final isValidTransition =
            (currentStatus ==
                    ComplaintModel.statusMenunggu &&
                (newStatus ==
                        ComplaintModel.statusDiproses ||
                    newStatus ==
                        ComplaintModel.statusDitolak)) ||
            (currentStatus ==
                    ComplaintModel.statusDiproses &&
                newStatus ==
                    ComplaintModel.statusSelesai);

        if (!isValidTransition) {
          throw Exception(
            'Perubahan status tidak sesuai alur pengaduan.',
          );
        }

        transaction.update(docRef, {
          'status': newStatus,
          'adminResponse': adminResponse.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      throw Exception(
        'Gagal memperbarui pengaduan: $e',
      );
    }
  }

  // =========================================
  // ADMIN: STATISTIK PENGADUAN
  // =========================================

  Future<Map<String, int>> getComplaintStatistics() async {
    try {
      await _requireAdmin();

      final snapshot = await _complaints.get();

      final statistics = {
        ComplaintModel.statusMenunggu: 0,
        ComplaintModel.statusDiproses: 0,
        ComplaintModel.statusSelesai: 0,
        ComplaintModel.statusDitolak: 0,
      };

      for (final doc in snapshot.docs) {
        final status = doc.data()['status'];

        if (statistics.containsKey(status)) {
          statistics[status] =
              statistics[status]! + 1;
        }
      }

      return statistics;
    } catch (e) {
      throw Exception(
        'Gagal mengambil statistik: $e',
      );
    }
  }
}
