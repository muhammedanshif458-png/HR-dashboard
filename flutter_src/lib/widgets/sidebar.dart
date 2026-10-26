import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/hr_provider.dart';

class AppSidebar extends StatelessWidget {
  final bool isDrawer;

  const AppSidebar({super.key, this.isDrawer = false});

  @override
  Widget build(BuildContext context) {
    final hrProvider = context.watch<HRProvider>();
    final currentUser = hrProvider.currentUser;
    final currentScreen = hrProvider.currentScreen;

    final content = Material(
      color: Colors.white,
      child: Container(
        width: 250,
        decoration: BoxDecoration(
          color: Colors.white,
          border: isDrawer
              ? null
              : const Border(
                  right: BorderSide(
                    color: Color(0xFFE2E8F0),
                    width: 1.0,
                  ),
                ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Branding Header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
              child: InkWell(
                onTap: () {
                  hrProvider.setScreen('hr-dashboard');
                  if (isDrawer) Navigator.of(context).pop();
                },
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2457D6),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF2457D6).withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        'LY',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LY SOFTWARE',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2),
                          Text(
                            'HR Management Portal',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),

            // Section Title: MAIN MENU
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Text(
                'MAIN MENU',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 1.1,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: hrProvider.isStaffUser
                    ? [
                        _buildSidebarItem(
                          context,
                          title: 'Staff Portal',
                          icon: Icons.person_outline,
                          activeIcon: Icons.person,
                          isActive: currentScreen == 'staff-portal',
                          onTap: () {
                            hrProvider.setScreen('staff-portal');
                            if (isDrawer) Navigator.of(context).pop();
                          },
                        ),
                        _buildSidebarItem(
                          context,
                          title: 'Department Chat',
                          icon: Icons.forum_outlined,
                          activeIcon: Icons.forum,
                          isActive: currentScreen == 'dept-chat',
                          onTap: () {
                            hrProvider.setScreen('dept-chat');
                            if (isDrawer) Navigator.of(context).pop();
                          },
                        ),
                        _buildSidebarItem(
                          context,
                          title: 'Direct Messages',
                          icon: Icons.chat_bubble_outline,
                          activeIcon: Icons.chat_bubble,
                          isActive: currentScreen == 'chat',
                          onTap: () {
                            hrProvider.setScreen('chat');
                            if (isDrawer) Navigator.of(context).pop();
                          },
                        ),
                      ]
                    : [
                        _buildSidebarItem(
                          context,
                          title: 'Dashboard',
                          icon: Icons.dashboard_outlined,
                          activeIcon: Icons.dashboard,
                          isActive: currentScreen == 'hr-dashboard',
                          onTap: () {
                            hrProvider.setScreen('hr-dashboard');
                            if (isDrawer) Navigator.of(context).pop();
                          },
                        ),
                        _buildSidebarItem(
                          context,
                          title: 'Employees',
                          icon: Icons.people_outline,
                          activeIcon: Icons.people,
                          isActive: currentScreen == 'employees',
                          onTap: () {
                            hrProvider.setScreen('employees');
                            if (isDrawer) Navigator.of(context).pop();
                          },
                        ),
                        _buildSidebarItem(
                          context,
                          title: 'Attendance',
                          icon: Icons.calendar_today_outlined,
                          activeIcon: Icons.calendar_today,
                          isActive: currentScreen == 'attendance',
                          onTap: () {
                            hrProvider.setScreen('attendance');
                            if (isDrawer) Navigator.of(context).pop();
                          },
                        ),
                        _buildSidebarItem(
                          context,
                          title: 'Leave Management',
                          icon: Icons.event_note_outlined,
                          activeIcon: Icons.event_note,
                          isActive: currentScreen == 'leave-management',
                          badgeCount: hrProvider.pendingLeavesCount,
                          onTap: () {
                            hrProvider.setScreen('leave-management');
                            if (isDrawer) Navigator.of(context).pop();
                          },
                        ),
                        _buildSidebarItem(
                          context,
                          title: 'Tasks',
                          icon: Icons.task_alt_outlined,
                          activeIcon: Icons.task_alt,
                          isActive: currentScreen == 'tasks',
                          onTap: () {
                            hrProvider.setScreen('tasks');
                            if (isDrawer) Navigator.of(context).pop();
                          },
                        ),
                        _buildSidebarItem(
                          context,
                          title: 'Reports',
                          icon: Icons.bar_chart_outlined,
                          activeIcon: Icons.bar_chart,
                          isActive: currentScreen == 'reports',
                          onTap: () {
                            hrProvider.setScreen('reports');
                            if (isDrawer) Navigator.of(context).pop();
                          },
                        ),
                        _buildSidebarItem(
                          context,
                          title: 'Departments',
                          icon: Icons.corporate_fare_outlined,
                          activeIcon: Icons.corporate_fare,
                          isActive: currentScreen == 'departments',
                          onTap: () {
                            hrProvider.setScreen('departments');
                            if (isDrawer) Navigator.of(context).pop();
                          },
                        ),
                        _buildSidebarItem(
                          context,
                          title: 'Payroll',
                          icon: Icons.payments_outlined,
                          activeIcon: Icons.payments,
                          isActive: currentScreen == 'payroll',
                          onTap: () {
                            hrProvider.setScreen('payroll');
                            if (isDrawer) Navigator.of(context).pop();
                          },
                        ),
                      ],
              ),
            ),

            const SizedBox(height: 16),

            // Bottom User Profile Card
            if (currentUser != null) ...[
              const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFFDBEAFE),
                        child: Text(
                          currentUser.name.isNotEmpty
                              ? currentUser.name[0]
                              : 'U',
                          style: const TextStyle(
                            color: Color(0xFF1D4ED8),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currentUser.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              currentUser.role,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout,
                            size: 18, color: Color(0xFF94A3B8)),
                        tooltip: 'Sign Out',
                        splashRadius: 18,
                        onPressed: () => hrProvider.logout(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (isDrawer) {
      return Drawer(
        backgroundColor: Colors.white,
        child: content,
      );
    }

    return content;
  }

  Widget _buildSidebarItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required IconData activeIcon,
    required bool isActive,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          hoverColor: const Color(0xFFF1F5F9),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFEFF6FF) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive ? const Color(0xFFBFDBFE) : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  size: 19,
                  color: isActive
                      ? const Color(0xFF2457D6)
                      : const Color(0xFF64748B),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive
                          ? const Color(0xFF2457D6)
                          : const Color(0xFF334155),
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
                if (badgeCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badgeCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
