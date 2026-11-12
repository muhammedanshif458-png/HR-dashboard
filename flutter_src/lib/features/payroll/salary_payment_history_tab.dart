import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/hr_models.dart';
import '../../providers/hr_provider.dart';

class SalaryPaymentHistoryTab extends StatefulWidget {
  const SalaryPaymentHistoryTab({super.key});

  @override
  State<SalaryPaymentHistoryTab> createState() =>
      _SalaryPaymentHistoryTabState();
}

class _SalaryPaymentHistoryTabState extends State<SalaryPaymentHistoryTab> {
  static const _departmentOptions = <String>[
    'all',
    'Tech',
    'Telecalling',
    'Management',
  ];

  static const _months = <String>[
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
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    final provider = context.read<HRProvider>();
    _searchController =
        TextEditingController(text: provider.salaryPaymentSearchQuery);
    if (!_departmentOptions.contains(provider.salaryPaymentDepartment)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final current = context.read<HRProvider>();
        if (!_departmentOptions.contains(current.salaryPaymentDepartment)) {
          current.setSalaryPaymentDepartment('all', historyOnly: true);
        }
      });
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showDetails(
      BuildContext context, HRProvider provider, SalaryPayment payment) async {
    unawaited(provider.loadSalaryPaymentDetails(payment.id));
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Consumer<HRProvider>(
        builder: (context, current, _) {
          final detail = current.selectedSalaryPayment?.id == payment.id
              ? current.selectedSalaryPayment
              : null;
          return AlertDialog(
            title: const Text('Payment Details'),
            content: SizedBox(
              width: 520,
              child: current.isSalaryPaymentDetailLoading
                  ? const SizedBox(
                      height: 100,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : current.salaryPaymentDetailError != null
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(current.salaryPaymentDetailError!),
                            TextButton(
                              onPressed: () =>
                                  current.loadSalaryPaymentDetails(payment.id),
                              child: const Text('Retry'),
                            ),
                          ],
                        )
                      : detail == null
                          ? const Text('Payment details are unavailable.')
                          : _detailsContent(detail),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _detailsContent(SalaryPayment payment) {
    final employee =
        payment.employeeName.trim().isEmpty ? '—' : payment.employeeName;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _detailRow('Employee', employee),
          _detailRow('Employee ID', _shown(payment.employeeId)),
          _detailRow('Department', _shown(payment.department)),
          _detailRow('Payroll month',
              _period(payment.payrollMonth, payment.payrollYear)),
          _detailRow('Net salary', _money(payment.netSalary)),
          _detailRow('Payment date', _date(payment.paymentDate)),
          _detailRow('Payment method', _method(payment.paymentMethod)),
          _detailRow(
              'Transaction reference', _shown(payment.transactionReference)),
          _detailRow('Remarks', _shown(payment.remarks)),
          _detailRow('Confirmed by', _confirmedBy(payment.confirmedBy)),
          _detailRow('Confirmed timestamp', _dateTime(payment.confirmedAt)),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 165,
              child: Text(label,
                  style: const TextStyle(
                      color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      color: Color(0xFF0F172A), fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HRProvider>();
    final selectedDepartment =
        _departmentOptions.contains(provider.salaryPaymentDepartment)
            ? provider.salaryPaymentDepartment
            : 'all';
    final year = provider.salaryPaymentYear;
    final years = <int>{
      for (var item = DateTime.now().year - 5;
          item <= DateTime.now().year + 1;
          item++)
        item,
      year,
    }.toList()
      ..sort();
    final searching = provider.salaryPaymentSearchQuery.trim().isNotEmpty;

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
                child: const Icon(Icons.history_outlined,
                    color: Color(0xFF2563EB), size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Payment History',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A))),
                    SizedBox(height: 3),
                    Text('Review employee salary payments and confirmations.',
                        style:
                            TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              IconButton(
                key: const ValueKey('salary_payment_history_refresh'),
                tooltip: 'Refresh Payment History',
                onPressed: provider.isSalaryPaymentHistoryLoading
                    ? null
                    : () => provider.loadSalaryPaymentHistory(page: 1),
                icon: provider.isSalaryPaymentHistoryLoading
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
            children: [
              SizedBox(
                width: 150,
                child: DropdownButtonFormField<int>(
                  key: ValueKey(
                      'payment_history_month_${provider.salaryPaymentMonth}'),
                  initialValue: provider.salaryPaymentMonth,
                  isExpanded: true,
                  decoration: _filterDecoration('Month'),
                  items: List.generate(12, (i) => i + 1)
                      .map((month) => DropdownMenuItem(
                            value: month,
                            child: Text(_months[month - 1]),
                          ))
                      .toList(),
                  onChanged: (month) {
                    if (month != null) {
                      provider.setSalaryPaymentMonth(month, year,
                          historyOnly: true);
                    }
                  },
                ),
              ),
              SizedBox(
                width: 120,
                child: DropdownButtonFormField<int>(
                  key: ValueKey('payment_history_year_$year'),
                  initialValue: year,
                  isExpanded: true,
                  decoration: _filterDecoration('Year'),
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
                          historyOnly: true);
                    }
                  },
                ),
              ),
              SizedBox(
                width: 210,
                child: DropdownButtonFormField<String>(
                  key: ValueKey(
                      'payment_history_department_$selectedDepartment'),
                  initialValue: selectedDepartment,
                  isExpanded: true,
                  decoration: _filterDecoration('Department'),
                  items: _departmentOptions
                      .map((department) => DropdownMenuItem(
                            value: department,
                            child: Text(department == 'all'
                                ? 'All Departments'
                                : department),
                          ))
                      .toList(),
                  onChanged: (department) {
                    if (department != null) {
                      provider.setSalaryPaymentDepartment(department,
                          historyOnly: true);
                    }
                  },
                ),
              ),
              SizedBox(
                width: 165,
                child: DropdownButtonFormField<String>(
                  key: ValueKey(
                      'payment_history_status_${provider.salaryPaymentStatusFilter}'),
                  initialValue:
                      provider.salaryPaymentStatusFilter.toLowerCase() == 'all'
                          ? 'all'
                          : provider.salaryPaymentStatusFilter,
                  isExpanded: true,
                  decoration: _filterDecoration('Payment Status'),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(value: 'PAID', child: Text('PAID')),
                    DropdownMenuItem(value: 'PENDING', child: Text('PENDING')),
                  ],
                  onChanged: (status) {
                    if (status != null) {
                      provider.setSalaryPaymentStatus(status,
                          historyOnly: true);
                    }
                  },
                ),
              ),
              SizedBox(
                width: 255,
                child: TextField(
                  key: const ValueKey('payment_history_search'),
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
                              _searchDebounce?.cancel();
                              _searchController.clear();
                              provider.setSalaryPaymentSearch('',
                                  historyOnly: true);
                              setState(() {});
                            },
                            icon: const Icon(Icons.close, size: 18),
                          ),
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  onChanged: (value) {
                    setState(() {});
                    _searchDebounce?.cancel();
                    _searchDebounce = Timer(
                        const Duration(milliseconds: 350),
                        () => provider.setSalaryPaymentSearch(value,
                            historyOnly: true));
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (provider.salaryPaymentHistoryError != null)
            _errorBanner(provider.salaryPaymentHistoryError!,
                () => provider.loadSalaryPaymentHistory(page: 1)),
          if (provider.isSalaryPaymentHistoryLoading &&
              provider.salaryPaymentHistory.isNotEmpty)
            const LinearProgressIndicator(minHeight: 2),
          if (provider.isSalaryPaymentHistoryLoading &&
              provider.salaryPaymentHistory.isEmpty)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (provider.salaryPaymentHistoryError != null)
            const SizedBox.shrink()
          else if (provider.salaryPaymentHistory.isEmpty)
            _emptyState(searching)
          else
            _historyTable(provider),
        ],
      ),
    );
  }

  InputDecoration _filterDecoration(String label) => InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      );

  Widget _historyTable(HRProvider provider) {
    final rows = provider.salaryPaymentHistory;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
              columns: const [
                DataColumn(label: Text('Employee ID')),
                DataColumn(label: Text('Employee Name')),
                DataColumn(label: Text('Department')),
                DataColumn(label: Text('Payroll Month')),
                DataColumn(label: Text('Net Salary')),
                DataColumn(label: Text('Payment Status')),
                DataColumn(label: Text('Payment Date')),
                DataColumn(label: Text('Payment Method')),
                DataColumn(label: Text('Transaction Reference')),
                DataColumn(label: Text('Confirmed By')),
                DataColumn(label: Text('Action')),
              ],
              rows: rows.map((payment) {
                final paid = payment.status.toUpperCase() == 'PAID';
                return DataRow(cells: [
                  DataCell(Text(_shown(payment.employeeId))),
                  DataCell(Text(_shown(payment.employeeName))),
                  DataCell(Text(_shown(payment.department))),
                  DataCell(
                      Text(_period(payment.payrollMonth, payment.payrollYear))),
                  DataCell(Text(_money(payment.netSalary))),
                  DataCell(_statusBadge(paid)),
                  DataCell(Text(_date(payment.paymentDate))),
                  DataCell(Text(_method(payment.paymentMethod))),
                  DataCell(Text(_shown(payment.transactionReference))),
                  DataCell(Text(_confirmedBy(payment.confirmedBy))),
                  DataCell(paid
                      ? TextButton.icon(
                          key:
                              ValueKey('payment_history_details_${payment.id}'),
                          onPressed: () =>
                              _showDetails(context, provider, payment),
                          icon: const Icon(Icons.visibility_outlined, size: 17),
                          label: const Text('View Details'),
                        )
                      : const Text('—')),
                ]);
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
                '${provider.salaryPaymentHistoryTotal == 0 ? rows.length : provider.salaryPaymentHistoryTotal} records · Page ${provider.salaryPaymentHistoryPage} of ${provider.salaryPaymentHistoryTotalPages}'),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Previous page',
              onPressed: provider.salaryPaymentHistoryPage > 1 &&
                      !provider.isSalaryPaymentHistoryLoading
                  ? () => provider.setSalaryPaymentHistoryPage(
                      provider.salaryPaymentHistoryPage - 1)
                  : null,
              icon: const Icon(Icons.chevron_left),
            ),
            IconButton(
              tooltip: 'Next page',
              onPressed: provider.salaryPaymentHistoryPage <
                          provider.salaryPaymentHistoryTotalPages &&
                      !provider.isSalaryPaymentHistoryLoading
                  ? () => provider.setSalaryPaymentHistoryPage(
                      provider.salaryPaymentHistoryPage + 1)
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statusBadge(bool paid) {
    final color = paid ? const Color(0xFF059669) : const Color(0xFFD97706);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(paid ? 'PAID' : 'PENDING',
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _emptyState(bool searching) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(44),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Icon(Icons.history, size: 42, color: Color(0xFF94A3B8)),
            const SizedBox(height: 10),
            Text(searching
                ? 'No payment history matches your search.'
                : 'No salary payment history found for this period.'),
          ],
        ),
      );

  Widget _errorBanner(String message, VoidCallback retry) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          border: Border.all(color: const Color(0xFFFECACA)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFB91C1C)),
            const SizedBox(width: 10),
            Expanded(
                child: Text(message,
                    style: const TextStyle(color: Color(0xFF991B1B)))),
            TextButton(onPressed: retry, child: const Text('Retry')),
          ],
        ),
      );
}

String _shown(String? value) =>
    value == null || value.trim().isEmpty ? '—' : value;

String _money(double amount) => '₹ ${amount.toStringAsFixed(2)}';

String _period(int month, int year) => month >= 1 && month <= 12
    ? '${_SalaryPaymentHistoryTabState._months[month - 1]} $year'
    : '$year';

String _date(DateTime? value) {
  if (value == null) return '—';
  return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}

String _dateTime(DateTime? value) {
  if (value == null) return '—';
  final local = value.toLocal();
  return '${_date(local)} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

String _method(String? value) {
  switch (value?.toUpperCase()) {
    case 'CASH':
      return 'Cash';
    case 'BANK_TRANSFER':
      return 'Bank Transfer';
    case 'UPI':
      return 'UPI';
    default:
      return '—';
  }
}

String _confirmedBy(SalaryPaymentUser? user) {
  if (user == null) return '—';
  final name = '${user.firstName} ${user.lastName}'.trim();
  return name.isEmpty ? _shown(user.email) : name;
}
