import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  /// Register pengguna baru dengan role default "user" sesuai PRD.
  Future<User?> register({
    required String name,
    required String email,
    required String password,
    String phone = '',
    String role = UserModel.roleUser,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;

    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return user;
  }

  /// Login pengguna.
  Future<User?> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  /// Logout pengguna.
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Mengambil data pengguna berdasarkan UID.
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserData(
    String uid,
  ) async {
    return _firestore.collection('users').doc(uid).get();
  }

  /// Mengambil profil pengguna yang sedang login sebagai [UserModel].
  Future<UserModel?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await getUserData(user.uid);
    if (!doc.exists || doc.data() == null) return null;

    return UserModel.fromMap(doc.data()!, doc.id);
  }

  /// Memperbarui profil pengguna (`name` dan `phone` saja sesuai RBAC PRD).
  Future<void> updateProfile({
    required String name,
    required String phone,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Pengguna belum login.');
    }

    await _firestore.collection('users').doc(user.uid).update({
      'name': name.trim(),
      'phone': phone.trim(),
    });
  }

  /// Memantau status autentikasi.
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
