import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/hr_provider.dart';
import 'features/auth/login_view.dart';
import 'features/dashboard/hr_dashboard_view.dart';
import 'features/dashboard/staff_profile_view.dart';
import 'features/leaves/leave_management_view.dart';
import 'features/attendance/attendance_view.dart';
import 'features/employees/employees_view.dart';
import 'features/tasks/tasks_view.dart';
import 'features/reports/reports_view.dart';
import 'features/departments/departments_view.dart';
import 'features/staff/staff_portal_view.dart';
import 'features/chat/chat_view.dart';
import 'features/chat/department_chat_view.dart';
import 'features/payroll/payroll_view.dart';
import 'core/theme.dart';
import 'features/api_list/api_list.dart';

import 'widgets/sidebar.dart';

class HRApp extends StatelessWidget {
  const HRApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LY SOFTWARE — HR Management Portal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainRouter(),
      routes: {
        ApiListPage.routeName: (_) => const ApiListPage(),
      },
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

    final Widget content;
    switch (currentScreen) {
      case 'hr-dashboard':
        content = const HRDashboardView();
        break;
      case 'leave-management':
        content = const LeaveManagementView();
        break;
      case 'attendance':
        content = const AttendanceView();
        break;
      case 'employees':
        content = const EmployeesView();
        break;
      case 'tasks':
        content = const TasksView();
        break;
      case 'reports':
        content = const ReportsView();
        break;
      case 'departments':
        content = const DepartmentsView();
        break;
      case 'payroll':
        content = const PayrollView();
        break;
      case 'staff-profile':
        content = const StaffProfileView();
        break;
      case 'staff-portal':
        content = const StaffPortalView();
        break;
      case 'chat':
        content = const ChatView();
        break;
      case 'dept-chat':
        content = DepartmentChatView(
          key: ValueKey(
              'dept_chat_${hrProvider.activeDepartmentChatKey ?? "tech"}'),
          departmentKey: hrProvider.activeDepartmentChatKey ?? 'tech',
        );
      default:
        content = const HRDashboardView();
    }

    return AppShell(child: content);
  }
}

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    if (!isDesktop) {
      return child;
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(
          width: 250,
          child: AppSidebar(),
        ),
        Expanded(child: child),
      ],
    );
  }
}
