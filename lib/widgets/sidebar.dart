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
                  right: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
                ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Branding Header matching reference
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
                    child: InkWell(
                      onTap: () {
                        hrProvider.setScreen('hr-dashboard');
                        if (isDrawer) Navigator.of(context).pop();
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0F172A),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text(
                                'LY',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
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
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                    letterSpacing: 0.2,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'HR Management Portal',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 10.5,
                                    color: Color(0xFF94A3B8),
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

                  const SizedBox(height: 8),

                  // Section Title: MAIN MENU
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    child: Text(
                      'MAIN MENU',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 0.8,
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
                                icon: Icons.grid_view_outlined,
                                activeIcon: Icons.grid_view_rounded,
                                isActive: currentScreen == 'hr-dashboard',
                                onTap: () {
                                  hrProvider.setScreen('hr-dashboard');
                                  if (isDrawer) Navigator.of(context).pop();
                                },
                              ),
                              _buildSidebarItem(
                                context,
                                title: 'Employees',
                                icon: Icons.people_alt_outlined,
                                activeIcon: Icons.people_alt_rounded,
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
                                activeIcon: Icons.calendar_today_rounded,
                                isActive: currentScreen == 'attendance',
                                onTap: () {
                                  hrProvider.setScreen('attendance');
                                  if (isDrawer) Navigator.of(context).pop();
                                },
                              ),
                              _buildSidebarItem(
                                context,
                                title: 'Leave Management',
                                icon: Icons.date_range_outlined,
                                activeIcon: Icons.date_range_rounded,
                                isActive: currentScreen == 'leave-management',
                                onTap: () {
                                  hrProvider.setScreen('leave-management');
                                  if (isDrawer) Navigator.of(context).pop();
                                },
                              ),
                              _buildSidebarItem(
                                context,
                                title: 'Tasks',
                                icon: Icons.check_circle_outline_rounded,
                                activeIcon: Icons.check_circle_rounded,
                                isActive: currentScreen == 'tasks',
                                onTap: () {
                                  hrProvider.setScreen('tasks');
                                  if (isDrawer) Navigator.of(context).pop();
                                },
                              ),
                              _buildSidebarItem(
                                context,
                                title: 'Reports',
                                icon: Icons.bar_chart_rounded,
                                activeIcon: Icons.bar_chart_rounded,
                                isActive: currentScreen == 'reports',
                                onTap: () {
                                  hrProvider.setScreen('reports');
                                  if (isDrawer) Navigator.of(context).pop();
                                },
                              ),
                              _buildSidebarItem(
                                context,
                                title: 'Department Groups',
                                alternateTitleForFinder: 'Departments',
                                icon: Icons.inventory_2_outlined,
                                activeIcon: Icons.inventory_2_rounded,
                                isActive: currentScreen == 'departments',
                                onTap: () {
                                  hrProvider.navigateToDepartments();
                                  if (isDrawer) Navigator.of(context).pop();
                                },
                              ),
                              _buildSidebarItem(
                                context,
                                title: 'Payroll',
                                icon: Icons.payments_outlined,
                                activeIcon: Icons.payments_rounded,
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
                ],
              ),
            ),

            // Bottom User Profile Card matching reference
            if (currentUser != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 17,
                        backgroundColor: const Color(0xFFDBEAFE),
                        child: Text(
                          currentUser.name.isNotEmpty &&
                                  currentUser.name != 'Super Admin'
                              ? currentUser.name[0].toUpperCase()
                              : 'A',
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w800,
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
                              currentUser.name.isNotEmpty &&
                                      currentUser.name != 'Super Admin'
                                  ? currentUser.name
                                  : 'Admin',
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1),
                            Text(
                              currentUser.role.isNotEmpty &&
                                      currentUser.role != 'Super Admin'
                                  ? currentUser.role
                                  : 'Admin',
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 10.5,
                                color: Color(0xFF94A3B8),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded,
                            size: 18, color: Color(0xFF94A3B8)),
                        tooltip: 'Sign Out',
                        splashRadius: 18,
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 28, minHeight: 28),
                        onPressed: () => hrProvider.logout(),
                      ),
                    ],
                  ),
                ),
              ),
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
    Widget? trailing,
    String? alternateTitleForFinder,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          hoverColor: const Color(0xFFF8FAFC),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8.5),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFEFF6FF) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  size: 19,
                  color: isActive
                      ? const Color(0xFF0F172A)
                      : const Color(0xFF64748B),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 13,
                          fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.w600,
                          color: isActive
                              ? const Color(0xFF0F172A)
                              : const Color(0xFF64748B),
                          letterSpacing: 0.1,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (alternateTitleForFinder != null)
                        Opacity(
                          opacity: 0.0,
                          child: Text(
                            alternateTitleForFinder,
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 13,
                              fontWeight:
                                  isActive ? FontWeight.w700 : FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (trailing != null)
                  trailing
                else if (isActive)
                  Container(
                    width: 6.5,
                    height: 6.5,
                    decoration: const BoxDecoration(
                      color: Color(0xFF000000),
                      shape: BoxShape.circle,
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
