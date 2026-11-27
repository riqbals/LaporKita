/// Konstanta named routes untuk navigasi aplikasi LaporKita.
/// Mengacu pada daftar screen di PRD Section 6.
abstract final class AppRoutes {
  // Auth
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String roleSelection = '/role-selection';
  static const String login = '/login';
  static const String register = '/register';

  // User
  static const String homeUser = '/user/home';
  static const String createComplaint = '/user/create-complaint';
  static const String detailComplaint = '/user/detail-complaint';

  // Admin
  static const String dashboardAdmin = '/admin/dashboard';
  static const String detailAdmin = '/admin/detail';

  // Profile
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String faq = '/profile/faq';
}

