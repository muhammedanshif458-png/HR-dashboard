import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/hr_provider.dart';
import '../../models/staff.dart';
import '../../models/hr_models.dart';
import '../../core/department_helper.dart';
import '../../widgets/modals.dart';

class PayrollView extends StatefulWidget {
  const PayrollView({super.key});

  @override
  State<PayrollView> createState() => _PayrollViewState();
}

class _PayrollViewState extends State<PayrollView> {
  final List<String> _months = [
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

  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    final hrProvider = context.read<HRProvider>();
    _searchController =
        TextEditingController(text: hrProvider.payrollSearchQuery);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!hrProvider.hasLoadedApiPayroll &&
          !hrProvider.isPayrollLoading &&
          hrProvider.payrollError == null) {
        hrProvider.loadPayroll();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hrProvider = context.watch<HRProvider>();
    final currentYear = hrProvider.payrollYear;
    final currentMonth = hrProvider.payrollMonth;

    // Calculate standard working days in month by department
    final daysInMonth = DateTime(currentYear, currentMonth + 1, 0).day;

    int techStandardWorkingDays = 0;
    int teleStandardWorkingDays = 0;

    for (int day = 1; day <= daysInMonth; day++) {
      final dt = DateTime(currentYear, currentMonth, day);
      if (dt.weekday >= DateTime.monday && dt.weekday <= DateTime.friday) {
        techStandardWorkingDays++;
      }
      if (dt.weekday >= DateTime.monday && dt.weekday <= DateTime.saturday) {
        teleStandardWorkingDays++;
      }
    }

    final payrollRecords = hrProvider.filteredPayrollRecords;
    final summary = hrProvider.effectivePayrollSummary;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.payments_outlined,
                    color: Color(0xFF2563EB),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Monthly Payroll Processing',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Department-specific working calendars, attendance matching & leave deduction engine',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Refresh Payroll Data',
                  onPressed: hrProvider.isPayrollLoading
                      ? null
                      : () => hrProvider.loadPayroll(),
                  icon: hrProvider.isPayrollLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh, color: Color(0xFF2563EB)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Payroll preview for ${_months[currentMonth - 1]} $currentYear loaded. Batch finalization mutation is pending backend endpoint implementation.'),
                        backgroundColor: const Color(0xFF059669),
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Process & Finalize Batch'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Error Banner
            if (hrProvider.payrollError != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Color(0xFFDC2626), size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Failed to load payroll data from server: ${hrProvider.payrollError}',
                        style: const TextStyle(
                          color: Color(0xFF991B1B),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      onPressed: () => hrProvider.loadPayroll(),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ],

            // Department Rules Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: Color(0xFF2563EB), size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Active Company Working & Leave Rules',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF475569)),
                            children: [
                              const TextSpan(
                                text: '• Tech Department: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                  text:
                                      'Monday–Friday schedule ($techStandardWorkingDays working days this month). Sat/Sun off.\n'),
                              const TextSpan(
                                text: '• Telecalling Department: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                  text:
                                      'Monday–Saturday schedule ($teleStandardWorkingDays working days this month). Sun off.\n'),
                              const TextSpan(
                                text: '• Company Leave Policy: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const TextSpan(
                                  text:
                                      '1 paid leave day allowance per month applied without salary deduction.'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Summary Metric Cards
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Gross Salary Pool',
                    value:
                        '₹ ${summary.totalPayrollExpenditure.toStringAsFixed(0)}',
                    icon: Icons.account_balance_wallet_outlined,
                    color: const Color(0xFF2563EB),
                    subtitle: '${summary.totalEmployees} Staff Members',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Unpaid Leave Deductions',
                    value: '₹ ${summary.totalDeductions.toStringAsFixed(0)}',
                    icon: Icons.money_off_outlined,
                    color: const Color(0xFFEF4444),
                    subtitle: 'Loss of Pay Applied',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Net Payout Amount',
                    value: '₹ ${summary.totalNetPayout.toStringAsFixed(0)}',
                    icon: Icons.check_circle_outlined,
                    color: const Color(0xFF10B981),
                    subtitle: '${_months[currentMonth - 1]} $currentYear',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Controls & Filter Bar
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Month Selector
                    SizedBox(
                      width: 170,
                      child: DropdownButtonFormField<int>(
                        isExpanded: true,
                        initialValue: currentMonth,
                        decoration: const InputDecoration(
                          labelText: 'Select Month',
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(),
                        ),
                        items: List.generate(12, (index) {
                          return DropdownMenuItem(
                            value: index + 1,
                            child: Text(_months[index]),
                          );
                        }),
                        onChanged: (val) {
                          if (val != null) hrProvider.setPayrollMonth(val);
                        },
                      ),
                    ),

                    // Year Selector
                    SizedBox(
                      width: 140,
                      child: DropdownButtonFormField<int>(
                        isExpanded: true,
                        initialValue: currentYear,
                        decoration: const InputDecoration(
                          labelText: 'Select Year',
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(),
                        ),
                        items: [2024, 2025, 2026, 2027].map((y) {
                          return DropdownMenuItem(
                            value: y,
                            child: Text(y.toString()),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) hrProvider.setPayrollYear(val);
                        },
                      ),
                    ),

                    // Department Filter
                    Builder(builder: (context) {
                      final deptData = DepartmentHelper.buildFilterDropdown(
                        currentValue: hrProvider.payrollDepartment,
                        departments: hrProvider.departments,
                      );
                      return SizedBox(
                        width: 180,
                        child: DropdownButtonFormField<String>(
                          key: ValueKey('payroll_dept_${deptData.value}'),
                          isExpanded: true,
                          value: deptData.value,
                          decoration: const InputDecoration(
                            labelText: 'Department',
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(),
                          ),
                          items: deptData.items,
                          onChanged: (val) {
                            if (val != null) {
                              hrProvider.setPayrollDepartment(val);
                            }
                          },
                        ),
                      );
                    }),

                    // Search Staff
                    SizedBox(
                      width: 240,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search staff by name or role...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    hrProvider.setPayrollSearchQuery('');
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (val) =>
                            hrProvider.setPayrollSearchQuery(val),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Loading indicator
            if (hrProvider.isPayrollLoading) ...[
              const LinearProgressIndicator(
                color: Color(0xFF2563EB),
                backgroundColor: Color(0xFFEFF6FF),
              ),
              const SizedBox(height: 12),
            ],

            // Payroll Breakdown Table
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: payrollRecords.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(48.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off,
                              size: 54, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            hrProvider.payrollError != null
                                ? 'No payroll data available due to server error'
                                : 'No staff records match filter criteria',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            horizontalMargin: 20,
                            columnSpacing: 20,
                            columns: const [
                              DataColumn(
                                  label: Text('Employee',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Department',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Calendar Days',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Actual Present',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Approved Leaves',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Paid / Unpaid',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Payable Days',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Base Salary',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Deduction (LOP)',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Net Pay',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Actions',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                            ],
                            rows: payrollRecords.map((record) {
                              return _buildPayrollDataRow(
                                  context, record, hrProvider);
                            }).toList(),
                          ),
                        ),

                        // Pagination Footer (when live API pagination is active)
                        if (hrProvider.hasLoadedApiPayroll &&
                            hrProvider.payrollTotalPages > 1) ...[
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Showing ${(hrProvider.payrollPage - 1) * hrProvider.payrollLimit + 1} to ${min(hrProvider.payrollPage * hrProvider.payrollLimit, hrProvider.payrollTotal)} of ${hrProvider.payrollTotal} records',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.chevron_left),
                                      onPressed: hrProvider.payrollPage > 1 &&
                                              !hrProvider.isPayrollLoading
                                          ? () => hrProvider.setPayrollPage(
                                              hrProvider.payrollPage - 1)
                                          : null,
                                    ),
                                    Text(
                                      'Page ${hrProvider.payrollPage} of ${hrProvider.payrollTotalPages}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.chevron_right),
                                      onPressed: hrProvider.payrollPage <
                                                  hrProvider
                                                      .payrollTotalPages &&
                                              !hrProvider.isPayrollLoading
                                          ? () => hrProvider.setPayrollPage(
                                              hrProvider.payrollPage + 1)
                                          : null,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildPayrollDataRow(BuildContext context,
      EmployeePayrollRecord record, HRProvider hrProvider) {
    final isTech = record.department.toLowerCase() == 'tech';

    return DataRow(
      cells: [
        // Employee
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                record.name,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              Text(
                record.designation.isNotEmpty
                    ? record.designation
                    : record.employeeId,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),

        // Department
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isTech ? const Color(0xFFEFF6FF) : const Color(0xFFFDF2F8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              record.department,
              style: TextStyle(
                color:
                    isTech ? const Color(0xFF2563EB) : const Color(0xFFDB2777),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        // Calendar Standard Working Days
        DataCell(
          Text(
              '${record.standardWorkingDays} days (${isTech ? 'M-F' : 'M-Sat'})',
              style: const TextStyle(fontSize: 12)),
        ),

        // Actual Present
        DataCell(
          Text('${record.presentDays} days',
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ),

        // Approved Leaves
        DataCell(
          Text('${record.approvedLeaves} days',
              style: TextStyle(
                fontSize: 12,
                color: record.approvedLeaves > 0
                    ? const Color(0xFF8B5CF6)
                    : const Color(0xFF64748B),
                fontWeight: record.approvedLeaves > 0
                    ? FontWeight.bold
                    : FontWeight.normal,
              )),
        ),

        // Paid / Unpaid
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${record.paidLeaveDays} Paid',
                  style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF15803D),
                      fontWeight: FontWeight.bold),
                ),
              ),
              if (record.unpaidLeaveDays > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${record.unpaidLeaveDays} LOP',
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFB91C1C),
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Payable Days
        DataCell(
          Text('${record.payableDays} / ${record.standardWorkingDays}',
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),

        // Base Salary
        DataCell(
          Text('₹ ${record.grossSalary.toStringAsFixed(0)}',
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ),

        // Deductions
        DataCell(
          Text(
            record.deductions > 0
                ? '- ₹ ${record.deductions.toStringAsFixed(0)}'
                : '₹ 0',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: record.deductions > 0
                  ? const Color(0xFFDC2626)
                  : const Color(0xFF16A34A),
            ),
          ),
        ),

        // Net Pay
        DataCell(
          Text(
            '₹ ${record.netPay.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
        ),

        // Actions
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.currency_rupee,
                    size: 16, color: Color(0xFF10B981)),
                tooltip: 'Edit Salary',
                onPressed: () {
                  final staff = hrProvider.staffList.firstWhere(
                    (s) =>
                        s.id == record.id ||
                        (record.employeeId.isNotEmpty &&
                            s.id == record.employeeId),
                    orElse: () => Staff(
                      id: record.id.isNotEmpty ? record.id : record.employeeId,
                      name: record.name,
                      email: '',
                      phoneNumber: '',
                      department: record.department,
                      role: record.designation,
                      joinDate: '',
                      status: record.status.toLowerCase(),
                      onLeaveToday: false,
                      designation: record.designation,
                      salary: record.grossSalary,
                      salaryCurrency: record.salaryCurrency,
                    ),
                  );
                  Modals.showEditSalaryModal(context, staff);
                },
              ),
              IconButton(
                icon: const Icon(Icons.receipt_long_outlined,
                    size: 16, color: Color(0xFF2563EB)),
                tooltip: 'View Payslip Details',
                onPressed: () => _showPayslipDialog(context, record),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showPayslipDialog(BuildContext context, EmployeePayrollRecord record) {
    showDialog(
      context: context,
      builder: (ctx) {
        final isTech = record.department.toLowerCase() == 'tech';
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.receipt, color: Color(0xFF2563EB), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Payslip: ${record.name} — ${_months[record.month - 1]} ${record.year}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPayslipLine('Department', record.department),
                _buildPayslipLine('Designation', record.designation),
                _buildPayslipLine(
                    'Working Schedule', isTech ? 'Mon-Fri' : 'Mon-Sat'),
                _buildPayslipLine('Standard Working Days',
                    '${record.standardWorkingDays} days'),
                _buildPayslipLine(
                    'Actual Present Days', '${record.presentDays} days'),
                _buildPayslipLine(
                    'Approved Leaves', '${record.approvedLeaves} days'),
                _buildPayslipLine('Paid Leave Allowance',
                    '${record.paidLeaveDays} day (Zero deduction)'),
                _buildPayslipLine('Unpaid Leave (Loss of Pay)',
                    '${record.unpaidLeaveDays} days'),
                _buildPayslipLine('Total Payable Days',
                    '${record.payableDays} / ${record.standardWorkingDays}'),
                const Divider(height: 20),
                _buildPayslipLine('Base Monthly Salary',
                    '₹ ${record.grossSalary.toStringAsFixed(0)}'),
                _buildPayslipLine('Salary Deduction (LOP)',
                    '- ₹ ${record.deductions.toStringAsFixed(0)}',
                    isDeduction: true),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Net Payout',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '₹ ${record.netPay.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPayslipLine(String label, String value,
      {bool isDeduction = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: isDeduction
                  ? const Color(0xFFDC2626)
                  : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}
