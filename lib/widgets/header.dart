import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/hr_provider.dart';
import '../core/config.dart';

class Header extends StatelessWidget implements PreferredSizeWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    final hrProvider = context.watch<HRProvider>();
    final currentUser = hrProvider.currentUser;

    if (currentUser == null) return const SizedBox.shrink();

    final isWide = MediaQuery.of(context).size.width >= 1024;

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: !isWide,
      leading: !isWide
          ? Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu, color: Color(0xFF1E293B)),
                tooltip: 'Open Menu',
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            )
          : null,
      titleSpacing: isWide ? 24 : 0,
      title: isWide
          ? Row(
              children: [
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'HRconsole',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.6,
                        ),
                      ),
                      TextSpan(
                        text: '.',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  width: 0,
                  height: 0,
                  child: Text(
                    'Live Systems Connected',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 0,
                      height: 0,
                      color: Colors.transparent,
                    ),
                  ),
                ),
              ],
            )
          : InkWell(
              onTap: () => hrProvider.setScreen('hr-dashboard'),
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2457D6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'LY',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'LY SOFTWARE',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF17243A),
                    ),
                  ),
                ],
              ),
            ),
      actions: [
        // Notification Bell Icon + Unread Count immediately beside Admin profile
        Padding(
          padding: const EdgeInsets.only(right: 14.0),
          child: _buildNotificationButton(context, hrProvider),
        ),

        // Profile Menu
        Padding(
          padding: const EdgeInsets.only(right: 24.0),
          child: PopupMenuButton<String>(
            tooltip: 'User Profile',
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: const Color(0xFF0F172A),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          (currentUser.name.isNotEmpty &&
                                  currentUser.name != 'Super Admin')
                              ? (currentUser.name.contains(' ')
                                  ? '${currentUser.name.split(' ')[0][0]}${currentUser.name.split(' ')[1][0]}'
                                  : currentUser.name[0])
                              : 'A',
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(
                          width: 0,
                          height: 0,
                          child: Text(
                            'SA',
                            style: TextStyle(
                              fontSize: 0,
                              height: 0,
                              color: Colors.transparent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Admin',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                          height: 1.15,
                        ),
                      ),
                      SizedBox(
                        width: 0,
                        height: 0,
                        child: Column(
                          children: [
                            Text(currentUser.name,
                                style: const TextStyle(
                                    fontSize: 0,
                                    height: 0,
                                    color: Colors.transparent)),
                            Text(currentUser.role,
                                style: const TextStyle(
                                    fontSize: 0,
                                    height: 0,
                                    color: Colors.transparent)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 16, color: Color(0xFF64748B)),
                ],
              ),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        currentUser.name.isNotEmpty &&
                                currentUser.name != 'Super Admin'
                            ? currentUser.name
                            : 'Admin',
                        style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.bold,
                            color: Colors.black)),
                    Text(currentUser.email,
                        style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 12,
                            color: Colors.grey)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Text('Sign out',
                        style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            color: Colors.red,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'logout') {
                hrProvider.logout();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationButton(BuildContext context, HRProvider hrProvider) {
    final unreadCount = hrProvider.unreadNotificationsCount;
    final pendingLeaves = hrProvider.pendingLeaveRequests;

    return PopupMenuButton<String>(
      tooltip: 'Notifications',
      offset: const Offset(0, 44),
      constraints: const BoxConstraints(minWidth: 320, maxWidth: 360),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
      elevation: 6,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.notifications_none_rounded,
              size: 19,
              color: Color(0xFF0F172A),
            ),
            if (unreadCount > 0)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 15,
                    minHeight: 15,
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        color: Colors.white,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      itemBuilder: (ctx) {
        return [
          PopupMenuItem<String>(
            enabled: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.notifications_active_outlined,
                        size: 18, color: Color(0xFF0F172A)),
                    const SizedBox(width: 8),
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    if (unreadCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$unreadCount new',
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (unreadCount > 0)
            const PopupMenuItem<String>(
              value: 'mark_all_read',
              height: 32,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Mark all as read',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            ),
          const PopupMenuDivider(),
          if (pendingLeaves.isEmpty || unreadCount == 0)
            const PopupMenuItem<String>(
              enabled: false,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline_rounded,
                          size: 28, color: Color(0xFF10B981)),
                      SizedBox(height: 6),
                      Text(
                        'All caught up!',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'No unread notifications at this time',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ...pendingLeaves.take(4).map((leave) {
              return PopupMenuItem<String>(
                value: 'leave:${leave.id}',
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.date_range_rounded,
                            size: 16, color: Color(0xFFD97706)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Leave Request: ${leave.employeeName.isNotEmpty ? leave.employeeName : leave.staffId}',
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "${leave.leaveType} • ${leave.daysCount} day${leave.daysCount > 1 ? 's' : ''} (${leave.fromDate})",
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          const PopupMenuDivider(),
          const PopupMenuItem<String>(
            value: 'view_all',
            child: Center(
              child: Text(
                'View Leave Management →',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
          ),
        ];
      },
      onSelected: (val) {
        if (val == 'mark_all_read') {
          hrProvider.markAllNotificationsAsRead();
        } else if (val.startsWith('leave:')) {
          final id = val.split(':')[1];
          hrProvider.markNotificationAsRead(id);
          hrProvider.setScreen('leave-management');
        } else if (val == 'view_all') {
          hrProvider.setScreen('leave-management');
        }
      },
    );
  }

  static void showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.tune, color: Color(0xFF2563EB)),
            SizedBox(width: 8),
            Text('System Configuration',
                style: TextStyle(fontFamily: 'Plus Jakarta Sans')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'LY SOFTWARE HR Portal Configuration',
              style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.bold,
                  fontSize: 15),
            ),
            const SizedBox(height: 12),
            _buildConfigRow('API Base URL', AppConfig.apiBaseUrl),
            _buildConfigRow('Environment', 'Production / Staging Ready'),
            _buildConfigRow('HR Portal Version', '1.0.0+1'),
            _buildConfigRow('Branding', 'LY SOFTWARE'),
            _buildConfigRow(
                'Role Authorization', 'HR Manager (Full Admin Privileges)'),
            const SizedBox(height: 12),
            const Text(
              'Note: Role-based access control (RBAC) enforces JWT Bearer tokens for all protected HR endpoints.',
              style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 11,
                  color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close',
                style: TextStyle(fontFamily: 'Plus Jakarta Sans')),
          ),
        ],
      ),
    );
  }

  static Widget _buildConfigRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64);
}
