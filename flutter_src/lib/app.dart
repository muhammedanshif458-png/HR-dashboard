import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/hr_provider.dart';
import 'features/auth/login_view.dart';
import 'features/dashboard/hr_dashboard_view.dart';
import 'features/dashboard/staff_profile_view.dart';
import 'features/staff/staff_portal_view.dart';
import 'core/theme.dart';

class HRApp extends StatelessWidget {
  const HRApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HR Dashboard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainRouter(),
    );
  }
}

class MainRouter extends StatelessWidget {
  const MainRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final hrProvider = context.watch<HRProvider>();
    final currentUser = hrProvider.currentUser;
    final currentScreen = hrProvider.currentScreen;

    if (currentUser == null || currentScreen == 'login') {
      return const LoginView();
    }

    if (currentScreen == 'hr-dashboard') {
      return const HRDashboardView();
    }

    if (currentScreen == 'staff-portal') {
      return const StaffPortalView();
    }

    if (currentScreen == 'staff-profile') {
      return const StaffProfileView();
    }

    // Default fallback
    return const LoginView();
  }
}
