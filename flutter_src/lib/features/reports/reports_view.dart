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
  bool _includeHalfDayInPresent = false;
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
      {String? status, String? leaveType, bool includeHalfDay = false}) async {
    setState(() {
      _kind = kind;
      _metric = metric;
      _page = 1;
      _activeStatus = status;
      _activeLeaveType = leaveType;
      _includeHalfDayInPresent = includeHalfDay;
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
        final result = _includeHalfDayInPresent
            ? await _fetchCombinedPresentPage(provider, _page)
            : await ApiService.getAttendancePage(
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
        final result = await ApiService.getLeavesPage(
          page: _page,
          limit: _limit,
          startDate: start,
          endDate: end,
          department: provider.reportsDepartmentFilter,
          status: _activeStatus ?? provider.reportsStatusFilter,
          leaveType: _activeLeaveType ?? provider.reportsLeaveTypeFilter,
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

  Future<AttendancePage> _fetchCombinedPresentPage(
      HRProvider provider, int page) async {
    const requestLimit = 100;
    final needed = page * _limit;
    final records = <Attendance>[];
    var total = 0;
    for (final status in const ['PRESENT', 'HALF_DAY']) {
      var statusPage = 1;
      var statusPages = 1;
      var collected = 0;
      while (statusPage <= statusPages && collected < needed) {
        final result = await ApiService.getAttendancePage(
          page: statusPage,
          limit: requestLimit,
          startDate: _date(provider.reportsStartDate),
          endDate: _date(provider.reportsEndDate),
          department: provider.reportsDepartmentFilter,
          status: status,
        );
        if (statusPage == 1) total += result.total;
        statusPages = result.totalPages;
        collected += result.records.length;
        records.addAll(result.records);
        statusPage++;
      }
    }
    records.sort((left, right) {
      final leftDate = DateTime.tryParse(left.checkInAt ?? left.date) ??
          DateTime.tryParse(left.date) ??
          DateTime(0);
      final rightDate = DateTime.tryParse(right.checkInAt ?? right.date) ??
          DateTime.tryParse(right.date) ??
          DateTime(0);
      return rightDate.compareTo(leftDate);
    });
    final startIndex = (page - 1) * _limit;
    final endIndex = startIndex + _limit;
    final pageRecords = startIndex >= records.length
        ? <Attendance>[]
        : records.sublist(
            startIndex, endIndex < records.length ? endIndex : records.length);
    final totalPages = (total + _limit - 1) ~/ _limit;
    return AttendancePage(
      records: pageRecords,
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
      final statuses = _includeHalfDayInPresent
          ? const ['PRESENT', 'HALF_DAY']
          : <String?>[_activeStatus];
      final exportedRecords = <Attendance>[];
      for (final status in statuses) {
        var page = 1;
        var more = true;
        while (more) {
          final result = await ApiService.getAttendancePage(
              page: page,
              limit: 100,
              startDate: _date(provider.reportsStartDate),
              endDate: _date(provider.reportsEndDate),
              department: provider.reportsDepartmentFilter,
              status: status);
          exportedRecords.addAll(result.records);
          more = page < result.totalPages;
          page++;
        }
      }
      for (final r in exportedRecords) {
        rows.add([
              r.employeeId,
              r.employeeName,
              r.department,
              r.date,
              r.checkInTime ?? '',
              r.checkOutTime ?? '',
              r.rawStatus,
              r.minutesLate?.toString() ?? '',
              r.workingHours.toString()
            ]);
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
      var page = 1;
      var more = true;
      while (more) {
        final result = await ApiService.getLeavesPage(
            page: page,
            limit: 100,
            startDate: _date(provider.reportsStartDate),
            endDate: _date(provider.reportsEndDate),
            department: provider.reportsDepartmentFilter,
            status: _activeStatus ?? provider.reportsStatusFilter,
            leaveType: _activeLeaveType ?? provider.reportsLeaveTypeFilter);
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
        ...a.statusSummary
            .map((s) => ['Attendance status', s.status, s.count.toString()]),
        ...a.departmentSummary.map((s) => [
              'Attendance department',
              '${s.department} • ${s.status}',
              s.count.toString()
            ]),
        if (a.lateArrivals != null)
          ['Attendance', 'Late arrivals', a.lateArrivals.toString()],
        if (a.onTimeArrivals != null)
          ['Attendance', 'On-time arrivals', a.onTimeArrivals.toString()],
        if (a.totalAbsent != null)
          ['Attendance', 'Total absent', a.totalAbsent.toString()],
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
              final title = Text(
                _metric ?? 'HR Reports & Workforce Analytics',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
            const SizedBox(height: 12),
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
                        : _buildOverview(a, l),
              )
            else
              _buildDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverview(AttendanceReportData a, LeaveReportData l) => ListView(
        children: [
          const Text('Attendance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Wrap(spacing: 12, children: [
            _metricButton(
                'Total Present',
                a.presentCount,
                () => _open(_DrillKind.attendance, 'Total Present',
                    status: 'PRESENT', includeHalfDay: true)),
            if (a.totalAbsent != null)
              _metricButton(
                  'Total Absent',
                  a.totalAbsent!,
                  () => _open(_DrillKind.attendance, 'Total Absent',
                      status: 'ABSENT')),
            if (a.lateArrivals != null)
              _metricButton(
                  'Late Arrivals',
                  a.lateArrivals!,
                  () => _open(_DrillKind.attendance, 'Late Arrivals',
                      status: 'LATE')),
            if (a.onTimeArrivals != null)
              _metricButton(
                  'On-Time Arrivals',
                  a.onTimeArrivals!,
                  () => _open(_DrillKind.attendance, 'On-Time Arrivals',
                      status: 'ON_TIME')),
          ]),
          if (a.statusSummary.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text('Attendance status summary',
                style: TextStyle(fontWeight: FontWeight.w600)),
            ...a.statusSummary.map((s) => ListTile(
                dense: true,
                title: Text(s.status),
                trailing: Text('${s.count}'))),
          ],
          if (a.departmentSummary.isNotEmpty) ...[
            const Text('Department summary',
                style: TextStyle(fontWeight: FontWeight.w600)),
            ...a.departmentSummary.map((s) => ListTile(
                dense: true,
                title: Text('${s.department} • ${s.status}'),
                trailing: Text(
                    '${s.count} • ${s.totalHours <= 0 ? '—' : '${s.totalHours} hrs'}'))),
          ],
          const Divider(height: 32, thickness: 1),
          const Text('Leave requests',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Wrap(spacing: 12, children: [
            _metricButton('Total Leave Requests', l.totalApplications,
                () => _open(_DrillKind.leave, 'Total Leave Requests')),
            ...l.statusSummary.map((s) => _metricButton(s.status, s.count,
                () => _open(_DrillKind.leave, s.status, status: s.status))),
            ...l.typeSummary.map((t) => _metricButton(
                t.leaveType,
                t.count,
                () => _open(_DrillKind.leave, t.leaveType,
                    leaveType: t.leaveType))),
          ]),
          if (l.statusSummary.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text('Leave status summary',
                style: TextStyle(fontWeight: FontWeight.w600)),
            ...l.statusSummary.map((s) => ListTile(
                dense: true,
                title: Text(s.status),
                trailing: Text('${s.count}'))),
          ],
        ],
      );

  Widget _metricButton(String label, int count, VoidCallback onTap) =>
      OutlinedButton(onPressed: onTap, child: Text('$label  $count'));

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
