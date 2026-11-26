import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/constants/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'screens/admin/dashboard_admin_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/profile/faq_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/user/complaint/create_complaint_screen.dart';
import 'screens/user/home_user_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const LaporKitaApp());
}

class LaporKitaApp extends StatelessWidget {
  const LaporKitaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LaporKita',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.login,
      onGenerateInitialRoutes: (_) => [
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: const RouteSettings(name: AppRoutes.login),
        ),
      ],
      onGenerateRoute: (settings) {
        final Widget page = switch (settings.name) {
          AppRoutes.splash => const SplashScreen(),
          AppRoutes.onboarding => const OnboardingScreen(),
          AppRoutes.login => const LoginScreen(),
          AppRoutes.register => const RegisterScreen(),
          AppRoutes.homeUser => const HomeUserScreen(),
          AppRoutes.createComplaint => const CreateComplaintScreen(),
          AppRoutes.dashboardAdmin => const DashboardAdminScreen(),
          AppRoutes.profile => const ProfileScreen(),
          AppRoutes.editProfile => const EditProfileScreen(),
          AppRoutes.faq => const FaqScreen(),
          _ => const LoginScreen(),
        };
        return MaterialPageRoute(builder: (_) => page, settings: settings);
      },
    );
  }
}
