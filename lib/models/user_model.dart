import 'package:cloud_firestore/cloud_firestore.dart';

/// Model pengguna sesuai skema koleksi `users` pada PRD dan ERD.
class UserModel {
  static const String roleUser = 'user';
  static const String roleAdmin = 'admin';

  final String uid;
  final String name;
  final String email;
  final String phone;
  final String role;
  final DateTime? createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phone = '',
    this.role = roleUser,
    this.createdAt,
  });

  bool get isAdmin => role == roleAdmin;

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory UserModel.fromMap(
    Map<String, dynamic> map, [
    String? documentId,
  ]) {
    return UserModel(
      uid: (map['uid'] as String?) ?? documentId ?? '',
      name: (map['name'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      phone: (map['phone'] as String?) ?? '',
      role: (map['role'] as String?) ?? roleUser,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? role,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
