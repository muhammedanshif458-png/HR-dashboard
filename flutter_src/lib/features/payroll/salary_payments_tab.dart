import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/hr_models.dart';
import '../../providers/hr_provider.dart';

class SalaryPaymentsTab extends StatefulWidget {
  const SalaryPaymentsTab({super.key});

  @override
  State<SalaryPaymentsTab> createState() => _SalaryPaymentsTabState();
}

class _SalaryPaymentsTabState extends State<SalaryPaymentsTab> {
  static const _months = [
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
    'December',
  ];

  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
        text: context.read<HRProvider>().salaryPaymentSearchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HRProvider>();
    final summary = provider.salaryPaymentSummary;
    final year = provider.salaryPaymentYear;
    final departments = <String>{
      'all',
      'Tech',
      'Telecalling',
      ...provider.departments.map((item) => item.title.trim()),
      ...provider.salaryPayments.map((item) => item.department.trim()),
    }.where((item) => item.isNotEmpty).toList();
    if (!departments.contains(provider.salaryPaymentDepartment)) {
      departments.add(provider.salaryPaymentDepartment);
    }

    return LayoutBuilder(builder: (context, constraints) {
      final contentWidth = constraints.maxWidth - 48;
      final columns = contentWidth < 560
          ? 1
          : contentWidth < 900
              ? 2
              : contentWidth < 1250
                  ? 3
                  : 6;
      final cardWidth = (contentWidth - (columns - 1) * 12) / columns;
      final years = <int>{
        for (var item = DateTime.now().year - 5;
            item <= DateTime.now().year + 1;
            item++)
          item,
        year,
      }.toList()
        ..sort();

      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.payments_outlined,
                      color: Color(0xFF2563EB), size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Salary Payments',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A))),
                      SizedBox(height: 3),
                      Text(
                        'Manage employee monthly salary payments and track payment status.',
                        style:
                            TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const ValueKey('salary_payment_refresh'),
                  tooltip: 'Refresh Salary Payments',
                  onPressed: provider.isSalaryPaymentsLoading ||
                          provider.isSalaryPaymentSummaryLoading
                      ? null
                      : () => _refresh(provider),
                  icon: provider.isSalaryPaymentsLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh, color: Color(0xFF2563EB)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 150,
                  child: DropdownButtonFormField<int>(
                    isExpanded: true,
                    key: ValueKey(
                        'salary_payment_month_${provider.salaryPaymentMonth}'),
                    initialValue: provider.salaryPaymentMonth,
                    decoration: const InputDecoration(
                      labelText: 'Month',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: List.generate(12, (i) => i + 1)
                        .map((month) => DropdownMenuItem(
                              value: month,
                              child: Text(_months[month - 1]),
                            ))
                        .toList(),
                    onChanged: (month) {
                      if (month != null) {
                        provider.setSalaryPaymentMonth(month, year,
                            paymentsOnly: true);
                      }
                    },
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: DropdownButtonFormField<int>(
                    isExpanded: true,
                    key: ValueKey('salary_payment_year_$year'),
                    initialValue: year,
                    decoration: const InputDecoration(
                      labelText: 'Year',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: years
                        .map((item) => DropdownMenuItem(
                              value: item,
                              child: Text('$item'),
                            ))
                        .toList(),
                    onChanged: (selectedYear) {
                      if (selectedYear != null) {
                        provider.setSalaryPaymentMonth(
                            provider.salaryPaymentMonth, selectedYear,
                            paymentsOnly: true);
                      }
                    },
                  ),
                ),
                SizedBox(
                  width: 210,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    key: ValueKey(
                        'salary_payment_department_${provider.salaryPaymentDepartment}'),
                    initialValue: provider.salaryPaymentDepartment,
                    decoration: const InputDecoration(
                      labelText: 'Department',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: departments
                        .map((item) => DropdownMenuItem(
                              value: item,
                              child: Text(
                                  item == 'all' ? 'All Departments' : item),
                            ))
                        .toList(),
                    onChanged: (department) {
                      if (department != null) {
                        provider.setSalaryPaymentDepartment(department,
                            paymentsOnly: true);
                      }
                    },
                  ),
                ),
                SizedBox(
                  width: 165,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    key: ValueKey(
                        'salary_payment_status_${provider.salaryPaymentStatusFilter}'),
                    initialValue: provider.salaryPaymentStatusFilter,
                    decoration: const InputDecoration(
                      labelText: 'Payment Status',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'all', child: Text('All Statuses')),
                      DropdownMenuItem(
                          value: 'PENDING', child: Text('Pending')),
                      DropdownMenuItem(value: 'PAID', child: Text('Paid')),
                    ],
                    onChanged: (status) {
                      if (status != null) {
                        provider.setSalaryPaymentStatus(status,
                            paymentsOnly: true);
                      }
                    },
                  ),
                ),
                SizedBox(
                  width: 255,
                  child: TextField(
                    key: const ValueKey('salary_payment_search'),
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Employee search',
                      hintText: 'Name or employee ID',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear employee search',
                              onPressed: () {
                                _searchController.clear();
                                provider.setSalaryPaymentSearch('',
                                    paymentsOnly: true);
                              },
                              icon: const Icon(Icons.close, size: 18),
                            ),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    onChanged: (search) => provider
                        .setSalaryPaymentSearch(search, paymentsOnly: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _summaryCard(
                    'Total Employees',
                    summary?.totalEmployees.toString() ?? '—',
                    Icons.groups_outlined,
                    const Color(0xFF2563EB),
                    cardWidth),
                _summaryCard(
                    'Total Net Salary',
                    summary == null
                        ? '—'
                        : '₹ ${summary.totalSalary.toStringAsFixed(2)}',
                    Icons.account_balance_wallet_outlined,
                    const Color(0xFF7C3AED),
                    cardWidth),
                _summaryCard(
                    'Paid Employees',
                    summary?.paidEmployees.toString() ?? '—',
                    Icons.check_circle_outline,
                    const Color(0xFF059669),
                    cardWidth),
                _summaryCard(
                    'Pending Employees',
                    summary?.pendingEmployees.toString() ?? '—',
                    Icons.pending_outlined,
                    const Color(0xFFD97706),
                    cardWidth),
                _summaryCard(
                    'Total Paid Amount',
                    summary == null
                        ? '—'
                        : '₹ ${summary.paidAmount.toStringAsFixed(2)}',
                    Icons.payments_outlined,
                    const Color(0xFF059669),
                    cardWidth),
                _summaryCard(
                    'Total Pending Amount',
                    summary == null
                        ? '—'
                        : '₹ ${summary.pendingAmount.toStringAsFixed(2)}',
                    Icons.schedule_outlined,
                    const Color(0xFFD97706),
                    cardWidth),
              ],
            ),
            const SizedBox(height: 20),
            if (provider.salaryPaymentsError != null)
              _errorBanner(
                  provider.salaryPaymentsError!, () => _refresh(provider)),
            if (provider.salaryPaymentSummaryError != null && summary == null)
              _errorBanner(provider.salaryPaymentSummaryError!,
                  provider.loadSalaryPaymentSummary),
            if (provider.isSalaryPaymentsLoading &&
                provider.salaryPayments.isNotEmpty)
              const LinearProgressIndicator(minHeight: 2),
            if (provider.isSalaryPaymentsLoading &&
                provider.salaryPayments.isEmpty)
              const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (!provider.hasLoadedSalaryPayments &&
                provider.salaryPaymentsError == null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: ElevatedButton.icon(
                    onPressed: () => _refresh(provider),
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Load Salary Payments'),
                  ),
                ),
              )
            else if (provider.salaryPayments.isEmpty &&
                provider.salaryPaymentsError == null)
              _emptyState(provider.salaryPaymentSearchQuery.trim().isNotEmpty)
            else if (provider.salaryPayments.isNotEmpty)
              _paymentTable(provider),
          ],
        ),
      );
    });
  }

  Widget _summaryCard(
      String title, String value, IconData icon, Color color, double width) {
    return Container(
      key: ValueKey(
          'salary_payment_summary_${title.toLowerCase().replaceAll(' ', '_')}'),
      width: width,
      height: 112,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Color(0x080F172A), blurRadius: 5, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 21),
          Text(value,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text(title,
              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _errorBanner(String message, VoidCallback retry) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFDC2626)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  key: const ValueKey('salary_payment_error'),
                  style: const TextStyle(color: Color(0xFF991B1B))),
            ),
            TextButton.icon(
              onPressed: retry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      );

  Widget _emptyState(bool isSearch) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Icon(Icons.payments_outlined,
                size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              isSearch
                  ? 'No employees match your search.'
                  : 'No salary payments found for this period.',
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155)),
            ),
          ],
        ),
      );

  Widget _paymentTable(HRProvider provider) => Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            horizontalMargin: 18,
            columnSpacing: 18,
            columns: const [
              DataColumn(label: Text('Employee ID')),
              DataColumn(label: Text('Employee Name')),
              DataColumn(label: Text('Department')),
              DataColumn(label: Text('Monthly Base Salary')),
              DataColumn(label: Text('Total Present')),
              DataColumn(label: Text('Paid Leave Days')),
              DataColumn(label: Text('LOP Days')),
              DataColumn(label: Text('Payable Days')),
              DataColumn(label: Text('Net Salary')),
              DataColumn(label: Text('Payment Status')),
              DataColumn(label: Text('Action')),
            ],
            rows: provider.salaryPayments.map((payment) {
              final paid = payment.status == 'PAID';
              return DataRow(cells: [
                DataCell(Text(payment.employeeId)),
                DataCell(Text(payment.employeeName,
                    style: const TextStyle(fontWeight: FontWeight.w600))),
                DataCell(Text(payment.department)),
                DataCell(Text(_money(payment.monthlyBaseSalary))),
                // Backend totalPresentDays combines office and WFH days.
                DataCell(Text(payment.totalPresentDays.toStringAsFixed(1))),
                DataCell(Text(payment.paidLeaveDays.toStringAsFixed(1))),
                DataCell(Text(payment.lopDays.toStringAsFixed(1))),
                DataCell(Text(payment.payableDays.toStringAsFixed(1))),
                DataCell(Text(_money(payment.netSalary),
                    style: const TextStyle(fontWeight: FontWeight.w600))),
                DataCell(_statusBadge(payment.status)),
                DataCell(paid
                    ? OutlinedButton.icon(
                        key: ValueKey('view_salary_payment_${payment.id}'),
                        onPressed: provider.isSalaryPaymentDetailLoading
                            ? null
                            : () => _showDetails(context, provider, payment),
                        icon: const Icon(Icons.visibility_outlined, size: 16),
                        label: const Text('View Payment Details'),
                      )
                    : ElevatedButton.icon(
                        key: ValueKey('mark_salary_payment_${payment.id}'),
                        onPressed: provider.isMarkSalaryPaymentLoading
                            ? null
                            : () => showDialog<void>(
                                  context: context,
                                  builder: (_) => _MarkSalaryPaymentDialog(
                                      payment: payment),
                                ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                        ),
                        icon: provider.isMarkSalaryPaymentLoading
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.payments_outlined, size: 16),
                        label: const Text('Mark as Paid'),
                      )),
              ]);
            }).toList(),
          ),
        ),
      );

  Widget _statusBadge(String status) {
    final paid = status == 'PAID';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: paid ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status,
          style: TextStyle(
              color: paid ? const Color(0xFF15803D) : const Color(0xFFB45309),
              fontSize: 11,
              fontWeight: FontWeight.bold)),
    );
  }

  Future<void> _refresh(HRProvider provider) async {
    await provider.loadSalaryPayments(page: 1);
  }

  void _showDetails(
      BuildContext context, HRProvider provider, SalaryPayment payment) {
    provider.loadSalaryPaymentDetails(payment.id);
    showDialog<void>(
      context: context,
      builder: (_) => _SalaryPaymentDetailsDialog(paymentId: payment.id),
    );
  }

  String _money(double value) => '₹ ${value.toStringAsFixed(2)}';
}

