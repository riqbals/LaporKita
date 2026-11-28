import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_logo.dart';

/// Halaman awal untuk memeriksa sesi FirebaseAuth dan mengarahkan sesuai role.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    if (Firebase.apps.isEmpty) {
      Navigator.pushReplacementNamed(context, AppRoutes.roleSelection);
      return;
    }

    try {
      final user = _authService.currentUser;
      if (user == null) {
        Navigator.pushReplacementNamed(context, AppRoutes.roleSelection);
        return;
      }

      final profile = await _authService.getCurrentUserProfile();
      if (!mounted) return;

      if (profile == null) {
        Navigator.pushReplacementNamed(context, AppRoutes.roleSelection);
        return;
      }

      final targetRoute = profile.role == UserModel.roleAdmin
          ? AppRoutes.dashboardAdmin
          : AppRoutes.homeUser;

      Navigator.pushReplacementNamed(context, targetRoute);
    } catch (_) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.roleSelection);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLogo(width: 170),
            SizedBox(height: 20),
            CircularProgressIndicator(color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
