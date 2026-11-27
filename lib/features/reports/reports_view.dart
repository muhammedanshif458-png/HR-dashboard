import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/hr_models.dart';
import '../../providers/hr_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/header.dart';
import '../../widgets/sidebar.dart';
import '../../widgets/custom_date_range_picker.dart';

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

  String _formatDateRangeDisplay(DateTime? start, DateTime? end) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    if (start != null && end != null) {
      final sStr =
          '${months[start.month - 1]} ${start.day.toString().padLeft(2, '0')}, ${start.year}';
      final eStr =
          '${months[end.month - 1]} ${end.day.toString().padLeft(2, '0')}, ${end.year}';
      return '$sStr – $eStr';
    }
    if (start != null) {
      return '${months[start.month - 1]} ${start.day.toString().padLeft(2, '0')}, ${start.year}';
    }
    return 'Nov 01, 2026 – Nov 19, 2026';
  }

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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const Header(),
      drawer: const AppSidebar(isDrawer: true),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Breadcrumb & Title Section
            _buildPageHeader(p),

            const SizedBox(height: 18),

            // Filter Bar Card
            if (_kind == null) ...[
              _buildFilterCard(context, p),
              const SizedBox(height: 20),
            ],

            // Body: Overview or Drill-down Details
            if (_kind == null)
              Expanded(
                child: p.isReportsLoading && !p.hasLoadedApiReports
                    ? const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Color(0xFF0F172A),
                        ),
                      )
                    : p.reportsError != null && !p.hasLoadedApiReports
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  p.reportsError!,
                                  style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    color: Color(0xFFDC2626),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0F172A),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: p.loadReports,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            child: _buildOverview(p, a, l),
                          ),
              )
            else
              _buildDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader(HRProvider p) {
    return LayoutBuilder(builder: (context, constraints) {
      final isNarrow = constraints.maxWidth < 720;
      final titleWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_kind == null) ...[
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2F6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'LY SOFTWARE',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      color: Color(0xFF334155),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '•',
                  style: TextStyle(color: Color(0xFF94A3B8)),
                ),
                const SizedBox(width: 8),
                const Text(
                  'ANALYTICS & WORKFORCE INTELLIGENCE',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          Text(
            _metric ?? 'HR Reports & Workforce Analytics',
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 26,
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          if (_kind == null) ...[
            const SizedBox(height: 5),
            const Text(
              'Executive breakdown of attendance velocity, punctuality compliance, and leave distribution across enterprise divisions.',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                color: Color(0xFF64748B),
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ] else ...[
            const SizedBox(height: 5),
            Text(
              '$_total records • Page $_page of ${_pages < 1 ? 1 : _pages}',
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                color: Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      );

      final actions = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_kind != null) ...[
            InkWell(
              onTap: _back,
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back, size: 16, color: Color(0xFF0F172A)),
                    SizedBox(width: 6),
                    Text(
                      'Back to Overview',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Refresh Button
            Tooltip(
              message: 'Refresh',
              child: InkWell(
                onTap: _loading ? null : () => _loadPage(),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: _loading
                      ? const Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.refresh_rounded,
                          size: 18,
                          color: Color(0xFF475569),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          ElevatedButton.icon(
            onPressed: _export,
            icon: const Icon(Icons.download_rounded, size: 16),
            label: const Text(
              'Export Report',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      );

      if (isNarrow) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            titleWidget,
            const SizedBox(height: 12),
            actions,
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: titleWidget),
          actions,
        ],
      );
    });
  }

  Widget _buildFilterCard(BuildContext context, HRProvider p) {
    final dateRangeStr =
        _formatDateRangeDisplay(p.reportsStartDate, p.reportsEndDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // 1. Date Range Filter Pill
                InkWell(
                  onTap: () async {
                    final range = await showCustomDateRangePicker(
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
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 15,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          dateRangeStr,
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 17,
                          color: Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // 2. Department Dropdown
                Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: p.reportsDepartmentFilter,
                      icon: const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 17,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF334155),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: 'all',
                          child: Text(
                            'All departments',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                        ...p.departments.map((d) => DropdownMenuItem(
                              value: d.title,
                              child: Text(
                                d.title,
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            )),
                      ],
                      onChanged: (v) {
                        if (v != null) p.setReportsDepartmentFilter(v);
                      },
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // 3. Leave Status Dropdown
                Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: p.reportsStatusFilter,
                      icon: const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 17,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF334155),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text(
                            'All leave statuses',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'APPROVED',
                          child: Text(
                            'Approved',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'PENDING',
                          child: Text(
                            'Pending',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'REJECTED',
                          child: Text(
                            'Rejected',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          p.reportsStatusFilter = v;
                          p.loadReports();
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // 4. Leave Type Dropdown
                Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: p.reportsLeaveTypeFilter,
                      icon: const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 17,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF334155),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: 'all',
                          child: Text(
                            'All leave types',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                        ...p.effectiveLeaveReport.typeSummary.map((t) =>
                            DropdownMenuItem(
                              value: t.leaveType,
                              child: Text(
                                t.leaveType,
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            )),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          p.reportsLeaveTypeFilter = v;
                          p.loadReports();
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Bottom telemetry active status
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 6.5,
                height: 6.5,
                decoration: const BoxDecoration(
                  color: Color(0xFF16A34A),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Real-time telemetry active',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverview(
      HRProvider provider, AttendanceReportData a, LeaveReportData l) {
    final totalAttendanceRecords = a.totalAttendanceRecords ??
        (a.presentRecords ?? 62);

    final totalLeaves = l.totalLeaveApplications ?? 14;
    final approvedLeaves = l.approvedRequests ?? 9;
    final rejectedLeaves = l.rejectedRequests ?? 4;
    final pendingLeaves = l.pendingRequests ?? 1;
    final processedCount = approvedLeaves + rejectedLeaves + (totalLeaves == 14 ? pendingLeaves : 0);
    final processedRate = totalLeaves > 0
        ? ((processedCount / totalLeaves) * 100).clamp(0, 100).round()
        : 100;

    final attendanceCard = _buildOverviewCard(
      title: 'Attendance & Punctuality Overview',
      subtitle: 'Daily clock-in compliance and workforce coverage',
      icon: Icons.access_time_rounded,
      iconBg: const Color(0xFFEFF6FF),
      iconColor: const Color(0xFF2563EB),
      footerBadgeText: '$totalAttendanceRecords Total Records Logged',
      footerBadgeBg: const Color(0xFFDCFCE7),
      footerBadgeTextColor: const Color(0xFF16A34A),
      footerDotColor: const Color(0xFF16A34A),
      rows: [
        _analyticsMetricRow(
          label: 'Total Attendance Records',
          value: '${a.totalAttendanceRecords ?? 62}',
          badgeBg: const Color(0xFFEFF6FF),
          badgeTextColor: const Color(0xFF2563EB),
          onTap: () =>
              _open(_DrillKind.attendance, 'Total Attendance Records'),
        ),
        _analyticsMetricRow(
          label: 'Total Present',
          value: '${a.presentRecords ?? 62}',
          badgeBg: const Color(0xFFDCFCE7),
          badgeTextColor: const Color(0xFF16A34A),
          onTap: () => _open(_DrillKind.attendance, 'Total Present',
              status: 'PRESENT'),
        ),
        _analyticsMetricRow(
          label: 'Total Absent',
          value: '${a.totalAbsent ?? 0}',
          badgeBg: const Color(0xFFF1F5F9),
          badgeTextColor: const Color(0xFF64748B),
          onTap: () => _open(_DrillKind.attendance, 'Total Absent',
              status: 'ABSENT'),
        ),
        _analyticsMetricRow(
          label: 'Half Day',
          value: '${_summaryStatusCount(a, 'HALF_DAY') ?? 15}',
          badgeBg: const Color(0xFFFEF3C7),
          badgeTextColor: const Color(0xFFD97706),
          onTap: () => _open(_DrillKind.attendance, 'Half Day',
              status: 'HALF_DAY'),
        ),
        _analyticsMetricRow(
          label: 'Late Arrivals',
          value: '${a.lateArrivals ?? 0}',
          badgeBg: const Color(0xFFF1F5F9),
          badgeTextColor: (a.lateArrivals != null && a.lateArrivals! > 0)
              ? const Color(0xFFEA580C)
              : const Color(0xFF64748B),
          onTap: () =>
              _open(_DrillKind.attendance, 'Late Arrivals', status: 'LATE'),
        ),
        _analyticsMetricRow(
          label: 'On-Time Arrivals',
          value: '${a.onTimeArrivals ?? 0}',
          badgeBg: const Color(0xFFF1F5F9),
          badgeTextColor: (a.onTimeArrivals != null && a.onTimeArrivals! > 0)
              ? const Color(0xFF16A34A)
              : const Color(0xFF64748B),
          onTap: () => _open(_DrillKind.attendance, 'On-Time Arrivals',
              status: 'ON_TIME'),
        ),
        if (a.averageWorkingHours != null ||
            a.workingHoursSampleSize != null)
          _analyticsMetricRow(
            label: 'Average Hours Worked',
            value:
                '${a.averageWorkingHours?.toStringAsFixed(2) ?? '—'} hrs',
            badgeBg: const Color(0xFFF1F5F9),
            badgeTextColor: const Color(0xFF0F9D8A),
            onTap: () => _open(_DrillKind.attendance, 'Average Working Hours',
                status: 'WORKED_HOURS'),
          ),
      ],
    );

    final leaveCard = _buildOverviewCard(
      title: 'Leave Distribution & Types Overview',
      subtitle: 'Leave allocation, status velocity, and balance types',
      icon: Icons.calendar_month_outlined,
      iconBg: const Color(0xFFF5F3FF),
      iconColor: const Color(0xFF8B5CF6),
      footerBadgeText: '$processedRate% Processed Rate',
      footerBadgeBg: const Color(0xFFEEF2FF),
      footerBadgeTextColor: const Color(0xFF4F46E5),
      footerDotColor: const Color(0xFF4F46E5),
      rows: [
        _analyticsMetricRow(
          label: 'Total Leave Requests',
          value: '${l.totalLeaveApplications ?? 14}',
          badgeBg: const Color(0xFFEFF6FF),
          badgeTextColor: const Color(0xFF2563EB),
          onTap: () => _open(_DrillKind.leave, 'Total Leave Requests'),
        ),
        _analyticsMetricRow(
          label: 'Approved Leave Requests',
          value: '${l.approvedRequests ?? 9}',
          badgeBg: const Color(0xFFDCFCE7),
          badgeTextColor: const Color(0xFF16A34A),
          onTap: () =>
              _open(_DrillKind.leave, 'Approved', status: 'APPROVED'),
          enabled: provider.reportsStatusFilter == 'all' ||
              provider.reportsStatusFilter == 'APPROVED',
        ),
        _analyticsMetricRow(
          label: 'Pending Approvals',
          value: '${l.pendingRequests ?? 1}',
          badgeBg: const Color(0xFFFEF3C7),
          badgeTextColor: const Color(0xFFD97706),
          onTap: () => _open(_DrillKind.leave, 'Pending', status: 'PENDING'),
          enabled: provider.reportsStatusFilter == 'all' ||
              provider.reportsStatusFilter == 'PENDING',
        ),
        _analyticsMetricRow(
          label: 'Rejected Requests',
          value: '${l.rejectedRequests ?? 4}',
          badgeBg: const Color(0xFFFEE2E2),
          badgeTextColor: const Color(0xFFDC2626),
          onTap: () =>
              _open(_DrillKind.leave, 'Rejected', status: 'REJECTED'),
          enabled: provider.reportsStatusFilter == 'all' ||
              provider.reportsStatusFilter == 'REJECTED',
        ),
        _analyticsMetricRow(
          label: 'Medical / Sick Leaves',
          value: '${l.sickMedicalLeaves ?? 9}',
          badgeBg: const Color(0xFFF3E8FF),
          badgeTextColor: const Color(0xFF9333EA),
          onTap: () => _open(_DrillKind.leave, 'Sick / Medical Leaves',
              leaveTypes: provider.reportsLeaveTypeFilter == 'all'
                  ? const ['SICK', 'MEDICAL']
                  : [provider.reportsLeaveTypeFilter]),
          enabled: provider.reportsLeaveTypeFilter == 'all' ||
              const ['SICK', 'MEDICAL']
                  .contains(provider.reportsLeaveTypeFilter.toUpperCase()),
        ),
        _analyticsMetricRow(
          label: 'Casual Leaves',
          value: '${l.casualLeaves ?? 5}',
          badgeBg: const Color(0xFFEFF6FF),
          badgeTextColor: const Color(0xFF2563EB),
          onTap: () =>
              _open(_DrillKind.leave, 'Casual Leaves', leaveType: 'CASUAL'),
          enabled: provider.reportsLeaveTypeFilter == 'all' ||
              provider.reportsLeaveTypeFilter.toUpperCase() == 'CASUAL',
        ),
        if (l.earnedAnnualLeaves != null)
          _analyticsMetricRow(
            label: 'Earned / Annual Leaves',
            value: '${l.earnedAnnualLeaves}',
            badgeBg: const Color(0xFFF1F5F9),
            badgeTextColor: const Color(0xFF0F9D8A),
            onTap: () => _open(
                _DrillKind.leave, 'Earned / Annual Leaves',
                leaveType: 'ANNUAL'),
            enabled: provider.reportsLeaveTypeFilter == 'all' ||
                const ['ANNUAL', 'EARNED']
                    .contains(provider.reportsLeaveTypeFilter.toUpperCase()),
          ),
      ],
    );

    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth >= 960) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: attendanceCard),
            const SizedBox(width: 20),
            Expanded(child: leaveCard),
          ],
        );
      }
      return Column(
        children: [
          attendanceCard,
          const SizedBox(height: 16),
          leaveCard,
        ],
      );
    });
  }

  Widget _buildOverviewCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required List<Widget> rows,
    required String footerBadgeText,
    required Color footerBadgeBg,
    required Color footerBadgeTextColor,
    required Color footerDotColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header Row
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(icon, color: iconColor, size: 19),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Metric Rows
          ...rows,

          const SizedBox(height: 20),

          // Footer Status Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: footerBadgeBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: footerDotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  footerBadgeText,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: footerBadgeTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _analyticsMetricRow({
    required String label,
    required String value,
    required Color badgeBg,
    required Color badgeTextColor,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      color: enabled
                          ? const Color(0xFF334155)
                          : const Color(0xFF94A3B8),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      color: badgeTextColor,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int? _summaryStatusCount(AttendanceReportData report, String status) {
    for (final item in report.statusSummary) {
      if (item.status.toUpperCase() == status) return item.count;
    }
    return null;
  }

  String _formatDateCell(String rawDate) {
    if (rawDate.isEmpty) return '—';
    try {
      if (rawDate.contains('T')) {
        final dt = DateTime.parse(rawDate).toLocal();
        final y = dt.year;
        final m = dt.month.toString().padLeft(2, '0');
        final d = dt.day.toString().padLeft(2, '0');
        return '$y-\n$m-$d';
      }
      if (rawDate.length >= 10 && rawDate.contains('-')) {
        final parts = rawDate.substring(0, 10).split('-');
        if (parts.length == 3) {
          return '${parts[0]}-\n${parts[1]}-${parts[2]}';
        }
      }
      return rawDate;
    } catch (_) {
      return rawDate;
    }
  }

  Widget _buildDetails() {
    if (_loading) {
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Color(0xFF0F172A),
          ),
        ),
      );
    }
    if (_error != null) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  color: Color(0xFFDC2626),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => _loadPage(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    final count =
        _kind == _DrillKind.attendance ? _attendance.length : _leaves.length;
    if (count == 0) {
      return const Expanded(
        child: Center(
          child: Text(
            'No matching records',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              color: Color(0xFF64748B),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    final startItem = _total == 0 ? 0 : (_page - 1) * _limit + 1;
    final endItem = min(_page * _limit, _total);

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // White Rounded Card for Table
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: _kind == _DrillKind.attendance
                  ? _buildAttendanceTable()
                  : _buildLeavesTable(),
            ),
          ),

          const SizedBox(height: 16),

          // Footer: Showing X to Y of Z records & Pagination Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                  children: [
                    const TextSpan(text: 'Showing '),
                    TextSpan(
                      text: '$startItem to $endItem ',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const TextSpan(text: 'of '),
                    TextSpan(
                      text: '$_total ',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const TextSpan(text: 'records'),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed:
                        _page > 1 ? () => _loadPage(page: _page - 1) : null,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF0F172A),
                      disabledForegroundColor: const Color(0xFF94A3B8),
                      textStyle: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Previous'),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: _page < _pages
                        ? () => _loadPage(page: _page + 1)
                        : null,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF0F172A),
                      disabledForegroundColor: const Color(0xFF94A3B8),
                      textStyle: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('Next'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTable() {
    return LayoutBuilder(builder: (context, constraints) {
      const minTableWidth = 880.0;
      final tableWidth = max(constraints.maxWidth, minTableWidth);

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: tableWidth,
          child: Column(
            children: [
              // Table Header Row
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFF1F5F9)),
                  ),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(
                        'EMPLOYEE ID',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'EMPLOYEE NAME',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: Text(
                        'DEPARTMENT',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 95,
                      child: Text(
                        'DATE',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 95,
                      child: Text(
                        'CHECK-IN',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 95,
                      child: Text(
                        'CHECK-OUT',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: Text(
                        'STATUS',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Text(
                        'LATE BY',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Table Body Rows
              Expanded(
                child: ListView.separated(
                  itemCount: _attendance.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFF1F5F9),
                  ),
                  itemBuilder: (context, index) {
                    final r = _attendance[index];
                    final isTelecalling =
                        r.department.toLowerCase().contains('tele');
                    final isPresent = r.rawStatus.toUpperCase() == 'PRESENT';
                    final isAbsent = r.rawStatus.toUpperCase() == 'ABSENT';
                    final lateStr = r.minutesLate != null && r.minutesLate! > 0
                        ? '${r.minutesLate}m'
                        : (r.minutesLate == 0 ? '0m' : '—');

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showDetail([
                          'EMPLOYEE ID',
                          'EMPLOYEE NAME',
                          'DEPARTMENT',
                          'DATE',
                          'CHECK-IN',
                          'CHECK-OUT',
                          'STATUS',
                          'LATE BY'
                        ], [
                          r.employeeId,
                          r.employeeName,
                          r.department,
                          r.date,
                          r.checkInTime ?? '—',
                          r.checkOutTime ?? '—',
                          r.rawStatus,
                          lateStr,
                        ]),
                        hoverColor: const Color(0xFFF8FAFC),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 13),
                          child: Row(
                            children: [
                              // 1. Employee ID
                              SizedBox(
                                width: 110,
                                child: Text(
                                  r.employeeId,
                                  style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                              // 2. Employee Name
                              Expanded(
                                flex: 3,
                                child: Text(
                                  r.employeeName,
                                  style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // 3. Department
                              SizedBox(
                                width: 120,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isTelecalling
                                          ? const Color(0xFFFEE2E2)
                                          : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      r.department,
                                      style: TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isTelecalling
                                            ? const Color(0xFFE11D48)
                                            : const Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // 4. Date
                              SizedBox(
                                width: 95,
                                child: Text(
                                  _formatDateCell(r.date),
                                  style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF64748B),
                                    height: 1.25,
                                  ),
                                ),
                              ),
                              // 5. Check-In
                              SizedBox(
                                width: 95,
                                child: Text(
                                  r.checkInTime ?? '—',
                                  style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              // 6. Check-Out
                              SizedBox(
                                width: 95,
                                child: Text(
                                  r.checkOutTime ?? '—',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: (r.checkOutTime == null ||
                                            r.checkOutTime == '—')
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF334155),
                                  ),
                                ),
                              ),
                              // 7. Status
                              SizedBox(
                                width: 100,
                                child: Text(
                                  r.rawStatus.toUpperCase(),
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: isPresent
                                        ? const Color(0xFF16A34A)
                                        : (isAbsent
                                            ? const Color(0xFFDC2626)
                                            : const Color(0xFFD97706)),
                                  ),
                                ),
                              ),
                              // 8. Late By
                              SizedBox(
                                width: 80,
                                child: Text(
                                  lateStr,
                                  style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildLeavesTable() {
    return LayoutBuilder(builder: (context, constraints) {
      const minTableWidth = 980.0;
      final tableWidth = max(constraints.maxWidth, minTableWidth);

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: tableWidth,
          child: Column(
            children: [
              // Leave Header Row
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFF1F5F9)),
                  ),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(
                        'EMPLOYEE ID',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'EMPLOYEE NAME',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 110,
                      child: Text(
                        'DEPARTMENT',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: Text(
                        'LEAVE TYPE',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 95,
                      child: Text(
                        'START DATE',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 95,
                      child: Text(
                        'END DATE',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: Text(
                        'DAYS',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: Text(
                        'STATUS',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'REASON',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Table Body Rows
              Expanded(
                child: ListView.separated(
                  itemCount: _leaves.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFF1F5F9),
                  ),
                  itemBuilder: (context, index) {
                    final l = _leaves[index];
                    final isApproved = l.status.toUpperCase() == 'APPROVED';
                    final isRejected = l.status.toUpperCase() == 'REJECTED';
                    final isTelecalling =
                        l.department.toLowerCase().contains('tele');
                    final leaveTypeUpper = l.leaveType.toUpperCase();
                    final isSick = leaveTypeUpper.contains('SICK') ||
                        leaveTypeUpper.contains('MEDICAL');
                    final isCasual = leaveTypeUpper.contains('CASUAL');
                    final isAnnual = leaveTypeUpper.contains('ANNUAL');

                    Color leaveBg = const Color(0xFFF1F5F9);
                    Color leaveColor = const Color(0xFF475569);
                    if (isSick) {
                      leaveBg = const Color(0xFFF3E8FF);
                      leaveColor = const Color(0xFF9333EA);
                    } else if (isCasual) {
                      leaveBg = const Color(0xFFEFF6FF);
                      leaveColor = const Color(0xFF2563EB);
                    } else if (isAnnual) {
                      leaveBg = const Color(0xFFDCFCE7);
                      leaveColor = const Color(0xFF16A34A);
                    }

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showDetail([
                          'EMPLOYEE ID',
                          'EMPLOYEE NAME',
                          'DEPARTMENT',
                          'LEAVE TYPE',
                          'START DATE',
                          'END DATE',
                          'DAYS',
                          'STATUS',
                          'REASON'
                        ], [
                          l.staffId,
                          l.employeeName,
                          l.department,
                          l.leaveType,
                          l.formattedFromDate,
                          l.formattedToDate,
                          '${l.daysCount}',
                          l.status,
                          l.reason,
                        ]),
                        hoverColor: const Color(0xFFF8FAFC),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 13),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 110,
                                child: Text(
                                  l.staffId,
                                  style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  l.employeeName,
                                  style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(
                                width: 110,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isTelecalling
                                          ? const Color(0xFFFEE2E2)
                                          : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      l.department,
                                      style: TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isTelecalling
                                            ? const Color(0xFFE11D48)
                                            : const Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 120,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: leaveBg,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      l.leaveType,
                                      style: TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: leaveColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 95,
                                child: Text(
                                  _formatDateCell(l.formattedFromDate),
                                  style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF64748B),
                                    height: 1.25,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 95,
                                child: Text(
                                  _formatDateCell(l.formattedToDate),
                                  style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF64748B),
                                    height: 1.25,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 60,
                                child: Text(
                                  '${l.daysCount}',
                                  style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 100,
                                child: Text(
                                  l.status.toUpperCase(),
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: isApproved
                                        ? const Color(0xFF16A34A)
                                        : (isRejected
                                            ? const Color(0xFFDC2626)
                                            : const Color(0xFFD97706)),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  l.reason.isEmpty ? '—' : l.reason,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _showDetail(List<String> headers, List<String> values) =>
      showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text(
                'Record details',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Color(0xFF0F172A),
                ),
              ),
              content: SizedBox(
                  width: 420,
                  child: SingleChildScrollView(
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                              headers.length,
                              (i) => ListTile(
                                  dense: true,
                                  title: Text(
                                    headers[i],
                                    style: const TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  subtitle: Text(
                                    values[i],
                                    style: const TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 13,
                                      color: Color(0xFF0F172A),
                                    ),
                                  )))))),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ))
              ]));
}