class _MarkSalaryPaymentDialog extends StatefulWidget {
  final SalaryPayment payment;
  const _MarkSalaryPaymentDialog({required this.payment});

  @override
  State<_MarkSalaryPaymentDialog> createState() =>
      _MarkSalaryPaymentDialogState();
}

class _MarkSalaryPaymentDialogState extends State<_MarkSalaryPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _referenceController = TextEditingController();
  final _remarksController = TextEditingController();
  String? _method;

  @override
  void dispose() {
    _dateController.dispose();
    _referenceController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  DateTime? _parseDate(String input) {
    final value = input.trim();
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return null;
    final parts = value.split('-').map(int.tryParse).toList();
    if (parts.any((part) => part == null)) return null;
    final date = DateTime(parts[0]!, parts[1]!, parts[2]!);
    if (date.year != parts[0] ||
        date.month != parts[1] ||
        date.day != parts[2]) {
      return null;
    }
    return date;
  }

  @override
  Widget build(BuildContext context) => Consumer<HRProvider>(
        builder: (context, provider, _) => AlertDialog(
          key: const ValueKey('salary_payment_form_dialog'),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Mark as Paid'),
          content: SizedBox(
            width: 440,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.payment.employeeName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          Text(widget.payment.employeeId,
                              style: const TextStyle(color: Color(0xFF64748B))),
                          const SizedBox(height: 6),
                          Text(
                              '${_months[widget.payment.payrollMonth - 1]} ${widget.payment.payrollYear} · ${_money(widget.payment.netSalary)}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const ValueKey('salary_payment_date'),
                      controller: _dateController,
                      decoration: InputDecoration(
                        labelText: 'Payment date',
                        hintText: 'YYYY-MM-DD',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: 'Choose payment date',
                          icon: const Icon(Icons.calendar_today_outlined),
                          onPressed: () async {
                            final today = DateTime.now();
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: today,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() {
                                _dateController.text =
                                    '${picked.year.toString().padLeft(4, '0')}-'
                                    '${picked.month.toString().padLeft(2, '0')}-'
                                    '${picked.day.toString().padLeft(2, '0')}';
                              });
                            }
                          },
                        ),
                      ),
                      validator: (value) => _parseDate(value ?? '') == null
                          ? 'Enter a valid payment date (YYYY-MM-DD)'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      key: const ValueKey('salary_payment_method'),
                      initialValue: _method,
                      decoration: const InputDecoration(
                        labelText: 'Payment method',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Select payment method'),
                      items: const [
                        DropdownMenuItem(value: 'CASH', child: Text('Cash')),
                        DropdownMenuItem(
                            value: 'BANK_TRANSFER',
                            child: Text('Bank Transfer')),
                        DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                      ],
                      onChanged: provider.isMarkSalaryPaymentLoading
                          ? null
                          : (value) => setState(() => _method = value),
                      validator: (value) =>
                          value == null ? 'Select a payment method' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const ValueKey('salary_payment_reference'),
                      controller: _referenceController,
                      decoration: const InputDecoration(
                        labelText: 'Transaction reference',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          (_method == 'BANK_TRANSFER' || _method == 'UPI') &&
                                  (value == null || value.trim().isEmpty)
                              ? 'Transaction reference is required'
                              : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const ValueKey('salary_payment_remarks'),
                      controller: _remarksController,
                      decoration: const InputDecoration(
                        labelText: 'Remarks (optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    if (provider.markSalaryPaymentError != null) ...[
                      const SizedBox(height: 12),
                      Text(provider.markSalaryPaymentError!,
                          key: const ValueKey('salary_payment_submit_error'),
                          style: const TextStyle(
                              color: Color(0xFFB91C1C), fontSize: 13)),
                    ],
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: provider.isMarkSalaryPaymentLoading
                  ? null
                  : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              key: const ValueKey('salary_payment_review'),
              onPressed: provider.isMarkSalaryPaymentLoading ? null : _review,
              child: provider.isMarkSalaryPaymentLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Review Payment'),
            ),
          ],
        ),
      );

  Future<void> _review() async {
    if (!_formKey.currentState!.validate()) return;
    final paymentDate = _parseDate(_dateController.text)!;
    final method = _method!;
    final payment = widget.payment;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (confirmContext) => AlertDialog(
        title: const Text('Confirm Salary Payment'),
        content: Text(
          'Confirm ${payment.employeeName} (${payment.employeeId}) was paid '
          '${_money(payment.netSalary)} for '
          '${_months[payment.payrollMonth - 1]} ${payment.payrollYear}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(confirmContext, false),
            child: const Text('Back'),
          ),
          ElevatedButton(
            key: const ValueKey('salary_payment_confirm'),
            onPressed: () => Navigator.pop(confirmContext, true),
            child: const Text('Confirm Payment'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final provider = context.read<HRProvider>();
    final success = await provider.markSalaryPaymentPaid(
      payment.id,
      ConfirmSalaryPaymentRequest(
        paymentDate: paymentDate,
        paymentMethod: method,
        transactionReference: _referenceController.text.trim(),
        remarks: _remarksController.text.trim(),
      ),
    );
    if (!mounted) return;
    if (success) Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success
          ? 'Salary payment marked as paid.'
          : provider.markSalaryPaymentError ??
              'Unable to confirm salary payment.'),
      backgroundColor:
          success ? const Color(0xFF059669) : const Color(0xFFDC2626),
    ));
  }

  static const _months = [
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
    'December',
  ];

  String _money(double value) => '₹ ${value.toStringAsFixed(2)}';
}

