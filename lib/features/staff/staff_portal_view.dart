import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/hr_provider.dart';
import '../../widgets/birthday_section.dart';
import '../../widgets/header.dart';
import '../../widgets/sidebar.dart';
import '../../widgets/page_header.dart';
import '../../utils/date_time_utils.dart';

class StaffPortalView extends StatefulWidget {
  const StaffPortalView({super.key});

  @override
  State<StaffPortalView> createState() => _StaffPortalViewState();
}

class _StaffPortalViewState extends State<StaffPortalView> {
  String _selectedWorkMode = 'Office';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final prov = context.read<HRProvider>();
        if (!prov.hasLoadedStaffAttendance && !prov.isStaffAttendanceLoading) {
          prov.loadStaffAttendance();
        }
      }
    });
  }

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
                  'Your personal dashboard for attendance, punch logs, and internal collaboration.',
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

            // ── ATTENDANCE & PUNCH MANAGEMENT ─────────────────────────────
            const Text(
              'ATTENDANCE & TIME TRACKING',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 1.1),
            ),
            const SizedBox(height: 10),
            _buildAttendanceCard(context, provider),
            const SizedBox(height: 28),

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
                    icon: Icons.forum_outlined,
                    label: 'Department Chat',
                    description: 'Collaborate with your team',
                    color: const Color(0xFF2563EB),
                    width: isWide
                        ? (constraints.maxWidth - 32) / 2
                        : constraints.maxWidth,
                    onTap: () => provider.setScreen('dept-chat'),
                  ),
                  _buildActionCard(
                    icon: Icons.chat_bubble_outline,
                    label: 'Direct Messages',
                    description: 'Internal communications info',
                    color: const Color(0xFF8B5CF6),
                    width: isWide
                        ? (constraints.maxWidth - 32) / 2
                        : constraints.maxWidth,
                    onTap: () => provider.setScreen('chat'),
                  ),
                ],
              );
            }),
            const SizedBox(height: 28),

            // ── RECENT ATTENDANCE HISTORY ─────────────────────────────────
            const Text(
              'RECENT ATTENDANCE LOGS',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 1.1),
            ),
            const SizedBox(height: 10),
            _buildAttendanceHistoryTable(provider),
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

  Widget _buildAttendanceCard(BuildContext context, HRProvider provider) {
    final att = provider.todayStaffAttendance;
    final isLoading = provider.isStaffAttendanceLoading;
    final error = provider.staffAttendanceError;

    final isCheckedIn = att != null &&
        att.checkInTime != null &&
        att.checkInTime!.isNotEmpty &&
        (att.checkOutTime == null ||
            att.checkOutTime == 'Active' ||
            att.checkOutTime!.isEmpty);

    final isShiftCompleted = att != null &&
        att.checkOutTime != null &&
        att.checkOutTime!.isNotEmpty &&
        att.checkOutTime != 'Active';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.timer_outlined,
                        color: Color(0xFF2563EB), size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Attendance Punch',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Asia/Kolkata (IST)',
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh,
                        size: 18, color: Color(0xFF64748B)),
                tooltip: 'Refresh attendance status',
                onPressed:
                    isLoading ? null : () => provider.loadStaffAttendance(),
              ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      size: 16, color: Color(0xFFDC2626)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      error,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF991B1B)),
                    ),
                  ),
                  TextButton(
                    onPressed: () => provider.loadStaffAttendance(),
                    child: const Text('Retry', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildAttendanceMetric(
                  label: 'Status',
                  value: isCheckedIn
                      ? 'Checked In'
                      : (isShiftCompleted ? 'Completed' : 'Not Checked In'),
                  color: isCheckedIn
                      ? const Color(0xFF10B981)
                      : (isShiftCompleted
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFF59E0B)),
                ),
              ),
              Expanded(
                child: _buildAttendanceMetric(
                  label: 'Check-In',
                  value: att?.checkInTime != null
                      ? formatAttendanceTime(att!.checkInTime)
                      : '—',
                  color: const Color(0xFF0F172A),
                ),
              ),
              Expanded(
                child: _buildAttendanceMetric(
                  label: 'Check-Out',
                  value: isCheckedIn
                      ? 'Active'
                      : (att?.checkOutTime != null
                          ? formatAttendanceTime(att!.checkOutTime)
                          : '—'),
                  color: const Color(0xFF0F172A),
                ),
              ),
              Expanded(
                child: _buildAttendanceMetric(
                  label: 'Break Duration',
                  value: (att != null && att.breakDuration.isNotEmpty)
                      ? att.breakDuration
                      : '—',
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              if (!isCheckedIn && !isShiftCompleted) ...[
                DropdownButton<String>(
                  value: _selectedWorkMode,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: 'Office', child: Text('🏢 Office')),
                    DropdownMenuItem(value: 'WFH', child: Text('🏠 WFH')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedWorkMode = val);
                  },
                ),
                const SizedBox(width: 14),
                ElevatedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final ok = await provider.checkInStaff(
                              workMode: _selectedWorkMode);
                          if (context.mounted && ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Check-in recorded successfully'),
                                backgroundColor: Color(0xFF10B981),
                              ),
                            );
                          }
                        },
                  icon: const Icon(Icons.login, size: 16),
                  label: const Text('Check In'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ] else if (isCheckedIn) ...[
                ElevatedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final ok = await provider.checkOutStaff();
                          if (context.mounted && ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Check-out recorded successfully'),
                                backgroundColor: Color(0xFF2563EB),
                              ),
                            );
                          }
                        },
                  icon: const Icon(Icons.logout, size: 16),
                  label: const Text('Check Out'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ] else ...[
                const Text(
                  '✓ Shift completed for today',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF059669),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceMetric({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Color(0xFF94A3B8),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceHistoryTable(HRProvider provider) {
    final records = provider.staffAttendanceHistory;
    final isLoading = provider.isStaffAttendanceLoading;
    final error = provider.staffAttendanceError;

    if (isLoading && records.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null && records.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, size: 18, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(child: Text(error, style: const TextStyle(fontSize: 13))),
            ElevatedButton(
              onPressed: () => provider.loadStaffAttendance(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (records.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Center(
          child: Text(
            'No attendance history records found',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 44,
          dataRowMinHeight: 48,
          dataRowMaxHeight: 52,
          columns: const [
            DataColumn(
                label: Text('Date',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(
                label: Text('Status',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(
                label: Text('Check-In',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(
                label: Text('Check-Out',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(
                label: Text('Duration',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(
                label: Text('Breaks',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          ],
          rows: records.map((att) {
            return DataRow(cells: [
              DataCell(Text(formatAttendanceDate(att.date),
                  style: const TextStyle(fontSize: 12))),
              DataCell(
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: att.status == 'Present'
                        ? const Color(0xFFECFDF5)
                        : (att.status == 'Absent'
                            ? const Color(0xFFFEF2F2)
                            : const Color(0xFFFFFBEB)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    att.status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: att.status == 'Present'
                          ? const Color(0xFF047857)
                          : (att.status == 'Absent'
                              ? const Color(0xFFDC2626)
                              : const Color(0xFFB45309)),
                    ),
                  ),
                ),
              ),
              DataCell(Text(formatAttendanceTime(att.checkInTime),
                  style: const TextStyle(fontSize: 12))),
              DataCell(Text(formatAttendanceTime(att.checkOutTime),
                  style: const TextStyle(fontSize: 12))),
              DataCell(Text(
                  att.workedDuration.isNotEmpty ? att.workedDuration : '—',
                  style: const TextStyle(fontSize: 12))),
              DataCell(Text(
                  att.breakDuration.isNotEmpty ? att.breakDuration : '—',
                  style: const TextStyle(fontSize: 12))),
            ]);
          }).toList(),
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
