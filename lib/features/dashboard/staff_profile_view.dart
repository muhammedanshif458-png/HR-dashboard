import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import '../../providers/hr_provider.dart';
import '../../models/hr_document.dart';
import '../../models/staff.dart';
import '../../widgets/modals.dart';
import '../../widgets/document_modals.dart';
import '../../widgets/document_preview_modal.dart';
import '../../widgets/medical_document_preview_dialog.dart';
import '../../utils/file_download_helper.dart';
import '../../utils/date_time_utils.dart';

class StaffProfileView extends StatefulWidget {
  const StaffProfileView({super.key});

  @override
  State<StaffProfileView> createState() => _StaffProfileViewState();
}

class _StaffProfileViewState extends State<StaffProfileView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _documentCategoryFilter = 'All';
  String _documentStatusFilter = 'active';
  String? _requestedDailyUpdatesForStaffId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatUpdateTime(String? value) {
    if (value == null || value.isEmpty) return '';
    try {
      final time = DateTime.parse(value).toLocal();
      final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute ${time.hour >= 12 ? 'PM' : 'AM'}';
    } catch (_) {
      return value;
    }
  }

  Future<void> _deactivateStaff(
      BuildContext context, HRProvider hrProvider, Staff staff) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B)),
            SizedBox(width: 8),
            Text('Deactivate Employee'),
          ],
        ),
        content: Text(
          'Are you sure you want to deactivate ${staff.name}? The employee will no longer be able to log in, but their historical records will be preserved.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final success = await hrProvider.deactivateStaff(staff.id);
    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${staff.name} has been deactivated.'),
            backgroundColor: const Color(0xFFF59E0B),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(hrProvider.apiStaffError.isNotEmpty
              ? hrProvider.apiStaffError
              : 'Could not deactivate employee.'),
        ));
      }
    }
  }

  Future<void> _reactivateStaff(
      BuildContext context, HRProvider hrProvider, Staff staff) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text('Reactivate Employee'),
          ],
        ),
        content: Text(
          'Are you sure you want to reactivate ${staff.name}? The employee account will be restored to active status and login access will be re-enabled.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reactivate'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final success = await hrProvider.reactivateStaff(staff.id);
    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${staff.name} has been reactivated.'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(hrProvider.apiStaffError.isNotEmpty
              ? hrProvider.apiStaffError
              : 'Could not reactivate employee.'),
        ));
      }
    }
  }

  Future<void> _resignStaff(
      BuildContext context, HRProvider hrProvider, Staff staff) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.assignment_return_outlined, color: Colors.red),
            SizedBox(width: 8),
            Text('Mark Employee as Resigned'),
          ],
        ),
        content: Text(
          'Are you sure you want to mark ${staff.name} as resigned? This formally records their resignation and closes active access.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Mark Resigned'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final success = await hrProvider.resignStaff(staff.id);
    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${staff.name} has been marked as resigned.'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(hrProvider.apiStaffError.isNotEmpty
              ? hrProvider.apiStaffError
              : 'Could not mark employee as resigned.'),
        ));
      }
    }
  }

  Future<void> _deleteStaff(
      BuildContext context, HRProvider hrProvider, Staff staff) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_outlined, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Employee'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete ${staff.name}? This will remove the employee record from the directory while preserving their historical records.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final success = await hrProvider.deleteEmployee(staff.id);
    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${staff.name} has been deleted.'),
            backgroundColor: Colors.red,
          ),
        );
        hrProvider.setScreen('employees');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(hrProvider.apiStaffError.isNotEmpty
              ? hrProvider.apiStaffError
              : 'Could not delete employee.'),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hrProvider = context.watch<HRProvider>();
    final staffId = hrProvider.selectedStaffId;
    final staff = hrProvider.employeeDirectory
        .where((s) => s.id == staffId)
        .firstOrNull;

    if (staff == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (hrProvider.isEmployeeDetailLoading)
                const CircularProgressIndicator()
              else
                Text(
                    hrProvider.employeeDetailError ?? 'Staff member not found'),
              const SizedBox(height: 16),
              if (hrProvider.employeeDetailError != null)
                ElevatedButton(
                  onPressed: hrProvider.selectedStaffId == null
                      ? null
                      : () => hrProvider
                          .fetchEmployeeDetails(hrProvider.selectedStaffId!),
                  child: const Text('Retry'),
                ),
              ElevatedButton(
                onPressed: () => hrProvider.setScreen('hr-dashboard'),
                child: const Text('Back to Dashboard'),
              ),
            ],
          ),
        ),
      );
    }

    final staffAttendance = hrProvider.apiAttendanceRecords
        .where((a) =>
            a.staffId == staff.id ||
            a.employeeName.toLowerCase() == staff.name.toLowerCase())
        .toList();
    if (_requestedDailyUpdatesForStaffId != staff.id) {
      _requestedDailyUpdatesForStaffId = staff.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || hrProvider.selectedStaffId != staff.id) return;
        hrProvider.loadEmployeeDailyUpdates(staff.id);
      });
    }
    final updatesBelongToCurrentStaff =
        hrProvider.employeeDailyUpdatesStaffId == staff.id;
    final staffUpdates = updatesBelongToCurrentStaff
        ? hrProvider.employeeDailyUpdates
        : const [];
    final staffUpdatesLoading = !updatesBelongToCurrentStaff ||
        hrProvider.isEmployeeDailyUpdatesLoading;
    final staffUpdatesError = updatesBelongToCurrentStaff
        ? hrProvider.employeeDailyUpdatesError
        : null;
    final staffLeaves = hrProvider.apiLeaveRecords
        .where((l) =>
            l.staffId == staff.id ||
            l.employeeName.toLowerCase() == staff.name.toLowerCase() ||
            l.employeeEmail.toLowerCase() == staff.email.toLowerCase())
        .toList();

    final isCompact = MediaQuery.sizeOf(context).width < 1100;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => hrProvider.setScreen('hr-dashboard'),
        ),
        title: const Text('Staff Profile',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: isCompact
            ? [
                PopupMenuButton<String>(
                  tooltip: 'Profile actions',
                  onSelected: (action) {
                    switch (action) {
                      case 'document':
                        DocumentModals.showAddDocumentModal(context, staff);
                        break;
                      case 'salary':
                        Modals.showEditSalaryModal(context, staff);
                        break;
                      case 'salary-history':
                        Modals.showSalaryHistoryModal(context, staff);
                        break;
                      case 'edit':
                        Modals.showEditStaffModal(context, staff);
                        break;
                      case 'deactivate':
                        _deactivateStaff(context, hrProvider, staff);
                        break;
                      case 'reactivate':
                        _reactivateStaff(context, hrProvider, staff);
                        break;
                      case 'resign':
                        _resignStaff(context, hrProvider, staff);
                        break;
                      case 'delete':
                        _deleteStaff(context, hrProvider, staff);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                        value: 'document', child: Text('Add Document')),
                    const PopupMenuItem(
                        value: 'salary', child: Text('Edit Salary')),
                    const PopupMenuItem(
                        value: 'salary-history', child: Text('Salary History')),
                    const PopupMenuItem(
                        value: 'edit', child: Text('Edit Staff')),
                    if (staff.status == 'active') ...[
                      const PopupMenuItem(
                          value: 'deactivate', child: Text('Deactivate Employee')),
                      const PopupMenuItem(
                          value: 'resign', child: Text('Mark as Resigned')),
                    ],
                    if (staff.status == 'inactive') ...[
                      const PopupMenuItem(
                          value: 'reactivate', child: Text('Reactivate Employee')),
                      const PopupMenuItem(
                          value: 'resign', child: Text('Mark as Resigned')),
                    ],
                    if (hrProvider.isHRAdmin)
                      const PopupMenuItem(
                          value: 'delete', child: Text('Delete Employee')),
                  ],
                ),
              ]
            : [
                ElevatedButton.icon(
                  onPressed: () =>
                      DocumentModals.showAddDocumentModal(context, staff),
                  icon: const Icon(Icons.upload_file, size: 16),
                  label: const Text('Add Document'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: () => Modals.showEditSalaryModal(context, staff),
                  icon: const Icon(Icons.currency_rupee,
                      size: 16, color: Color(0xFF10B981)),
                  label: const Text('Edit Salary',
                      style: TextStyle(color: Color(0xFF10B981))),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: () =>
                      Modals.showSalaryHistoryModal(context, staff),
                  icon: const Icon(Icons.history, size: 16),
                  label: const Text('Salary History'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: () => Modals.showEditStaffModal(context, staff),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit Staff'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                if (staff.status == 'active') ...[
                  const SizedBox(width: 4),
                  TextButton.icon(
                    onPressed: () =>
                        _deactivateStaff(context, hrProvider, staff),
                    icon: const Icon(Icons.person_off_outlined,
                        size: 16, color: Color(0xFFF59E0B)),
                    label: const Text('Deactivate Employee',
                        style: TextStyle(color: Color(0xFFF59E0B))),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 4),
                  TextButton.icon(
                    onPressed: () =>
                        _resignStaff(context, hrProvider, staff),
                    icon: const Icon(Icons.exit_to_app,
                        size: 16, color: Colors.red),
                    label: const Text('Mark as Resigned',
                        style: TextStyle(color: Colors.red)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
                if (staff.status == 'inactive') ...[
                  const SizedBox(width: 4),
                  TextButton.icon(
                    onPressed: () =>
                        _reactivateStaff(context, hrProvider, staff),
                    icon: const Icon(Icons.how_to_reg_outlined,
                        size: 16, color: Color(0xFF10B981)),
                    label: const Text('Reactivate Employee',
                        style: TextStyle(color: Color(0xFF10B981))),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 4),
                  TextButton.icon(
                    onPressed: () =>
                        _resignStaff(context, hrProvider, staff),
                    icon: const Icon(Icons.exit_to_app,
                        size: 16, color: Colors.red),
                    label: const Text('Mark as Resigned',
                        style: TextStyle(color: Colors.red)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
                if (hrProvider.isHRAdmin) ...[
                  const SizedBox(width: 4),
                  TextButton.icon(
                    onPressed: () =>
                        _deleteStaff(context, hrProvider, staff),
                    icon: const Icon(Icons.delete_outline,
                        size: 16, color: Color(0xFFDC2626)),
                    label: const Text('Delete Employee',
                        style: TextStyle(color: Color(0xFFDC2626))),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
                const SizedBox(width: 12),
              ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Hero Card
            if (hrProvider.isEmployeeDetailLoading)
              const LinearProgressIndicator(),
            if (hrProvider.employeeDetailError != null)
              MaterialBanner(
                content: Text(
                    'Could not refresh employee details: ${hrProvider.employeeDetailError}'),
                leading: const Icon(Icons.error_outline),
                actions: [
                  TextButton(
                    onPressed: () => hrProvider.fetchEmployeeDetails(staff.id),
                    child: const Text('Retry'),
                  )
                ],
              ),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: staff.department == 'Tech'
                          ? const Color(0xFFEFF6FF)
                          : const Color(0xFFFDF2F8),
                      child: Text(
                        staff.name.isNotEmpty ? staff.name[0] : 'U',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: staff.department == 'Tech'
                              ? const Color(0xFF2563EB)
                              : const Color(0xFFDB2777),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(staff.name,
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(12)),
                                child: Text(staff.department,
                                    style: TextStyle(
                                        color: Colors.blue.shade700,
                                        fontSize: 12)),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                key: const Key('staff_profile_status_badge'),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: staff.status == 'resigned'
                                      ? Colors.red.shade50
                                      : staff.status == 'inactive'
                                          ? const Color(0xFFFEF3C7)
                                          : staff.status == 'terminated'
                                              ? Colors.grey.shade100
                                              : (staff.onLeaveToday
                                                  ? Colors.purple.shade50
                                                  : Colors.green.shade50),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  staff.status == 'resigned'
                                      ? 'Resigned'
                                      : staff.status == 'inactive'
                                          ? 'Inactive'
                                          : staff.status == 'terminated'
                                              ? 'Terminated'
                                              : (staff.onLeaveToday
                                                  ? 'On Leave Today'
                                                  : 'Active'),
                                  style: TextStyle(
                                    color: staff.status == 'resigned'
                                        ? Colors.red.shade700
                                        : staff.status == 'inactive'
                                            ? const Color(0xFFD97706)
                                            : staff.status == 'terminated'
                                                ? Colors.grey.shade800
                                                : (staff.onLeaveToday
                                                    ? Colors.purple.shade700
                                                    : Colors.green.shade700),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 16,
                            runSpacing: 8,
                            children: [
                              Row(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.email,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(staff.email)
                              ]),
                              Row(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.phone,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(staff.phoneNumber)
                              ]),
                              Row(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.badge,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(staff.designation.isNotEmpty
                                    ? staff.designation
                                    : staff.role)
                              ]),
                              Row(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.home_work,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text('Mode: ${staff.workMode}')
                              ]),
                              Row(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.currency_rupee,
                                    size: 16, color: Color(0xFF10B981)),
                                const SizedBox(width: 4),
                                Text(
                                  'Salary: ${staff.salaryCurrency} ${staff.salary.toStringAsFixed(0)} / mo',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF047857),
                                  ),
                                ),
                              ]),
                              Row(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.event_available,
                                    size: 16, color: Color(0xFF6366F1)),
                                const SizedBox(width: 4),
                                Text(
                                  'Paid Leave: ${staff.paidLeaveAllowance} day/mo',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF4338CA),
                                  ),
                                ),
                              ]),
                              Row(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.calendar_today,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text('Joined ${staff.joinDate}')
                              ]),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Documents Section Card (prominent for both Tech and Telecalling)
            _buildDocumentsSection(context, staff, hrProvider),
            const SizedBox(height: 24),

            // 4 Column / Responsive Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 900;
                final colWidth = isWide
                    ? (constraints.maxWidth - 24) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 24,
                  runSpacing: 24,
                  children: [
                    // Attendance Log Card
                    SizedBox(
                      width: colWidth,
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.access_time,
                                      size: 18, color: Color(0xFF2563EB)),
                                  const SizedBox(width: 8),
                                  Text(
                                      'Attendance History (${staffAttendance.length})',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ...staffAttendance.map((att) => Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(8)),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(formatAttendanceDate(att.date),
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            Text(
                                              att.isLate
                                                  ? (att.minutesLate != null && att.minutesLate! > 0
                                                      ? 'Late Check-in (${att.minutesLate}m)'
                                                      : 'Late Check-in')
                                                  : (att.scheduleConfigured
                                                      ? 'On Time'
                                                      : '—'),
                                              style: TextStyle(
                                                  color: att.isLate
                                                      ? Colors.orange
                                                      : (att.scheduleConfigured
                                                          ? Colors.green
                                                          : Colors.grey),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                            'In: ${formatAttendanceTime(att.checkInTime)} | Out: ${att.checkOutTime != null && att.checkOutTime!.isNotEmpty && att.checkOutTime != "—" ? (att.checkOutTime == "Active" ? "Active" : formatAttendanceTime(att.checkOutTime)) : (att.checkInTime != null ? "Active" : "—")}',
                                            style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 12)),
                                        Text(
                                            'Worked: ${att.workedDuration} · Break: ${att.breakDuration} (${att.workMode})',
                                            style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 11)),
                                      ],
                                    ),
                                  )),
                              if (staffAttendance.isEmpty)
                                const Text('No attendance records found.',
                                    style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Leave History Card
                    SizedBox(
                      width: colWidth,
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Builder(builder: (context) {
                                final approvedTotal = staffLeaves
                                    .where((l) =>
                                        l.status.toLowerCase() == 'approved')
                                    .fold<double>(
                                        0.0, (sum, l) => sum + l.totalDays);
                                final approvedStr = approvedTotal % 1 == 0
                                    ? '${approvedTotal.toInt()}.0'
                                    : approvedTotal.toString();
                                return Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.event_note,
                                            size: 18, color: Color(0xFF2563EB)),
                                        const SizedBox(width: 8),
                                        Text(
                                            'Leave History (${staffLeaves.length})',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16)),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                            color: const Color(0xFFBFDBFE)),
                                      ),
                                      child: Text(
                                        'Approved Leaves Taken: $approvedStr ${approvedTotal == 1.0 ? "day" : "days"}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1D4ED8),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                              const SizedBox(height: 16),
                              ...staffLeaves.map((leave) => Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(8)),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                                leave.leaveType
                                                        .toLowerCase()
                                                        .endsWith('leave')
                                                    ? '${leave.leaveType} (${leave.durationDisplay})'
                                                    : '${leave.leaveType} Leave (${leave.durationDisplay})',
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: leave.status ==
                                                        'Approved'
                                                    ? Colors.green.shade50
                                                    : (leave.status ==
                                                            'Rejected'
                                                        ? Colors.red.shade50
                                                        : Colors.amber.shade50),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                leave.status,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: leave.status ==
                                                          'Approved'
                                                      ? Colors.green.shade700
                                                      : (leave.status ==
                                                              'Rejected'
                                                          ? Colors.red.shade700
                                                          : Colors
                                                              .amber.shade800),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                            leave.formattedFromDate ==
                                                    leave.formattedToDate
                                                ? leave.formattedFromDate
                                                : '${leave.formattedFromDate} to ${leave.formattedToDate}',
                                            style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 12)),
                                        Text('Reason: "${leave.reason}"',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontStyle: FontStyle.italic)),
                                        if (leave.hasMedicalProof)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 6.0),
                                            child: InkWell(
                                              key: ValueKey(
                                                  'preview_medical_${leave.id}'),
                                              onTap: () {
                                                MedicalDocumentPreviewDialog
                                                    .show(
                                                  context,
                                                  leave: leave,
                                                );
                                              },
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFFEFF6FF),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  border: Border.all(
                                                      color: const Color(
                                                          0xFFBFDBFE)),
                                                ),
                                                child: const Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.attachment,
                                                        size: 13,
                                                        color:
                                                            Color(0xFF2563EB)),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      'Medical Document Attached • Click to Preview',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color:
                                                            Color(0xFF1D4ED8),
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        if (leave.rejectionReason != null)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 4.0),
                                            child: Text(
                                                'HR Remark: ${leave.rejectionReason}',
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.red)),
                                          ),
                                      ],
                                    ),
                                  )),
                              if (staffLeaves.isEmpty)
                                const Text('No leave requests submitted.',
                                    style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Staff Daily Work Updates
                    SizedBox(
                      width: colWidth,
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.assignment_outlined,
                                      size: 18, color: Color(0xFF2563EB)),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Staff Daily Work Updates',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                  ),
                                  IconButton(
                                    key: const ValueKey(
                                        'refresh_staff_daily_updates'),
                                    tooltip: 'Refresh daily work updates',
                                    visualDensity: VisualDensity.compact,
                                    onPressed: staffUpdatesLoading
                                        ? null
                                        : () => hrProvider
                                            .loadEmployeeDailyUpdates(staff.id),
                                    icon: const Icon(Icons.refresh, size: 18),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (staffUpdatesLoading) ...[
                                const LinearProgressIndicator(),
                                const SizedBox(height: 12),
                                const Text('Loading daily work updates…',
                                    style: TextStyle(color: Colors.grey)),
                              ],
                              if (staffUpdatesError != null) ...[
                                Text(
                                  'Unable to load daily work updates: $staffUpdatesError',
                                  style: const TextStyle(
                                      color: Color(0xFFB91C1C), fontSize: 13),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () => hrProvider
                                        .loadEmployeeDailyUpdates(staff.id),
                                    icon: const Icon(Icons.refresh, size: 16),
                                    label: const Text('Retry'),
                                  ),
                                ),
                              ],
                              ...staffUpdates.map((update) => Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        border: Border.all(
                                            color: Colors.grey.shade200),
                                        borderRadius: BorderRadius.circular(8)),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (update.title.isNotEmpty) ...[
                                          Text(update.title,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14)),
                                          const SizedBox(height: 4),
                                        ],
                                        Text(update.updateText,
                                            style: const TextStyle(
                                                fontSize: 13, height: 1.4)),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 12,
                                          runSpacing: 4,
                                          children: [
                                            if (update.employeeName.isNotEmpty)
                                              Text(update.employeeName,
                                                  style: TextStyle(
                                                      color:
                                                          Colors.grey.shade600,
                                                      fontSize: 11)),
                                            Text('Submitted: ${update.date}',
                                                style: TextStyle(
                                                    color: Colors.grey.shade600,
                                                    fontSize: 11)),
                                            if (_formatUpdateTime(
                                                    update.createdAt)
                                                .isNotEmpty)
                                              Text(
                                                  'Time: ${_formatUpdateTime(update.createdAt)}',
                                                  style: TextStyle(
                                                      color:
                                                          Colors.grey.shade600,
                                                      fontSize: 11)),
                                            if (update.department.isNotEmpty)
                                              Text(update.department,
                                                  style: TextStyle(
                                                      color:
                                                          Colors.grey.shade600,
                                                      fontSize: 11)),
                                            if (update.employeeId.isNotEmpty)
                                              Text(update.employeeId,
                                                  style: TextStyle(
                                                      color:
                                                          Colors.grey.shade600,
                                                      fontSize: 11)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  )),
                              if (!staffUpdatesLoading &&
                                  staffUpdatesError == null &&
                                  staffUpdates.isEmpty)
                                const Text('No daily work updates submitted.',
                                    style: TextStyle(color: Colors.grey)),
                              if (!staffUpdatesLoading &&
                                  staffUpdatesError == null &&
                                  hrProvider.employeeDailyUpdatesTotalPages > 1)
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                        'Page ${hrProvider.employeeDailyUpdatesPage} of ${hrProvider.employeeDailyUpdatesTotalPages}',
                                        style: const TextStyle(fontSize: 12)),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          tooltip: 'Previous updates page',
                                          onPressed: hrProvider
                                                      .employeeDailyUpdatesPage >
                                                  1
                                              ? () => hrProvider
                                                  .setEmployeeDailyUpdatesPage(
                                                      staff.id,
                                                      hrProvider
                                                              .employeeDailyUpdatesPage -
                                                          1)
                                              : null,
                                          icon: const Icon(Icons.chevron_left),
                                        ),
                                        IconButton(
                                          tooltip: 'Next updates page',
                                          onPressed: hrProvider
                                                      .employeeDailyUpdatesPage <
                                                  hrProvider
                                                      .employeeDailyUpdatesTotalPages
                                              ? () => hrProvider
                                                  .setEmployeeDailyUpdatesPage(
                                                      staff.id,
                                                      hrProvider
                                                              .employeeDailyUpdatesPage +
                                                          1)
                                              : null,
                                          icon: const Icon(Icons.chevron_right),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- HR Documents Section (accessible for both Tech & Telecalling) ---
  Widget _buildDocumentsSection(
      BuildContext context, Staff staff, HRProvider hrProvider) {
    final staffDocs = hrProvider.getDocumentsForStaff(staff.id);
    final filteredDocs = staffDocs.where((document) {
      final categoryMatches = _documentCategoryFilter == 'All' ||
          document.category == _documentCategoryFilter;
      final statusMatches = _documentStatusFilter == 'all' ||
          (_documentStatusFilter == 'archived'
              ? document.status == 'ARCHIVED'
              : document.status != 'ARCHIVED');
      return categoryMatches && statusMatches;
    }).toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hrProvider.isProcessingAction) const LinearProgressIndicator(),
            // Header Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.folder_shared,
                          color: Color(0xFF2563EB), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              const Text(
                                'HR Document Management',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: staff.department == 'Tech'
                                      ? const Color(0xFFEFF6FF)
                                      : const Color(0xFFFDF2F8),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  staff.department,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: staff.department == 'Tech'
                                        ? const Color(0xFF2563EB)
                                        : const Color(0xFFDB2777),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Upload, review, replace, and archive verified employee documents (${staffDocs.length} total)',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    DropdownButton<String>(
                      value: _documentStatusFilter,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(
                            value: 'all', child: Text('All documents')),
                        DropdownMenuItem(
                            value: 'active', child: Text('Active')),
                        DropdownMenuItem(
                            value: 'archived', child: Text('Archived')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _documentStatusFilter = value);
                        }
                      },
                    ),
                    // Category Filter
                    Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<String>(
                        value: _documentCategoryFilter,
                        underline: const SizedBox(),
                        items: ['All', ...DocumentModals.categories].map((c) {
                          return DropdownMenuItem(
                            value: c,
                            child:
                                Text(c, style: const TextStyle(fontSize: 12)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _documentCategoryFilter = val);
                          }
                        },
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: hrProvider.isProcessingAction
                          ? null
                          : () => DocumentModals.showAddDocumentModal(
                              context, staff),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Document'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Documents List / Empty state
            if (hrProvider.isDocumentsLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (hrProvider.employeeDocumentsError != null)
              Column(children: [
                Text(
                    'Could not load documents: ${hrProvider.employeeDocumentsError}',
                    style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => hrProvider.loadEmployeeDocuments(staff.id),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ])
            else if (filteredDocs.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        size: 46, color: Colors.grey.shade400),
                    const SizedBox(height: 10),
                    const Text(
                      'No documents found for this filter',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Click "Add Document" above to upload Resume, ID Proof, Agreements, etc.',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () =>
                          DocumentModals.showAddDocumentModal(context, staff),
                      icon: const Icon(Icons.upload_file, size: 16),
                      label: const Text('Upload Document Now'),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredDocs.length,
                separatorBuilder: (ctx, i) =>
                    Divider(color: Colors.grey.shade100),
                itemBuilder: (ctx, i) {
                  final doc = filteredDocs[i];
                  return _buildDocumentRow(
                      context, doc, staff.id, hrProvider.isProcessingAction);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentRow(BuildContext context, HRDocumentItem doc,
      String employeeId, bool isProcessing) {
    Color badgeColor = const Color(0xFF2563EB);
    if (doc.category == 'Medical Certificate') badgeColor = Colors.purple;
    if (doc.category == 'Identity Proof') badgeColor = Colors.teal;
    if (doc.category == 'Offer Letter' ||
        doc.category == 'Appointment Letter') {
      badgeColor = Colors.indigo;
    }
    if (doc.category == 'Employment Agreement') badgeColor = Colors.blueGrey;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Icon based on type
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color:
                  doc.isPdf ? const Color(0xFFFEE2E2) : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              doc.isPdf ? Icons.picture_as_pdf : Icons.image,
              color:
                  doc.isPdf ? const Color(0xFFDC2626) : const Color(0xFF2563EB),
              size: 26,
            ),
          ),
          const SizedBox(width: 14),

          // Title, category, and metadata
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      doc.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        doc.category,
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (doc.status == 'ARCHIVED')
                      const Chip(label: Text('Archived')),
                    if (doc.version > 1) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'v${doc.version}',
                          style: TextStyle(
                            color: Colors.amber.shade900,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Text(
                      'File: ${doc.originalName} (${doc.formattedSize})',
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                    Text(
                      'Uploaded: ${doc.formattedDate} by ${doc.uploadedBy}',
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                    if (doc.issueDate.isNotEmpty)
                      Text('Issued: ${doc.issueDate}',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600)),
                    if (doc.expiryDate.isNotEmpty)
                      Text('Expires: ${doc.expiryDate}',
                          style: const TextStyle(
                              fontSize: 11,
                              color: Colors.red,
                              fontWeight: FontWeight.bold)),
                  ],
                ),
                if (doc.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Notes: ${doc.description}',
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),

          // Actions: Preview, Download, Replace, Archive
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                key: ValueKey('doc_preview_${doc.id}'),
                onPressed: isProcessing
                    ? null
                    : () => _previewDocument(context, doc, employeeId),
                icon: const Icon(Icons.remove_red_eye_outlined, size: 14),
                label: const Text('Preview'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  side: const BorderSide(color: Color(0xFF93C5FD)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  textStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              OutlinedButton.icon(
                key: ValueKey('doc_download_${doc.id}'),
                onPressed:
                    isProcessing ? null : () => _downloadDocument(context, doc),
                icon: const Icon(Icons.download_rounded, size: 14),
                label: const Text('Download'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F766E),
                  side: const BorderSide(color: Color(0xFF99F6E4)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  textStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              if (doc.status != 'ARCHIVED') ...[
                IconButton(
                  icon: const Icon(Icons.sync, size: 18, color: Colors.amber),
                  tooltip: 'Replace Document',
                  onPressed: isProcessing
                      ? null
                      : () => DocumentModals.showReplaceDocumentModal(
                          context, doc, employeeId),
                ),
                IconButton(
                  icon: const Icon(Icons.archive_outlined,
                      size: 18, color: Colors.orange),
                  tooltip: 'Archive Document',
                  onPressed: isProcessing
                      ? null
                      : () => DocumentModals.showArchiveConfirmModal(
                          context, doc, employeeId),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _previewDocument(
      BuildContext context, HRDocumentItem doc, String employeeId) {
    DocumentPreviewModal.show(
      context,
      doc: doc,
      employeeId: employeeId,
    );
  }

  Future<void> _downloadDocument(
      BuildContext context, HRDocumentItem doc) async {
    final provider = context.read<HRProvider>();

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading "${doc.title}"...'),
        duration: const Duration(seconds: 2),
      ),
    );

    final downloaded = await provider.downloadEmployeeDocument(doc.id);
    if (!context.mounted) return;

    if (downloaded == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            provider.employeeDocumentsError ?? 'Document download failed.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final bytes = Uint8List.fromList(downloaded.bytes);
    if (bytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Downloaded file is empty.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    // Safety validation: Never download JSON error payloads or HTML error pages as documents
    if (bytes.length < 500) {
      final text = String.fromCharCodes(bytes.take(200)).trimLeft();
      if (text.startsWith('{"success":false') ||
          text.startsWith('{"error"') ||
          text.startsWith('{"statusCode":4') ||
          text.startsWith('{"statusCode":5') ||
          text.toLowerCase().startsWith('<!doctype html') ||
          text.toLowerCase().startsWith('<html')) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Server returned an error instead of the document file.'),
          backgroundColor: Colors.red,
        ));
        return;
      }
    }

    final fileName = doc.originalName.isNotEmpty
        ? doc.originalName
        : (doc.fileName.isNotEmpty ? doc.fileName : 'document');

    final cType = downloaded.contentType.isNotEmpty
        ? downloaded.contentType
        : (doc.isPdf
            ? 'application/pdf'
            : (doc.isImage ? 'image/png' : 'application/octet-stream'));

    try {
      final success = await FileDownloadHelper.downloadFile(
        bytes: bytes,
        fileName: fileName,
        mimeType: cType,
      );

      if (!context.mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Document "$fileName" downloaded successfully.'),
          backgroundColor: Colors.green,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Document download was cancelled or not saved.'),
          backgroundColor: Colors.orange,
        ));
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not save document: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }
}