class _SalaryPaymentDetailsDialog extends StatelessWidget {
  final String paymentId;
  const _SalaryPaymentDetailsDialog({required this.paymentId});

  @override
  Widget build(BuildContext context) => Consumer<HRProvider>(
        builder: (context, provider, _) {
          final payment = provider.selectedSalaryPayment;
          final isSelectedPayment = payment?.id == paymentId;
          return AlertDialog(
            key: const ValueKey('salary_payment_details_dialog'),
            title: const Text('Payment Details'),
            content: SizedBox(
              width: 420,
              child: provider.isSalaryPaymentDetailLoading && !isSelectedPayment
                  ? const Center(child: CircularProgressIndicator())
                  : provider.salaryPaymentDetailError != null &&
                          !isSelectedPayment
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(provider.salaryPaymentDetailError!,
                                key: const ValueKey(
                                    'salary_payment_detail_error')),
                            TextButton(
                              onPressed: () =>
                                  provider.loadSalaryPaymentDetails(paymentId),
                              child: const Text('Retry'),
                            ),
                          ],
                        )
                      : payment == null || !isSelectedPayment
                          ? const SizedBox.shrink()
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _detailLine('Employee', payment.employeeName),
                                _detailLine('Employee ID', payment.employeeId),
                                _detailLine('Department', payment.department),
                                _detailLine('Payroll month',
                                    '${_MarkSalaryPaymentDialogState._months[payment.payrollMonth - 1]} ${payment.payrollYear}'),
                                _detailLine('Net salary',
                                    '₹ ${payment.netSalary.toStringAsFixed(2)}'),
                                _detailLine(
                                    'Payment date',
                                    payment.paymentDate == null
                                        ? '—'
                                        : _formatDate(payment.paymentDate!)),
                                _detailLine('Payment method',
                                    payment.paymentMethod ?? '—'),
                                _detailLine(
                                    'Transaction reference',
                                    payment.transactionReference.isEmpty
                                        ? '—'
                                        : payment.transactionReference),
                                _detailLine(
                                    'Remarks',
                                    payment.remarks.isEmpty
                                        ? '—'
                                        : payment.remarks),
                                _detailLine(
                                    'Confirmed by',
                                    payment.confirmedBy == null
                                        ? '—'
                                        : '${payment.confirmedBy!.firstName} ${payment.confirmedBy!.lastName}'
                                            .trim()),
                                _detailLine(
                                    'Confirmed at',
                                    payment.confirmedAt == null
                                        ? '—'
                                        : payment.confirmedAt!
                                            .toLocal()
                                            .toString()),
                              ],
                            ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close')),
            ],
          );
        },
      );

  static Widget _detailLine(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 145,
              child: Text(label,
                  style:
                      const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
            ),
            Expanded(
              child: Text(value,
                  style:
                      const TextStyle(color: Color(0xFF0F172A), fontSize: 13)),
            ),
          ],
        ),
      );

  static String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
