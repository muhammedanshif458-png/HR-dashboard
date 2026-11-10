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

class _PayrollViewState extends State<PayrollView>
    with SingleTickerProviderStateMixin {
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
  late final TabController _tabController;

  // Conflict resolution dialog controllers
  final TextEditingController _conflictReasonController =
      TextEditingController();

  // Payment dialog controllers
  final TextEditingController _paymentMethodController =
      TextEditingController(text: 'Bank Transfer');
  final TextEditingController _paymentReferenceController =
      TextEditingController();
  final TextEditingController _paymentRemarksController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
    _tabController.dispose();
    _conflictReasonController.dispose();
    _paymentMethodController.dispose();
    _paymentReferenceController.dispose();
    _paymentRemarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hrProvider = context.watch<HRProvider>();
    final currentYear = hrProvider.payrollYear;
    final currentMonth = hrProvider.payrollMonth;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Row(
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
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Tab Bar ─────────────────────────────────────────────────
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF2563EB),
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: const Color(0xFF2563EB),
              indicatorWeight: 3,
              tabs: [
                const Tab(
                    icon: Icon(Icons.calculate_outlined),
                    text: 'Payroll Calc'),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 18),
                      const SizedBox(width: 6),
                      const Text('Conflicts'),
                      if (hrProvider.conflictsUnresolvedTotal > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${hrProvider.conflictsUnresolvedTotal}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Tab(
                    icon: Icon(Icons.layers_outlined), text: 'Batch'),
                const Tab(
                    icon: Icon(Icons.history_outlined), text: 'History'),
              ],
            ),
          ),

          // ── Tab Views ───────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPayrollCalcTab(hrProvider, currentYear, currentMonth),
                _buildConflictsTab(hrProvider),
                _buildBatchTab(hrProvider, currentYear, currentMonth),
                _buildHistoryTab(hrProvider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  // TAB 1 — PAYROLL CALC (existing functionality preserved)
  // ════════════════════════════════════════════════════════════════════
  Widget _buildPayrollCalcTab(
      HRProvider hrProvider, int currentYear, int currentMonth) {
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

          // Conflict Warning Banner
          if (summary.unresolvedConflictCount > 0) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFBBF24)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Color(0xFFD97706), size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${summary.unresolvedConflictCount} unresolved attendance/leave conflict(s) detected. Resolve them in the Conflicts tab before finalizing payroll.',
                      style: const TextStyle(
                        color: Color(0xFF92400E),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.warning_amber_rounded,
                        size: 16, color: Color(0xFFD97706)),
                    label: const Text('Go to Conflicts',
                        style: TextStyle(color: Color(0xFFD97706))),
                    onPressed: () => _tabController.animateTo(1),
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
                        initialValue: deptData.value,
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

                  // Create/Refresh Draft Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: hrProvider.isDraftBatchLoading
                        ? null
                        : () => hrProvider.createOrRefreshDraftBatch(),
                    icon: hrProvider.isDraftBatchLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.playlist_add_check, size: 18),
                    label: Text(hrProvider.activeDraftBatch != null
                        ? 'Refresh Draft'
                        : 'Create Draft'),
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
                                label: Text('Total Present',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Half Days',
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

                      // Pagination Footer
                      if (hrProvider.hasLoadedApiPayroll &&
                          hrProvider.payrollTotalPages > 1) ...[
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
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
    );
  }

  // ════════════════════════════════════════════════════════════════════
  // TAB 2 — CONFLICTS
  // ════════════════════════════════════════════════════════════════════
  Widget _buildConflictsTab(HRProvider hrProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Payroll Conflicts',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A)),
              ),
              const Spacer(),
              _buildConflictFilterChip(hrProvider, 'all', 'All'),
              const SizedBox(width: 8),
              _buildConflictFilterChip(
                  hrProvider, 'UNRESOLVED', 'Unresolved'),
              const SizedBox(width: 8),
              _buildConflictFilterChip(
                  hrProvider, 'RESOLVED', 'Resolved'),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: hrProvider.isConflictsLoading
                    ? null
                    : () => hrProvider.loadConflicts(page: 1),
                icon: hrProvider.isConflictsLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (hrProvider.conflictsUnresolvedTotal > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFBBF24)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Color(0xFFD97706), size: 20),
                  const SizedBox(width: 10),
                  Text(
                    '${hrProvider.conflictsUnresolvedTotal} unresolved conflict(s) must be resolved before payroll can be finalized.',
                    style: const TextStyle(
                        color: Color(0xFF92400E),
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

          if (hrProvider.conflictsError != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Text(
                'Error: ${hrProvider.conflictsError}',
                style: const TextStyle(color: Color(0xFF991B1B)),
              ),
            ),

          if (!hrProvider.hasLoadedConflicts && !hrProvider.isConflictsLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: ElevatedButton.icon(
                  onPressed: () => hrProvider.loadConflicts(page: 1),
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Load Conflicts'),
                ),
              ),
            )
          else if (hrProvider.isConflictsLoading &&
              hrProvider.payrollConflicts.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            )
          else if (hrProvider.payrollConflicts.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 56, color: Colors.green.shade400),
                    const SizedBox(height: 12),
                    const Text(
                      'No conflicts found.',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF334155)),
                    ),
                  ],
                ),
              ),
            )
          else
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  horizontalMargin: 20,
                  columnSpacing: 16,
                  columns: const [
                    DataColumn(
                        label: Text('Employee',
                            style:
                                TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('Date',
                            style:
                                TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('Type',
                            style:
                                TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('Status',
                            style:
                                TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('Resolution',
                            style:
                                TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('Actions',
                            style:
                                TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: hrProvider.payrollConflicts.map((conflict) {
                    final isUnresolved = conflict.status == 'UNRESOLVED';
                    return DataRow(
                      color: isUnresolved
                          ? WidgetStateProperty.all(
                              const Color(0xFFFFFBEB))
                          : null,
                      cells: [
                        DataCell(Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(conflict.employeeName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                            Text(conflict.employeeId,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600)),
                          ],
                        )),
                        DataCell(Text(
                          conflict.conflictDate.isNotEmpty
                              ? conflict.conflictDate
                              : conflict.dateKey,
                          style: const TextStyle(fontSize: 12),
                        )),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              conflict.conflictType.replaceAll('_', ' '),
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF92400E),
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isUnresolved
                                  ? const Color(0xFFFEE2E2)
                                  : const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              conflict.status,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: isUnresolved
                                      ? const Color(0xFFB91C1C)
                                      : const Color(0xFF15803D),
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        DataCell(Text(
                          conflict.resolutionDecision ?? '—',
                          style: const TextStyle(fontSize: 12),
                        )),
                        DataCell(
                          isUnresolved
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildResolveButton(
                                        context,
                                        hrProvider,
                                        conflict.id,
                                        'PRESENT',
                                        'Present',
                                        const Color(0xFF10B981)),
                                    const SizedBox(width: 4),
                                    _buildResolveButton(
                                        context,
                                        hrProvider,
                                        conflict.id,
                                        'PAID_LEAVE',
                                        'Paid Leave',
                                        const Color(0xFF2563EB)),
                                    const SizedBox(width: 4),
                                    _buildResolveButton(
                                        context,
                                        hrProvider,
                                        conflict.id,
                                        'UNPAID_LEAVE',
                                        'Unpaid Leave',
                                        const Color(0xFFEF4444)),
                                  ],
                                )
                              : Text(
                                  conflict.resolutionReason.isNotEmpty
                                      ? conflict.resolutionReason
                                      : (conflict.resolutionDecision ?? '—'),
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600),
                                ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConflictFilterChip(
      HRProvider hrProvider, String value, String label) {
    final isSelected = hrProvider.conflictsStatusFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (_) => hrProvider.setConflictsStatusFilter(value),
      selectedColor: const Color(0xFFEFF6FF),
      checkmarkColor: const Color(0xFF2563EB),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }

  Widget _buildResolveButton(
    BuildContext context,
    HRProvider hrProvider,
    String conflictId,
    String decision,
    String label,
    Color color,
  ) {
    return Tooltip(
      message: 'Mark as $label',
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.1),
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          elevation: 0,
        ),
        onPressed: () => _showResolveDialog(
            context, hrProvider, conflictId, decision, label),
        child: Text(label, style: const TextStyle(fontSize: 11)),
      ),
    );
  }

  void _showResolveDialog(
    BuildContext context,
    HRProvider hrProvider,
    String conflictId,
    String decision,
    String label,
  ) {
    _conflictReasonController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Resolve Conflict — $label'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mark this day as: $label',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _conflictReasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason (optional)',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final reason = _conflictReasonController.text.trim();
              final success = await hrProvider.resolveConflict(
                conflictId,
                decision,
                reason: reason,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(success
                      ? 'Conflict resolved as $label'
                      : 'Failed to resolve: ${hrProvider.conflictsError ?? "Unknown error"}'),
                  backgroundColor: success
                      ? const Color(0xFF10B981)
                      : const Color(0xFFDC2626),
                ));
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  // TAB 3 — BATCH MANAGEMENT
  // ════════════════════════════════════════════════════════════════════
  Widget _buildBatchTab(
      HRProvider hrProvider, int currentYear, int currentMonth) {
    final batch = hrProvider.activeDraftBatch;
    final hasConflicts = (batch?.unresolvedConflictCount ?? 0) > 0;
    final isFinalized = batch?.status == 'FINALIZED';
    final isDraft = batch?.status == 'DRAFT';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Payroll Batch Management',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A)),
              ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: hrProvider.isDraftBatchLoading
                    ? null
                    : () => hrProvider.createOrRefreshDraftBatch(),
                icon: hrProvider.isDraftBatchLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.playlist_add_check, size: 18),
                label: Text(batch != null
                    ? 'Refresh Draft'
                    : 'Create Draft Batch'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (hrProvider.draftBatchError != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: Color(0xFFDC2626), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      hrProvider.draftBatchError!,
                      style:
                          const TextStyle(color: Color(0xFF991B1B), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          if (batch == null)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.layers_outlined,
                        size: 56, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text(
                      'No draft batch created yet.',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Click "Create Draft Batch" to generate payroll for ${_months[currentMonth - 1]} $currentYear.',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Batch Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Batch Summary',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(width: 12),
                      _buildStatusBadge(batch.status),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 32,
                    runSpacing: 12,
                    children: [
                      _buildBatchInfoItem(
                          'Batch ID',
                          batch.id.length > 12
                              ? '...${batch.id.substring(batch.id.length - 12)}'
                              : batch.id),
                      _buildBatchInfoItem('Period',
                          '${_months[(batch.month) - 1]} ${batch.year}'),
                      _buildBatchInfoItem(
                          'Department',
                          batch.department.isEmpty
                              ? 'All'
                              : batch.department),
                      _buildBatchInfoItem(
                          'Employees', '${batch.employeeCount}'),
                      _buildBatchInfoItem('Gross Salary',
                          '₹ ${batch.grossSalary.toStringAsFixed(0)}'),
                      _buildBatchInfoItem('Total Deductions',
                          '₹ ${batch.totalDeductions.toStringAsFixed(0)}'),
                      _buildBatchInfoItem('Net Payout',
                          '₹ ${batch.totalNetPayout.toStringAsFixed(0)}'),
                      if (batch.unresolvedConflictCount > 0)
                        _buildBatchInfoItem(
                            'Unresolved Conflicts',
                            '${batch.unresolvedConflictCount}',
                            valueColor: const Color(0xFFDC2626)),
                      if (batch.finalizedAt != null)
                        _buildBatchInfoItem(
                            'Finalized At', batch.finalizedAt!.split('T').first),
                      if (batch.paidAt != null)
                        _buildBatchInfoItem(
                            'Paid At', batch.paidAt!.split('T').first),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Conflict warning
            if (hasConflicts)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFBBF24)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFD97706), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${batch.unresolvedConflictCount} unresolved conflict(s) must be resolved before finalizing.',
                        style: const TextStyle(
                            color: Color(0xFF92400E),
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _tabController.animateTo(1),
                      child: const Text('Go to Conflicts',
                          style: TextStyle(color: Color(0xFFD97706))),
                    ),
                  ],
                ),
              ),

            // Action Buttons
            Row(
              children: [
                // Finalize Button
                if (isDraft)
                  Tooltip(
                    message: hasConflicts
                        ? 'Resolve ${batch.unresolvedConflictCount} conflict(s) before finalizing'
                        : 'Finalize payroll batch',
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasConflicts
                            ? Colors.grey.shade400
                            : const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: hasConflicts ||
                              hrProvider.isDraftBatchLoading
                          ? null
                          : () => _showFinalizeConfirmDialog(
                              context, hrProvider, batch.id),
                      icon: const Icon(Icons.check_circle_outline, size: 20),
                      label: const Text('Finalize Batch',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),

                // Mark as Paid Button
                if (isFinalized) ...[
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: hrProvider.isDraftBatchLoading
                        ? null
                        : () => _showMarkPaidDialog(
                            context, hrProvider, batch.id),
                    icon: const Icon(Icons.payments_outlined, size: 20),
                    label: const Text('Mark as Paid',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg, fg;
    switch (status) {
      case 'FINALIZED':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF15803D);
        break;
      case 'PAID':
        bg = const Color(0xFFEDE9FE);
        fg = const Color(0xFF6D28D9);
        break;
      default: // DRAFT
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(status,
          style: TextStyle(
              color: fg, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildBatchInfoItem(String label, String value,
      {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: valueColor ?? const Color(0xFF0F172A))),
      ],
    );
  }

  void _showFinalizeConfirmDialog(
      BuildContext context, HRProvider hrProvider, String batchId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Finalization'),
        content: const Text(
          'Are you sure you want to finalize this payroll batch? '
          'Once finalized, payroll records will be locked and you will need to mark it as Paid separately.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await hrProvider.finalizeBatch(batchId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(success
                      ? 'Batch finalized successfully'
                      : 'Finalization failed: ${hrProvider.draftBatchError ?? "Unknown error"}'),
                  backgroundColor: success
                      ? const Color(0xFF10B981)
                      : const Color(0xFFDC2626),
                ));
              }
            },
            child: const Text('Finalize'),
          ),
        ],
      ),
    );
  }

  void _showMarkPaidDialog(
      BuildContext context, HRProvider hrProvider, String batchId) {
    _paymentMethodController.text = 'Bank Transfer';
    _paymentReferenceController.clear();
    _paymentRemarksController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Mark Batch as Paid'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _paymentMethodController,
                decoration: const InputDecoration(
                  labelText: 'Payment Method',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _paymentReferenceController,
                decoration: const InputDecoration(
                  labelText: 'Reference / Transaction ID',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _paymentRemarksController,
                decoration: const InputDecoration(
                  labelText: 'Remarks (optional)',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await hrProvider.markBatchPaid(
                batchId,
                paymentMethod: _paymentMethodController.text.trim(),
                reference: _paymentReferenceController.text.trim(),
                remarks: _paymentRemarksController.text.trim(),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(success
                      ? 'Batch marked as PAID'
                      : 'Failed: ${hrProvider.draftBatchError ?? "Unknown error"}'),
                  backgroundColor: success
                      ? const Color(0xFF10B981)
                      : const Color(0xFFDC2626),
                ));
              }
            },
            child: const Text('Confirm Payment'),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  // TAB 4 — HISTORY
  // ════════════════════════════════════════════════════════════════════
  Widget _buildHistoryTab(HRProvider hrProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Payroll Batch History',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A)),
              ),
              const Spacer(),
              _buildHistoryFilterChip(hrProvider, 'all', 'All'),
              const SizedBox(width: 8),
              _buildHistoryFilterChip(hrProvider, 'DRAFT', 'Draft'),
              const SizedBox(width: 8),
              _buildHistoryFilterChip(
                  hrProvider, 'FINALIZED', 'Finalized'),
              const SizedBox(width: 8),
              _buildHistoryFilterChip(hrProvider, 'PAID', 'Paid'),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: hrProvider.isBatchHistoryLoading
                    ? null
                    : () => hrProvider.loadBatchHistory(page: 1),
                icon: hrProvider.isBatchHistoryLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (hrProvider.batchHistoryError != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Text(
                'Error: ${hrProvider.batchHistoryError}',
                style: const TextStyle(color: Color(0xFF991B1B)),
              ),
            ),

          if (!hrProvider.hasLoadedBatchHistory &&
              !hrProvider.isBatchHistoryLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: ElevatedButton.icon(
                  onPressed: () => hrProvider.loadBatchHistory(page: 1),
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Load History'),
                ),
              ),
            )
          else if (hrProvider.isBatchHistoryLoading &&
              hrProvider.payrollBatches.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            )
          else if (hrProvider.payrollBatches.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.history_outlined,
                        size: 56, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text(
                      'No payroll batches found.',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF334155)),
                    ),
                  ],
                ),
              ),
            )
          else
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  horizontalMargin: 20,
                  columnSpacing: 16,
                  columns: const [
                    DataColumn(
                        label: Text('Period',
                            style:
                                TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('Department',
                            style:
                                TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('Status',
                            style:
                                TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('Employees',
                            style:
                                TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('Net Payout',
                            style:
                                TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('Actions',
                            style:
                                TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: hrProvider.payrollBatches.map((batch) {
                    return DataRow(cells: [
                      DataCell(Text(
                        '${_months[batch.month - 1]} ${batch.year}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      )),
                      DataCell(Text(
                        batch.department.isEmpty ? 'All' : batch.department,
                        style: const TextStyle(fontSize: 12),
                      )),
                      DataCell(_buildStatusBadge(batch.status)),
                      DataCell(Text('${batch.employeeCount}',
                          style: const TextStyle(fontSize: 12))),
                      DataCell(Text(
                        '₹ ${batch.totalNetPayout.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      )),
                      DataCell(
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEFF6FF),
                            foregroundColor: const Color(0xFF2563EB),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6)),
                          ),
                          onPressed: () => _showBatchDetailDialog(
                              context, hrProvider, batch.id),
                          icon: const Icon(Icons.visibility_outlined,
                              size: 16),
                          label: const Text('View',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ]);
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryFilterChip(
      HRProvider hrProvider, String value, String label) {
    final isSelected = hrProvider.batchHistoryStatusFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (_) => hrProvider.setBatchHistoryStatusFilter(value),
      selectedColor: const Color(0xFFEFF6FF),
      checkmarkColor: const Color(0xFF2563EB),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }

  void _showBatchDetailDialog(
      BuildContext context, HRProvider hrProvider, String batchId) async {
    await hrProvider.loadBatchDetail(batchId);
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final detail = hrProvider.selectedBatchDetail;
            if (detail == null || hrProvider.isBatchDetailLoading) {
              return const AlertDialog(
                content: Center(
                    child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                )),
              );
            }
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.layers_outlined,
                      color: Color(0xFF2563EB), size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Batch Detail — ${_months[detail.batch.month - 1]} ${detail.batch.year}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  _buildStatusBadge(detail.batch.status),
                ],
              ),
              content: SizedBox(
                width: 820,
                height: 480,
                child: Column(
                  children: [
                    Wrap(
                      spacing: 24,
                      runSpacing: 8,
                      children: [
                        _buildBatchInfoItem('Employees',
                            '${detail.batch.employeeCount}'),
                        _buildBatchInfoItem('Gross Salary',
                            '₹ ${detail.batch.grossSalary.toStringAsFixed(0)}'),
                        _buildBatchInfoItem('Deductions',
                            '₹ ${detail.batch.totalDeductions.toStringAsFixed(0)}'),
                        _buildBatchInfoItem('Net Payout',
                            '₹ ${detail.batch.totalNetPayout.toStringAsFixed(0)}'),
                      ],
                    ),
                    const Divider(height: 24),
                    Expanded(
                      child: detail.records.isEmpty
                          ? const Center(
                              child: Text('No employee records found.'))
                          : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SingleChildScrollView(
                                child: DataTable(
                                  horizontalMargin: 12,
                                  columnSpacing: 12,
                                  columns: const [
                                    DataColumn(
                                        label: Text('Employee',
                                            style: TextStyle(
                                                fontWeight:
                                                    FontWeight.bold))),
                                    DataColumn(
                                        label: Text('Dept',
                                            style: TextStyle(
                                                fontWeight:
                                                    FontWeight.bold))),
                                    DataColumn(
                                        label: Text('Base Salary',
                                            style: TextStyle(
                                                fontWeight:
                                                    FontWeight.bold))),
                                    DataColumn(
                                        label: Text('Payable Days',
                                            style: TextStyle(
                                                fontWeight:
                                                    FontWeight.bold))),
                                    DataColumn(
                                        label: Text('Net Pay',
                                            style: TextStyle(
                                                fontWeight:
                                                    FontWeight.bold))),
                                    DataColumn(
                                        label: Text('Payslip',
                                            style: TextStyle(
                                                fontWeight:
                                                    FontWeight.bold))),
                                  ],
                                  rows: detail.records.map((rec) {
                                    return DataRow(cells: [
                                      DataCell(Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(rec.name,
                                              style: const TextStyle(
                                                  fontWeight:
                                                      FontWeight.w600,
                                                  fontSize: 12)),
                                          Text(rec.designation,
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey
                                                      .shade600)),
                                        ],
                                      )),
                                      DataCell(Text(rec.department,
                                          style: const TextStyle(
                                              fontSize: 12))),
                                      DataCell(Text(
                                          '₹ ${rec.grossSalary.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                              fontSize: 12))),
                                      DataCell(Text(
                                          '${rec.payableDays.toInt()}',
                                          style: const TextStyle(
                                              fontSize: 12))),
                                      DataCell(Text(
                                          '₹ ${rec.netPay.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12))),
                                      DataCell(IconButton(
                                        icon: const Icon(
                                            Icons.receipt_long_outlined,
                                            size: 18,
                                            color: Color(0xFF2563EB)),
                                        tooltip: 'View Payslip',
                                        onPressed: () async {
                                          Navigator.pop(ctx);
                                          await hrProvider.loadPayslip(
                                              batchId, rec.id);
                                          if (context.mounted &&
                                              hrProvider.selectedPayslip !=
                                                  null) {
                                            _showBatchPayslipDialog(
                                                context, hrProvider);
                                          }
                                        },
                                      )),
                                    ]);
                                  }).toList(),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close')),
              ],
            );
          },
        );
      },
    );
  }

  void _showBatchPayslipDialog(BuildContext context, HRProvider hrProvider) {
    final payslip = hrProvider.selectedPayslip;
    if (payslip == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.receipt, color: Color(0xFF2563EB), size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Payslip: ${payslip.employeeName} — ${_months[payslip.month - 1]} ${payslip.year}',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _buildStatusBadge(payslip.batchStatus),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPayslipLine('Department', payslip.department),
                _buildPayslipLine('Designation', payslip.designation),
                const Divider(height: 20),
                const Text('Attendance Calendar',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                _buildPayslipLine('Scheduled Working Days',
                    '${payslip.calendar.scheduledWorkingDays}'),
                _buildPayslipLine(
                    'Weekly Offs', '${payslip.calendar.weeklyOffs}'),
                _buildPayslipLine(
                    'Holidays', '${payslip.calendar.holidays}'),
                _buildPayslipLine(
                    'Total Present Days',
                    '${(payslip.calendar.presentDays + payslip.calendar.wfhDays) % 1 == 0 ? (payslip.calendar.presentDays + payslip.calendar.wfhDays).toInt() : (payslip.calendar.presentDays + payslip.calendar.wfhDays)}'),
                _buildPayslipLine(
                    'Half Days', '${payslip.calendar.halfDays}'),
                _buildPayslipLine(
                    'Paid Leave', '${payslip.calendar.paidLeaveDays}'),
                _buildPayslipLine(
                    'Unpaid Leave', '${payslip.calendar.unpaidLeaveDays}'),
                _buildPayslipLine(
                    'LOP Days', '${payslip.calendar.lopDays}'),
                _buildPayslipLine(
                    'Payable Days', '${payslip.calendar.payableDays}'),
                const Divider(height: 20),
                if (payslip.earnings.isNotEmpty) ...[
                  const Text('Earnings',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  ...payslip.earnings.map((e) => _buildPayslipLine(
                      e.title, '₹ ${e.amount.toStringAsFixed(0)}')),
                  const Divider(height: 20),
                ],
                if (payslip.deductions.isNotEmpty) ...[
                  const Text('Deductions',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  ...payslip.deductions.map((d) => _buildPayslipLine(
                      d.title,
                      '- ₹ ${d.amount.toStringAsFixed(0)}',
                      valueColor: const Color(0xFFDC2626))),
                  const Divider(height: 20),
                ],
                _buildPayslipLine('Daily Salary',
                    '₹ ${payslip.dailySalary.toStringAsFixed(2)}'),
                _buildPayslipLine('Gross Pay',
                    '₹ ${payslip.grossPay.toStringAsFixed(0)}'),
                _buildPayslipLine(
                    'Total Deductions',
                    '- ₹ ${payslip.totalDeductions.toStringAsFixed(0)}',
                    valueColor: const Color(0xFFDC2626)),
                _buildPayslipLine(
                    'Net Pay',
                    '₹ ${payslip.netPay.toStringAsFixed(0)}',
                    isBold: true,
                    valueColor: const Color(0xFF10B981)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'PDF Export: Not supported (feature pending)',
                    style: TextStyle(
                        fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close')),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  // SHARED WIDGETS (Payroll Calc Tab)
  // ════════════════════════════════════════════════════════════════════

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
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
              ),
              Text(
                record.designation.isNotEmpty
                    ? record.designation
                    : record.employeeId,
                style:
                    TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),

        // Department
        DataCell(
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isTech
                  ? const Color(0xFFEFF6FF)
                  : const Color(0xFFFDF2F8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              record.department,
              style: TextStyle(
                color: isTech
                    ? const Color(0xFF2563EB)
                    : const Color(0xFFDB2777),
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

        // Total Present (combined: presentDays + wfhDays)
        DataCell(
          Builder(builder: (_) {
            final totalPresent = record.presentDays + record.wfhDays;
            final isInt = totalPresent % 1 == 0;
            final displayValue = isInt ? totalPresent.toInt() : totalPresent;
            return Text(
              '$displayValue ${totalPresent == 1 ? 'day' : 'days'}',
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w500),
            );
          }),
        ),

        // Half Days
        DataCell(
          Text(
              '${record.halfDays % 1 == 0 ? record.halfDays.toInt() : record.halfDays} ${record.halfDays == 1 ? 'day' : 'days'}',
              style: TextStyle(
                fontSize: 12,
                color: record.halfDays > 0
                    ? const Color(0xFFD97706)
                    : const Color(0xFF64748B),
                fontWeight: record.halfDays > 0
                    ? FontWeight.w600
                    : FontWeight.normal,
              )),
        ),

        // Approved Leaves
        DataCell(
          Text(
              '${record.approvedLeaves} ${record.approvedLeaves == 1 ? 'day' : 'days'}',
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${record.paidLeaveDays.toInt()} Paid',
                  style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF15803D),
                      fontWeight: FontWeight.bold),
                ),
              ),
              if (record.unpaidLeaveDays > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${record.unpaidLeaveDays.toInt()} LOP',
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
          Text(
              '${record.payableDays.toInt()} / ${record.standardWorkingDays}',
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold)),
        ),

        // Base Salary
        DataCell(
          Text('₹ ${record.grossSalary.toStringAsFixed(0)}',
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600)),
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
                  final staffSource =
                      hrProvider.employeeDirectory.isNotEmpty
                          ? hrProvider.employeeDirectory
                          : hrProvider.staffList;
                  final staff = staffSource.firstWhere(
                    (s) =>
                        s.id == record.id ||
                        (record.employeeId.isNotEmpty &&
                            s.id == record.employeeId),
                    orElse: () => Staff(
                      id: record.id.isNotEmpty
                          ? record.id
                          : record.employeeId,
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
                onPressed: () => _showEmployeePayslipModal(context, record),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showEmployeePayslipModal(
      BuildContext context, EmployeePayrollRecord record) {
    showDialog(
      context: context,
      builder: (ctx) {
        final isTech = record.department.toLowerCase() == 'tech';
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.receipt,
                  color: Color(0xFF2563EB), size: 22),
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
                _buildPayslipLine('Total Present Days',
                    '${(record.presentDays + record.wfhDays) % 1 == 0 ? (record.presentDays + record.wfhDays).toInt() : (record.presentDays + record.wfhDays)} ${(record.presentDays + record.wfhDays) == 1 ? 'day' : 'days'}'),
                _buildPayslipLine('Half Days',
                    '${record.halfDays % 1 == 0 ? record.halfDays.toInt() : record.halfDays} ${record.halfDays == 1 ? 'day' : 'days'}'),
                _buildPayslipLine('Approved Leaves',
                    '${record.approvedLeaves} ${record.approvedLeaves == 1 ? 'day' : 'days'}'),
                _buildPayslipLine('Paid Leave Days',
                    '${record.paidLeaveDays % 1 == 0 ? record.paidLeaveDays.toInt() : record.paidLeaveDays} ${record.paidLeaveDays == 1 ? 'day' : 'days'}'),
                _buildPayslipLine('Unpaid Leave / LOP',
                    '${record.unpaidLeaveDays % 1 == 0 ? record.unpaidLeaveDays.toInt() : record.unpaidLeaveDays} ${record.unpaidLeaveDays == 1 ? 'day' : 'days'}'),
                _buildPayslipLine('Total Payable Days',
                    '${record.payableDays % 1 == 0 ? record.payableDays.toInt() : record.payableDays} / ${record.standardWorkingDays}'),
                const Divider(height: 20),
                _buildPayslipLine('Base Monthly Salary',
                    '₹ ${record.grossSalary.toStringAsFixed(0)}'),
                _buildPayslipLine(
                    'Daily Rate', '₹ ${record.dailyRate.toStringAsFixed(2)}'),
                _buildPayslipLine('LOP Deduction',
                    '- ₹ ${record.deductions.toStringAsFixed(0)}',
                    valueColor: record.deductions > 0
                        ? const Color(0xFFDC2626)
                        : null),
                _buildPayslipLine('Net Pay',
                    '₹ ${record.netPay.toStringAsFixed(0)}',
                    isBold: true,
                    valueColor: const Color(0xFF10B981)),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close')),
          ],
        );
      },
    );
  }

  Widget _buildPayslipLine(String label, String value,
      {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              )),
          Text(value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: valueColor ?? const Color(0xFF0F172A),
              )),
        ],
      ),
    );
  }
}
