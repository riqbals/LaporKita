import 'package:flutter/material.dart';
import 'core/constants/app_routes.dart';
import 'core/theme/app_theme.dart';

void main() {
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
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (_) => const _PlaceholderScreen(),
      },
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('LaporKita Design System Ready'),
      ),
    );
  }
}
