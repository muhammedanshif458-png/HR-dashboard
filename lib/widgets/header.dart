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
      elevation: 0.5,
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
      titleSpacing: isWide ? 20 : 0,
      title: isWide
          ? Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 7, color: Color(0xFF10B981)),
                  SizedBox(width: 6),
                  Text(
                    'Live Systems Connected',
                    style: TextStyle(
                      color: Color(0xFF047857),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
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
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF17243A),
                    ),
                  ),
                ],
              ),
            ),
      actions: [
        // Profile Menu
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: PopupMenuButton<String>(
            tooltip: 'User Profile',
            child: Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: const Color(0xFFEFF6FF),
                  child: Text(
                    currentUser.name.isNotEmpty ? currentUser.name[0] : 'U',
                    style: const TextStyle(
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentUser.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      currentUser.role,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                const Icon(Icons.expand_more,
                    size: 16, color: Color(0xFF64748B)),
              ],
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(currentUser.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.black)),
                    Text(currentUser.email,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
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
                            color: Colors.red, fontWeight: FontWeight.w500)),
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

  static void showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.tune, color: Color(0xFF2563EB)),
            SizedBox(width: 8),
            Text('System Configuration'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'LY SOFTWARE HR Portal Configuration',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
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
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
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
