
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Register pengguna baru
  Future<User?> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      UserCredential credential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = credential.user;

      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'email': email,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return user;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  // Login pengguna
  Future<User?> login({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential credential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return credential.user;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // Logout pengguna
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Mengambil data pengguna berdasarkan UID
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserData(
    String uid,
  ) async {
    return await _firestore.collection('users').doc(uid).get();
  }

  // Memantau status autentikasi
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
