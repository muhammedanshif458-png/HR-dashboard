import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/hr_provider.dart';
import '../../widgets/birthday_section.dart';
import '../../widgets/header.dart';
import '../../widgets/sidebar.dart';
import '../../widgets/page_header.dart';

class StaffPortalView extends StatelessWidget {
  const StaffPortalView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HRProvider>();
    final user = provider.currentUser;
    final now = DateTime.now();
    final todayBirthdays = provider.todayBirthdays;

    return Scaffold(
      appBar: const Header(),
      drawer: const AppSidebar(isDrawer: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              eyebrow: 'LY Software • Staff Self-Service Portal',
              title: user != null
                  ? 'Welcome, ${user.name.split(' ').first}!'
                  : 'Staff Portal',
              subtitle:
                  'Your personal dashboard for attendance, leaves, and assigned tasks.',
            ),
            const SizedBox(height: 24),

            // ── BIRTHDAY CELEBRATION SECTION ──────────────────────────────
            const BirthdayCelebrationSection(isHRView: false),
            const SizedBox(height: 20),

            // ── MY PROFILE CARD ───────────────────────────────────────────
            if (user != null) ...[
              const Text(
                'MY PROFILE',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 1.1),
              ),
              const SizedBox(height: 10),
              _buildProfileCard(user),
              const SizedBox(height: 28),
            ],

            // ── QUICK ACTIONS ─────────────────────────────────────────────
            const Text(
              'QUICK ACTIONS',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 1.1),
            ),
            const SizedBox(height: 10),
            LayoutBuilder(builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildActionCard(
                    icon: Icons.how_to_reg_outlined,
                    label: 'Attendance',
                    description: 'View your check-in records',
                    color: const Color(0xFF10B981),
                    width: isWide
                        ? (constraints.maxWidth - 48) / 3
                        : constraints.maxWidth,
                    onTap: () => provider.navigateToAttendance(),
                  ),
                  _buildActionCard(
                    icon: Icons.beach_access_outlined,
                    label: 'My Leaves',
                    description: 'Apply or check leave status',
                    color: const Color(0xFF3B82F6),
                    width: isWide
                        ? (constraints.maxWidth - 48) / 3
                        : constraints.maxWidth,
                    onTap: () => provider.navigateToLeaveManagement(),
                  ),
                  _buildActionCard(
                    icon: Icons.check_box_outlined,
                    label: 'My Tasks',
                    description: 'View assigned tasks & deadlines',
                    color: const Color(0xFF8B5CF6),
                    width: isWide
                        ? (constraints.maxWidth - 48) / 3
                        : constraints.maxWidth,
                    onTap: () => provider.navigateToTasks(),
                  ),
                ],
              );
            }),
            const SizedBox(height: 28),

            // ── TODAY INFO ────────────────────────────────────────────────
            const Text(
              "TODAY'S SUMMARY",
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 1.1),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.shade100,
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.today, color: Color(0xFF2563EB), size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(now),
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${todayBirthdays.length} birthday celebration${todayBirthdays.length != 1 ? 's' : ''} today',
                        style: TextStyle(
                          fontSize: 13,
                          color: todayBirthdays.isNotEmpty
                              ? const Color(0xFFDB2777)
                              : Colors.grey.shade500,
                          fontWeight: todayBirthdays.isNotEmpty
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  )),
                  if (todayBirthdays.isNotEmpty)
                    const Text('🎂', style: TextStyle(fontSize: 28)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(dynamic user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF2563EB).withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6))
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ),
          const SizedBox(width: 16),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.name,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 4),
              Text(
                  '${user.designation.isNotEmpty ? user.designation : user.role} • ${user.department}',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.8))),
              const SizedBox(height: 6),
              Row(children: [
                _statusChip(user.workMode == 'WFH' ? '🏠 WFH' : '🏢 Office'),
                const SizedBox(width: 8),
                _statusChip('✅ Active'),
              ]),
            ],
          )),
          if (user.salary > 0)
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(
                '${user.salaryCurrency} ${user.salary.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              Text('/ month',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.7))),
            ]),
        ],
      ),
    );
  }

  Widget _statusChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required double width,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: width,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                  color: color.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 14)),
                Text(description,
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            )),
            Icon(Icons.arrow_forward_ios,
                size: 14, color: Colors.grey.shade400),
          ]),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }
}
