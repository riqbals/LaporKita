import 'package:cloud_firestore/cloud_firestore.dart';

class ComplaintModel {
  // Status pengaduan sesuai PRD
  static const String statusMenunggu = 'Menunggu';
  static const String statusDiproses = 'Diproses';
  static const String statusSelesai = 'Selesai';
  static const String statusDitolak = 'Ditolak';

  final String? complaintId;
  final String userId;
  final String userName;
  final String title;
  final String categoryId;
  final String categoryName;
  final String description;
  final String locationAddress;
  final String imageUrl;
  final String status;
  final String adminResponse;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ComplaintModel({
    this.complaintId,
    required this.userId,
    required this.userName,
    required this.title,
    required this.categoryId,
    required this.categoryName,
    required this.description,
    required this.locationAddress,
    this.imageUrl = '',
    this.status = statusMenunggu,
    this.adminResponse = '',
    this.createdAt,
    this.updatedAt,
  });

  // Mengubah model menjadi Map untuk Firestore
  Map<String, dynamic> toMap() {
    return {
      if (complaintId != null) 'complaintId': complaintId,
      'userId': userId,
      'userName': userName,
      'title': title,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'description': description,
      'locationAddress': locationAddress,
      'imageUrl': imageUrl,
      'status': status,
      'adminResponse': adminResponse,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // Mengubah data Firestore menjadi ComplaintModel
  factory ComplaintModel.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    return ComplaintModel(
      complaintId: documentId,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      title: map['title'] ?? '',
      categoryId: map['categoryId'] ?? '',
      categoryName: map['categoryName'] ?? '',
      description: map['description'] ?? '',
      locationAddress: map['locationAddress'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      status: map['status'] ?? statusMenunggu,
      adminResponse: map['adminResponse'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // Membuat salinan model dengan nilai yang diperbarui
  ComplaintModel copyWith({
    String? complaintId,
    String? userId,
    String? userName,
    String? title,
    String? categoryId,
    String? categoryName,
    String? description,
    String? locationAddress,
    String? imageUrl,
    String? status,
    String? adminResponse,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ComplaintModel(
      complaintId: complaintId ?? this.complaintId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      title: title ?? this.title,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      description: description ?? this.description,
      locationAddress: locationAddress ?? this.locationAddress,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      adminResponse: adminResponse ?? this.adminResponse,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
