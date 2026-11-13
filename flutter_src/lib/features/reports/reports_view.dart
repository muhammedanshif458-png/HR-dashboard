import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/hr_models.dart';
import '../../providers/hr_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/header.dart';
import '../../widgets/sidebar.dart';

enum _DrillKind { attendance, leave }

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  String? _metric;
  _DrillKind? _kind;
  List<Attendance> _attendance = [];
  List<LeaveRequest> _leaves = [];
  bool _loading = false;
  String? _error;
  int _page = 1;
  int _total = 0;
  int _pages = 1;
  String? _activeStatus;
  String? _activeLeaveType;
  List<String>? _activeLeaveTypes;
  static const _limit = 25;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<HRProvider>().loadReports();
    });
  }

  String? _date(DateTime? value) => value == null
      ? null
      : '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  Future<void> _open(_DrillKind kind, String metric,
      {String? status, String? leaveType, List<String>? leaveTypes}) async {
    setState(() {
      _kind = kind;
      _metric = metric;
      _page = 1;
      _activeStatus = status;
      _activeLeaveType = leaveType;
      _activeLeaveTypes = leaveTypes;
      _attendance = [];
      _leaves = [];
    });
    await _loadPage(status: status, leaveType: leaveType);
  }

  Future<void> _loadPage({int? page, String? status, String? leaveType}) async {
    final provider = context.read<HRProvider>();
    final currentKind = _kind;
    if (currentKind == null) return;
    setState(() {
      _loading = true;
      _error = null;
      if (page != null) _page = page;
    });
    try {
      final start = _date(provider.reportsStartDate);
      final end = _date(provider.reportsEndDate);
      if (currentKind == _DrillKind.attendance) {
        final result = await ApiService.getAttendancePage(
          page: _page,
          limit: _limit,
          startDate: start,
          endDate: end,
          department: provider.reportsDepartmentFilter,
          status: _activeStatus,
        );
        if (!mounted) return;
        setState(() {
          _attendance = result.records;
          _total = result.total;
          _pages = result.totalPages;
        });
      } else {
        final leaveStatus = _activeStatus ?? provider.reportsStatusFilter;
        final leaveTypes = _activeLeaveTypes ??
            (_activeLeaveType != null
                ? [_activeLeaveType!]
                : provider.reportsLeaveTypeFilter == 'all'
                    ? null
                    : [provider.reportsLeaveTypeFilter]);
        final result = leaveTypes != null && leaveTypes.length > 1
            ? await _fetchCombinedLeavePage(
                provider, _page, leaveTypes, leaveStatus)
            : await ApiService.getLeavesPage(
                page: _page,
                limit: _limit,
                startDate: start,
                endDate: end,
                department: provider.reportsDepartmentFilter,
                status: leaveStatus,
                leaveType: leaveTypes?.first,
              );
        if (!mounted) return;
        setState(() {
          _leaves = result.leaves;
          _total = result.total;
          _pages = result.totalPages;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<LeavePage> _fetchCombinedLeavePage(HRProvider provider, int page,
      List<String> leaveTypes, String status) async {
    const requestLimit = 100;
    final needed = page * _limit;
    final leaves = <LeaveRequest>[];
    var total = 0;
    for (final leaveType in leaveTypes) {
      var typePage = 1;
      var typePages = 1;
      var collected = 0;
      while (typePage <= typePages && collected < needed) {
        final result = await ApiService.getLeavesPage(
          page: typePage,
          limit: requestLimit,
          startDate: _date(provider.reportsStartDate),
          endDate: _date(provider.reportsEndDate),
          department: provider.reportsDepartmentFilter,
          status: status,
          leaveType: leaveType,
        );
        if (typePage == 1) total += result.total;
        typePages = result.totalPages;
        collected += result.leaves.length;
        leaves.addAll(result.leaves);
        typePage++;
      }
    }
    leaves.sort((left, right) {
      final leftDate = DateTime.tryParse(left.submissionDate) ?? DateTime(0);
      final rightDate = DateTime.tryParse(right.submissionDate) ?? DateTime(0);
      return rightDate.compareTo(leftDate);
    });
    final startIndex = (page - 1) * _limit;
    final endIndex = startIndex + _limit;
    final pageLeaves = startIndex >= leaves.length
        ? <LeaveRequest>[]
        : leaves.sublist(
            startIndex, endIndex < leaves.length ? endIndex : leaves.length);
    final totalPages = (total + _limit - 1) ~/ _limit;
    return LeavePage(
      leaves: pageLeaves,
      page: page,
      limit: _limit,
      total: total,
      totalPages: totalPages,
    );
  }

  void _back() => setState(() {
        _kind = null;
        _metric = null;
        _error = null;
      });

  Future<void> _export() async {
    final provider = context.read<HRProvider>();
    final rows = <List<String>>[];
    if (_kind == _DrillKind.attendance) {
      var page = 1;
      var more = true;
      while (more) {
        final result = await ApiService.getAttendancePage(
            page: page,
            limit: 100,
            startDate: _date(provider.reportsStartDate),
            endDate: _date(provider.reportsEndDate),
            department: provider.reportsDepartmentFilter,
            status: _activeStatus);
        rows.addAll(result.records.map((r) => [
              r.employeeId,
              r.employeeName,
              r.department,
              r.date,
              r.checkInTime ?? '',
              r.checkOutTime ?? '',
              r.rawStatus,
              r.minutesLate?.toString() ?? '',
              r.workingHours.toString()
            ]));
        more = page < result.totalPages;
        page++;
      }
      rows.insert(0, [
        'Employee ID',
        'Employee Name',
        'Department',
        'Date',
        'Check-in',
        'Check-out',
        'Status',
        'Late minutes',
        'Working hours'
      ]);
    } else if (_kind == _DrillKind.leave) {
      final status = _activeStatus ?? provider.reportsStatusFilter;
      final leaveTypes = _activeLeaveTypes ??
          (_activeLeaveType != null
              ? [_activeLeaveType!]
              : provider.reportsLeaveTypeFilter == 'all'
                  ? <String?>[null]
                  : <String?>[provider.reportsLeaveTypeFilter]);
      for (final leaveType in leaveTypes) {
        var page = 1;
        var more = true;
        while (more) {
          final result = await ApiService.getLeavesPage(
              page: page,
              limit: 100,
              startDate: _date(provider.reportsStartDate),
              endDate: _date(provider.reportsEndDate),
              department: provider.reportsDepartmentFilter,
              status: status,
              leaveType: leaveType);
          rows.addAll(result.leaves.map((r) => [
                r.staffId,
                r.employeeName,
                r.department,
                r.leaveType,
                r.fromDate,
                r.toDate,
                r.daysCount.toString(),
                r.status,
                r.reason
              ]));
          more = page < result.totalPages;
          page++;
        }
      }
      rows.insert(0, [
        'Employee ID',
        'Employee Name',
        'Department',
        'Leave Type',
        'Start Date',
        'End Date',
        'Days',
        'Status',
        'Reason'
      ]);
    } else {
      final a = provider.effectiveAttendanceReport;
      final l = provider.effectiveLeaveReport;
      rows.addAll([
        ['Report', 'Metric', 'Count'],
        if (a.totalAttendanceRecords != null)
          [
            'Attendance',
            'totalAttendanceRecords',
            '${a.totalAttendanceRecords}'
          ],
        if (a.presentRecords != null)
          ['Attendance', 'presentRecords', '${a.presentRecords}'],
        if (a.totalAbsent != null)
          ['Attendance', 'totalAbsent', '${a.totalAbsent}'],
        if (a.lateArrivals != null)
          ['Attendance', 'lateArrivals', '${a.lateArrivals}'],
        if (a.onTimeArrivals != null)
          ['Attendance', 'onTimeArrivals', '${a.onTimeArrivals}'],
        if (a.averageWorkingHours != null)
          ['Attendance', 'averageWorkingHours', '${a.averageWorkingHours}'],
        if (a.workingHoursSampleSize != null)
          [
            'Attendance',
            'workingHoursSampleSize',
            '${a.workingHoursSampleSize}'
          ],
        ...a.statusSummary
            .map((s) => ['Attendance status', s.status, s.count.toString()]),
        ...a.departmentSummary.map((s) => [
              'Attendance department',
              '${s.department} • ${s.status}',
              s.count.toString()
            ]),
        if (l.totalLeaveApplications != null)
          ['Leave', 'totalLeaveApplications', '${l.totalLeaveApplications}'],
        if (l.approvedRequests != null)
          ['Leave', 'approvedRequests', '${l.approvedRequests}'],
        if (l.pendingRequests != null)
          ['Leave', 'pendingRequests', '${l.pendingRequests}'],
        if (l.rejectedRequests != null)
          ['Leave', 'rejectedRequests', '${l.rejectedRequests}'],
        if (l.casualLeaves != null)
          ['Leave', 'casualLeaves', '${l.casualLeaves}'],
        if (l.sickMedicalLeaves != null)
          ['Leave', 'sickMedicalLeaves', '${l.sickMedicalLeaves}'],
        if (l.earnedAnnualLeaves != null)
          ['Leave', 'earnedAnnualLeaves', '${l.earnedAnnualLeaves}'],
        ...l.statusSummary
            .map((s) => ['Leave status', s.status, s.count.toString()]),
        ...l.typeSummary
            .map((s) => ['Leave type', s.leaveType, s.count.toString()])
      ]);
    }
    final csv = rows
        .map((row) => row.map((v) => '"${v.replaceAll('"', '""')}"').join(','))
        .join('\r\n');
    await Clipboard.setData(ClipboardData(text: csv));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report CSV copied to clipboard')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<HRProvider>();
    final a = p.effectiveAttendanceReport;
    final l = p.effectiveLeaveReport;
    return Scaffold(
      appBar: const Header(),
      drawer: const AppSidebar(isDrawer: true),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(builder: (context, constraints) {
              final title = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_kind == null)
                    const Text('LY SOFTWARE · ANALYTICS & REPORTS',
                        style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: .7)),
                  const SizedBox(height: 6),
                  Text(_metric ?? 'HR Reports & Workforce Analytics',
                      style: const TextStyle(
                          fontSize: 24,
                          color: Color(0xFF172033),
                          fontWeight: FontWeight.bold)),
                  if (_kind == null) ...[
                    const SizedBox(height: 5),
                    const Text(
                        'Executive breakdown of attendance, punctuality and leave.',
                        style: TextStyle(color: Color(0xFF64748B))),
                  ],
                ],
              );
              final actions = Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (_kind != null)
                    TextButton.icon(
                      onPressed: _back,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back to Overview'),
                    ),
                  IconButton(
                    onPressed: p.isReportsLoading ? null : p.loadReports,
                    icon: const Icon(Icons.refresh),
                  ),
                  ElevatedButton.icon(
                    onPressed: _export,
                    icon: const Icon(Icons.download),
                    label: const Text('Export Report'),
                  ),
                ],
              );
              if (constraints.maxWidth < 680) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [title, actions],
                );
              }
              return Row(children: [Expanded(child: title), actions]);
            }),
            const SizedBox(height: 18),
            if (_kind == null)
              Wrap(
                spacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      final range = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2018),
                        lastDate: DateTime.now(),
                        initialDateRange: p.reportsStartDate != null &&
                                p.reportsEndDate != null
                            ? DateTimeRange(
                                start: p.reportsStartDate!,
                                end: p.reportsEndDate!)
                            : null,
                      );
                      if (range != null) {
                        p.setReportsDateRange(range.start, range.end);
                      }
                    },
                    icon: const Icon(Icons.date_range),
                    label: Text(p.reportsStartDate == null
                        ? 'Date range'
                        : '${_date(p.reportsStartDate)} – ${_date(p.reportsEndDate)}'),
                  ),
                  DropdownButton<String>(
                    value: p.reportsDepartmentFilter,
                    items: [
                      const DropdownMenuItem(
                          value: 'all', child: Text('All departments')),
                      ...p.departments.map((d) => DropdownMenuItem(
                          value: d.title, child: Text(d.title)))
                    ],
                    onChanged: (v) {
                      if (v != null) p.setReportsDepartmentFilter(v);
                    },
                  ),
                  DropdownButton<String>(
                    value: p.reportsStatusFilter,
                    items: const [
                      DropdownMenuItem(
                          value: 'all', child: Text('All leave statuses')),
                      DropdownMenuItem(
                          value: 'APPROVED', child: Text('Approved')),
                      DropdownMenuItem(
                          value: 'PENDING', child: Text('Pending')),
                      DropdownMenuItem(
                          value: 'REJECTED', child: Text('Rejected'))
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        p.reportsStatusFilter = v;
                        p.loadReports();
                      }
                    },
                  ),
                  DropdownButton<String>(
                    value: p.reportsLeaveTypeFilter,
                    items: [
                      const DropdownMenuItem(
                          value: 'all', child: Text('All leave types')),
                      ...p.effectiveLeaveReport.typeSummary.map((t) =>
                          DropdownMenuItem(
                              value: t.leaveType, child: Text(t.leaveType)))
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        p.reportsLeaveTypeFilter = v;
                        p.loadReports();
                      }
                    },
                  ),
                ],
              ),
            if (_kind == null)
              Expanded(
                child: p.isReportsLoading && !p.hasLoadedApiReports
                    ? const Center(child: CircularProgressIndicator())
                    : p.reportsError != null && !p.hasLoadedApiReports
                        ? Center(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                Text(p.reportsError!),
                                ElevatedButton(
                                    onPressed: p.loadReports,
                                    child: const Text('Retry'))
                              ]))
                        : _buildOverview(p, a, l),
              )
            else
              _buildDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverview(
          HRProvider provider, AttendanceReportData a, LeaveReportData l) =>
      LayoutBuilder(builder: (context, constraints) {
        final attendance = _analyticsCard(
          title: 'Attendance & Punctuality Overview',
          icon: Icons.access_time,
          rows: [
            if (a.totalAttendanceRecords != null)
              _analyticsMetric(
                  'Total Attendance Records',
                  '${a.totalAttendanceRecords}',
                  const Color(0xFF2563EB),
                  () =>
                      _open(_DrillKind.attendance, 'Total Attendance Records')),
            if (a.presentRecords != null)
              _analyticsMetric(
                  'Total Present',
                  '${a.presentRecords}',
                  const Color(0xFF16A34A),
                  () => _open(_DrillKind.attendance, 'Total Present',
                      status: 'PRESENT')),
            if (a.totalAbsent != null)
              _analyticsMetric(
                  'Total Absent',
                  '${a.totalAbsent}',
                  const Color(0xFFDC2626),
                  () => _open(_DrillKind.attendance, 'Total Absent',
                      status: 'ABSENT')),
            if (_summaryStatusCount(a, 'HALF_DAY') != null)
              _analyticsMetric(
                  'Half Day',
                  '${_summaryStatusCount(a, 'HALF_DAY')}',
                  const Color(0xFFD97706),
                  () => _open(_DrillKind.attendance, 'Half Day',
                      status: 'HALF_DAY')),
            if (a.lateArrivals != null)
              _analyticsMetric(
                  'Late Arrivals',
                  '${a.lateArrivals}',
                  const Color(0xFFEA580C),
                  () => _open(_DrillKind.attendance, 'Late Arrivals',
                      status: 'LATE')),
            if (a.onTimeArrivals != null)
              _analyticsMetric(
                  'On-Time Arrivals',
                  '${a.onTimeArrivals}',
                  const Color(0xFF16A34A),
                  () => _open(_DrillKind.attendance, 'On-Time Arrivals',
                      status: 'ON_TIME')),
            if (a.averageWorkingHours != null ||
                a.workingHoursSampleSize != null)
              _analyticsMetric(
                  'Average Hours Worked',
                  '${a.averageWorkingHours?.toStringAsFixed(2) ?? '—'} hrs${a.workingHoursSampleSize == null ? '' : ' · ${a.workingHoursSampleSize} samples'}',
                  const Color(0xFF0F9D8A),
                  () => _open(_DrillKind.attendance, 'Average Working Hours',
                      status: 'WORKED_HOURS')),
          ],
        );
        final leaves = _analyticsCard(
          title: 'Leave Distribution & Types Overview',
          icon: Icons.pie_chart_outline,
          rows: [
            if (l.totalLeaveApplications != null)
              _analyticsMetric(
                  'Total Leave Requests',
                  '${l.totalLeaveApplications}',
                  const Color(0xFF64748B),
                  () => _open(_DrillKind.leave, 'Total Leave Requests')),
            if (l.approvedRequests != null)
              _analyticsMetric(
                  'Approved Leave Requests',
                  '${l.approvedRequests}',
                  const Color(0xFF16A34A),
                  () => _open(_DrillKind.leave, 'Approved', status: 'APPROVED'),
                  enabled: provider.reportsStatusFilter == 'all' ||
                      provider.reportsStatusFilter == 'APPROVED'),
            if (l.pendingRequests != null)
              _analyticsMetric(
                  'Pending Approvals',
                  '${l.pendingRequests}',
                  const Color(0xFFD97706),
                  () => _open(_DrillKind.leave, 'Pending', status: 'PENDING'),
                  enabled: provider.reportsStatusFilter == 'all' ||
                      provider.reportsStatusFilter == 'PENDING'),
            if (l.rejectedRequests != null)
              _analyticsMetric(
                  'Rejected Requests',
                  '${l.rejectedRequests}',
                  const Color(0xFFDC2626),
                  () => _open(_DrillKind.leave, 'Rejected', status: 'REJECTED'),
                  enabled: provider.reportsStatusFilter == 'all' ||
                      provider.reportsStatusFilter == 'REJECTED'),
            if (l.sickMedicalLeaves != null)
              _analyticsMetric(
                  'Medical / Sick Leaves',
                  '${l.sickMedicalLeaves}',
                  const Color(0xFF9333EA),
                  () => _open(_DrillKind.leave, 'Sick / Medical Leaves',
                      leaveTypes: provider.reportsLeaveTypeFilter == 'all'
                          ? const ['SICK', 'MEDICAL']
                          : [provider.reportsLeaveTypeFilter]),
                  enabled: provider.reportsLeaveTypeFilter == 'all' ||
                      const ['SICK', 'MEDICAL'].contains(
                          provider.reportsLeaveTypeFilter.toUpperCase())),
            if (l.casualLeaves != null)
              _analyticsMetric(
                  'Casual Leaves',
                  '${l.casualLeaves}',
                  const Color(0xFF2563EB),
                  () => _open(_DrillKind.leave, 'Casual Leaves',
                      leaveType: 'CASUAL'),
                  enabled: provider.reportsLeaveTypeFilter == 'all' ||
                      provider.reportsLeaveTypeFilter.toUpperCase() ==
                          'CASUAL'),
            if (l.earnedAnnualLeaves != null)
              _analyticsMetric(
                  'Earned / Annual Leaves',
                  '${l.earnedAnnualLeaves}',
                  const Color(0xFF0F9D8A),
                  () => _open(_DrillKind.leave, 'Earned / Annual Leaves',
                      leaveType: 'ANNUAL'),
                  enabled: provider.reportsLeaveTypeFilter == 'all' ||
                      const ['ANNUAL', 'EARNED'].contains(
                          provider.reportsLeaveTypeFilter.toUpperCase())),
          ],
        );
        if (constraints.maxWidth >= 960) {
          return SingleChildScrollView(
            padding: const EdgeInsets.only(top: 10, bottom: 18),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: attendance),
              const SizedBox(width: 20),
              Expanded(child: leaves),
            ]),
          );
        }
        return ListView(
          padding: const EdgeInsets.only(top: 10, bottom: 18),
          children: [attendance, const SizedBox(height: 16), leaves],
        );
      });

  Widget _analyticsCard(
          {required String title,
          required IconData icon,
          required List<Widget> rows}) =>
      Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5EAF1))),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: const Color(0xFF2563EB), size: 22),
            const SizedBox(width: 10),
            Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF182230))))
          ]),
          const SizedBox(height: 14),
          if (rows.isEmpty)
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No report metrics available.',
                    style: TextStyle(color: Color(0xFF64748B))))
          else
            ...rows,
        ]),
      );

  Widget _analyticsMetric(
          String label, String value, Color color, VoidCallback onTap,
          {bool enabled = true}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
              child: Row(children: [
                Expanded(
                    child: Text(label,
                        style: TextStyle(
                            color: enabled
                                ? const Color(0xFF475569)
                                : const Color(0xFF94A3B8),
                            fontSize: 13))),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: enabled ? .1 : .06),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(value,
                      style: TextStyle(
                          color: enabled ? color : const Color(0xFF94A3B8),
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 7),
                Icon(Icons.chevron_right,
                    size: 18,
                    color:
                        enabled ? const Color(0xFF94A3B8) : Colors.transparent),
              ]),
            ),
          ),
        ),
      );

  int? _summaryStatusCount(AttendanceReportData report, String status) {
    for (final item in report.statusSummary) {
      if (item.status.toUpperCase() == status) return item.count;
    }
    return null;
  }

  Widget _buildDetails() {
    if (_loading) {
      return const Expanded(child: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Expanded(
          child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(_error!),
        ElevatedButton(onPressed: () => _loadPage(), child: const Text('Retry'))
      ])));
    }
    final count =
        _kind == _DrillKind.attendance ? _attendance.length : _leaves.length;
    if (count == 0) {
      return const Expanded(child: Center(child: Text('No matching records')));
    }
    final headers = _kind == _DrillKind.attendance
        ? [
            'Employee ID',
            'Employee Name',
            'Department',
            'Date',
            'Check-in',
            'Check-out',
            'Status',
            'Late duration',
            'Working hours'
          ]
        : [
            'Employee ID',
            'Employee Name',
            'Department',
            'Leave Type',
            'Start Date',
            'End Date',
            'Days',
            'Status',
            'Reason'
          ];
    final rows = _kind == _DrillKind.attendance
        ? _attendance
            .map((r) => [
                  r.employeeId,
                  r.employeeName,
                  r.department,
                  r.date,
                  r.checkInTime ?? '—',
                  r.checkOutTime ?? '—',
                  r.rawStatus,
                  r.minutesLate == null ? '—' : '${r.minutesLate} min',
                  r.workingHours <= 0 ? '—' : '${r.workingHours}'
                ])
            .toList()
        : _leaves
            .map((r) => [
                  r.staffId,
                  r.employeeName,
                  r.department,
                  r.leaveType,
                  r.formattedFromDate,
                  r.formattedToDate,
                  r.daysCount <= 0 ? '—' : '${r.daysCount}',
                  r.status,
                  r.reason
                ])
            .toList();
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$_total records • Page $_page of ${_pages < 1 ? 1 : _pages}'),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  columns:
                      headers.map((h) => DataColumn(label: Text(h))).toList(),
                  rows: List.generate(
                    rows.length,
                    (i) => DataRow(
                      cells: rows[i]
                          .map((v) => DataCell(
                                Text(v,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                                onTap: () => _showDetail(headers, rows[i]),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _page > 1 ? () => _loadPage(page: _page - 1) : null,
                child: const Text('Previous'),
              ),
              TextButton(
                onPressed:
                    _page < _pages ? () => _loadPage(page: _page + 1) : null,
                child: const Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDetail(List<String> headers, List<String> values) =>
      showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
                  title: const Text('Record details'),
                  content: SizedBox(
                      width: 420,
                      child: SingleChildScrollView(
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(
                                  headers.length,
                                  (i) => ListTile(
                                      dense: true,
                                      title: Text(headers[i]),
                                      subtitle: Text(values[i])))))),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'))
                  ]));
}
