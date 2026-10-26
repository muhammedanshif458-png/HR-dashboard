import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/staff.dart';
import '../models/hr_models.dart';
import '../models/hr_document.dart';
import '../models/birthday_item.dart';
import '../models/department.dart';
import '../core/department_helper.dart';
import '../services/api_service.dart';

String _attendanceDateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

DateTime _kolkataToday() =>
    DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));

class DashboardMetrics {
  final int presentToday;
  final int lateCheckIns;
  final int openTasks;
  final int onLeaveToday;
  final int resignedLast30Days;
  final int totalStaff;
  final int activeStaff;
  final int pendingLeaves;
  final int notCheckedIn;

  DashboardMetrics({
    required this.presentToday,
    required this.lateCheckIns,
    required this.openTasks,
    required this.onLeaveToday,
    required this.resignedLast30Days,
    this.totalStaff = 0,
    this.activeStaff = 0,
    this.pendingLeaves = 0,
    this.notCheckedIn = 0,
  });
}

class DownloadedEmployeeDocument {
  final Uint8List bytes;
  final String contentType;
  const DownloadedEmployeeDocument(this.bytes, this.contentType);
}

class HRProvider extends ChangeNotifier {
  Staff? _currentUser;
  String _currentScreen = 'login';
  String? _selectedStaffId;

  Staff? get currentUser => _currentUser;
  String get currentScreen => _currentScreen;
  String? get selectedStaffId => _selectedStaffId;
  set selectedStaffId(String? id) {
    _selectedStaffId = id;
    notifyListeners();
  }

  /// Role identification helpers
  bool get isSuperAdmin =>
      _currentUser?.role == 'Super Admin' || ApiService.isSuperAdminRole;

  bool get isHRAdmin =>
      isSuperAdmin ||
      _currentUser?.role == 'HR Manager' ||
      _currentUser?.role == 'Administrator' ||
      ApiService.isHrAdminRole;

  bool get isStaffUser =>
      !isHRAdmin &&
      (_currentUser?.role.toLowerCase() == 'staff' || ApiService.isStaffRole);

  void setCurrentUserForTesting(Staff? user) {
    _currentUser = user;
    notifyListeners();
  }

  // Master State
  List<Staff> staffList = [];
  List<Attendance> attendanceList = [];
  List<Task> tasksList = [];
  List<LeaveRequest> leaveRequests = [];
  List<ResignationRequest> resignationRequests = [];
  List<DailyUpdate> dailyUpdatesList = [];
  List<DailyUpdate> apiDailyUpdatesList = [];
  bool isDailyUpdatesLoading = false;
  String? dailyUpdatesError;
  bool hasLoadedApiDailyUpdates = false;
  int dailyUpdatesPage = 1;
  int dailyUpdatesLimit = 20;
  int dailyUpdatesTotal = 0;
  int dailyUpdatesTotalPages = 1;
  String dailyUpdatesDeptFilter = 'all';
  String dailyUpdatesSearchQuery = '';
  int _dailyUpdatesRequestVersion = 0;
  List<DailyUpdate> employeeDailyUpdates = [];
  String? employeeDailyUpdatesStaffId;
  bool isEmployeeDailyUpdatesLoading = false;
  String? employeeDailyUpdatesError;
  int employeeDailyUpdatesPage = 1;
  int employeeDailyUpdatesTotal = 0;
  int employeeDailyUpdatesTotalPages = 1;
  int _employeeDailyUpdatesRequestVersion = 0;
  List<ChatThread> chatThreads = [];
  List<DepartmentChatThread> departmentChatThreads = [];
  List<HRDocumentItem> documentsList = [];
  bool isDocumentsLoading = false;
  String? employeeDocumentsError;
  int _employeeDocumentsRequestVersion = 0;
  bool isEmployeeDetailLoading = false;
  String? employeeDetailError;
  int _employeeDetailRequestVersion = 0;

  // Chat state
  String? selectedChatParticipantId;
  String? activeDepartmentChatKey;

  // Dashboard Filters
  String dashboardFilter = 'all';
  String searchQuery = '';

  // Leave Management Filters
  String leaveSearchQuery = '';
  String leaveStatusFilter = 'all'; // all, Pending, Approved, Rejected
  String leaveDeptFilter = 'all'; // all, Tech, Telecalling
  String leaveTypeFilter = 'all'; // all, Casual, Sick, Earned, Medical
  DateTime? leaveStartDate;
  DateTime? leaveEndDate;

  // Leave Pagination & Async State (Screen 7 API Integration)
  bool isLeavesLoading = false;
  String? leavesError;
  int leavesPage = 1;
  int leavesLimit = 20;
  int leavesTotal = 0;
  int leavesTotalPages = 1;
  bool hasLoadedApiLeaves = false;
  List<LeaveRequest> apiLeaveRecords = [];
  int _leavesRequestVersion = 0;

  // Stable company-wide leave metric counts -- never mutated by table status filters.
  // These are maintained by _fetchLeaveMetrics() and seeded from the dashboard API.
  int companyPendingLeavesCount = 0;
  int companyApprovedLeavesCount = 0;
  int companyRejectedLeavesCount = 0;
  int companyOnLeaveTodayCount = 0;
  bool _hasLoadedLeaveMetrics = false;
  bool get hasLoadedLeaveMetrics => _hasLoadedLeaveMetrics;
  int _leaveMetricsRequestVersion = 0;

  // On Leave Today filter toggle (used by the Leave Management table).
  bool leaveFilterOnLeaveToday = false;

  // Attendance Management Filters
  String attendanceSearchQuery = '';
  String attendanceDeptFilter = 'all'; // all, Tech, Telecalling
  String attendanceStatusFilter =
      'all'; // all, Present, Late, Absent, On Leave, Not Checked In
  String attendanceWorkModeFilter = 'all'; // all, Office, WFH
  DateTime? attendanceSelectedDate;
  DateTime? attendanceDateRangeStart;
  DateTime? attendanceDateRangeEnd;
  String attendanceTab = 'today'; // today vs history

  // Attendance Pagination & Async State (Screen 6 API Integration)
  bool isAttendanceLoading = false;
  String? attendanceError;
  int attendancePage = 1;
  int attendanceLimit = 20;
  int attendanceTotal = 0;
  int attendanceTotalPages = 1;
  bool hasLoadedApiAttendance = false;
  List<Attendance> apiAttendanceRecords = [];
  int _attendanceRequestVersion = 0;
  Timer? _attendanceSearchTimer;
  bool isLateArrivalsLoading = false;
  String? lateArrivalsError;
  int? _lateArrivalsSummaryCount;
  int? _presentTodaySummaryCount;
  int _lateArrivalsRequestVersion = 0;

  int? get lateArrivalsSummaryCount => _lateArrivalsSummaryCount;

  int? get attendanceOnLeaveSummaryCount => _dashboardCount('onLeaveToday');
  int? get attendanceWfhSummaryCount => _dashboardCount('todayWfh');

  String get attendanceMetricDateKey => _attendanceDateKey(
        attendanceSelectedDate ?? _kolkataToday(),
      );

  DateTime get attendanceTodayDate => _kolkataToday();

  String get attendanceWfhDisplayValue {
    final count = attendanceWfhSummaryCount;
    if (count != null) return count.toString();
    return isLateArrivalsLoading ? '…' : '—';
  }

  String get attendanceOnLeaveDisplayValue {
    final count = attendanceOnLeaveSummaryCount;
    if (count != null) return count.toString();
    return isLateArrivalsLoading ? '…' : '—';
  }

  String get lateArrivalsDisplayValue {
    final count = _lateArrivalsSummaryCount ?? _dashboardCount('lateArrivals');
    if (count != null) return count.toString();
    if (isLateArrivalsLoading) return '…';
    return '—';
  }

  String get presentTodayDisplayValue {
    final count = _presentTodaySummaryCount ?? _dashboardCount('todayPresent');
    if (count != null) return count.toString();
    if (isLateArrivalsLoading) return '…';
    return '—';
  }

  int? _dashboardCount(String key) {
    final value = apiDashboardMetrics?[key];
    return value is num ? value.toInt() : null;
  }

  // Payroll State (Screen 8 API Integration)
  int payrollYear = DateTime.now().year;
  int payrollMonth = DateTime.now().month;
  String payrollDepartment = 'all'; // all, Tech, Telecalling
  String payrollSearchQuery = '';

  bool isPayrollLoading = false;
  String? payrollError;
  int payrollPage = 1;
  int payrollLimit = 50;
  int payrollTotal = 0;
  int payrollTotalPages = 1;
  bool hasLoadedApiPayroll = false;
  List<EmployeePayrollRecord> apiPayrollRecords = [];
  PayrollSummary? apiPayrollSummary;
  int _payrollRequestVersion = 0;

  // Task Management State (Screen 9 API Integration)
  String taskStatusFilter = 'all'; // all, pending, in-progress, done, cancelled
  String taskDeptFilter = 'all'; // all, Tech, Telecalling
  String taskSearchQuery = '';

  bool isTasksLoading = false;
  String? tasksError;
  int tasksPage = 1;
  int tasksLimit = 20;
  int tasksTotal = 0;
  int tasksTotalPages = 1;
  bool hasLoadedApiTasks = false;
  List<Task> apiTasksList = [];
  int _tasksRequestVersion = 0;

  // Department Chat State (Screen 11 API Integration)
  bool isDepartmentChatLoading = false;
  String? departmentChatError;
  bool hasLoadedApiDepartmentChat = false;
  int _departmentChatRequestVersion = 0;

  // Reports & Analytics State (Screen 12 Integration)
  bool isReportsLoading = false;
  String? reportsError;
  bool hasLoadedApiReports = false;
  AttendanceReportData? apiAttendanceReport;
  LeaveReportData? apiLeaveReport;
  String reportsDepartmentFilter = 'all';
  DateTime? reportsStartDate;
  DateTime? reportsEndDate;
  int _reportsRequestVersion = 0;

  // Employee Directory Filters
  String employeeSearchQuery = '';
  String employeeDeptFilter = 'all';
  String employeeStatusFilter = 'all';
  List<Staff> employeeDirectory = [];
  int employeePage = 1;
  int employeeLimit = 20;
  int employeeTotal = 0;
  int employeeTotalPages = 0;
  bool hasLoadedApiEmployees = false;
  int _employeeRequestVersion = 0;
  Timer? _employeeSearchTimer;

  // Async State
  bool isApiStaffLoading = false;
  String apiStaffError = '';
  bool isProcessingAction = false;
  bool isLoginLoading = false;
  String loginError = '';

  // Dashboard API State (GET /api/hr/dashboard)
  Map<String, dynamic>? apiDashboardMetrics;
  bool isDashboardLoading = false;
  String? dashboardError;
  bool hasLoadedApiDashboard = false;

  // Birthday State
  List<BirthdayItem> todayBirthdays = [];
  List<BirthdayItem> upcomingBirthdays = [];
  bool isBirthdaysLoading = false;

  // Department State (Screen 3 API Integration)
  List<Department> departments = [];
  bool isDepartmentsLoading = false;
  String? departmentsError;
  Department? selectedDepartmentDetail;
  bool isDepartmentDetailLoading = false;
  String? departmentDetailError;

  static bool enableTestFixtures = false;
  bool _isTestModeSeeded = false;

  HRProvider({bool? seedTestData}) {
    if (seedTestData == true || (seedTestData == null && enableTestFixtures)) {
      seedMockDataForTesting();
    }
  }

  @visibleForTesting
  void seedMockDataForTesting() {
    _isTestModeSeeded = true;
    _initMockData();
  }

  void _initMockData() {
    staffList = [
      Staff(
        id: 'staff_1',
        name: 'Anita Rao',
        email: 'anita@company.com',
        phoneNumber: '9876543210',
        department: 'Tech',
        role: 'HR Manager',
        joinDate: '2024-01-15',
        status: 'active',
        onLeaveToday: false,
        designation: 'Lead HR Manager',
        workMode: 'Office',
        salary: 85000.0,
        salaryCurrency: 'INR',
        salaryEffectiveDate: '2024-01-15',
        paidLeaveAllowance: 1,
        salaryHistory: [
          SalaryHistoryItem(
            amount: 85000.0,
            currency: 'INR',
            effectiveDate: '2024-01-15',
            changedBy: 'System Initializer',
            reason: 'Joining Base Salary',
            timestamp: '2024-01-15 09:00:00',
          )
        ],
        dateOfBirth:
            '1990-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
      ),
      Staff(
        id: 'staff_2',
        name: 'Arjun Desai',
        email: 'arjun@company.com',
        phoneNumber: '9876543211',
        department: 'Tech',
        role: 'Staff',
        joinDate: '2024-02-01',
        status: 'active',
        onLeaveToday: false,
        designation: 'Senior Frontend Engineer',
        workMode: 'Office',
        salary: 75000.0,
        salaryCurrency: 'INR',
        salaryEffectiveDate: '2024-02-01',
        paidLeaveAllowance: 1,
        salaryHistory: [
          SalaryHistoryItem(
            amount: 75000.0,
            currency: 'INR',
            effectiveDate: '2024-02-01',
            changedBy: 'System Initializer',
            reason: 'Joining Base Salary',
            timestamp: '2024-02-01 09:00:00',
          )
        ],
        dateOfBirth: '1988-10-19',
      ),
      Staff(
        id: 'staff_3',
        name: 'Neha Sharma',
        email: 'neha@company.com',
        phoneNumber: '9876543212',
        department: 'Telecalling',
        role: 'Staff',
        joinDate: '2024-03-10',
        status: 'active',
        onLeaveToday: false,
        designation: 'Telecalling Executive',
        workMode: 'Office',
        salary: 32000.0,
        salaryCurrency: 'INR',
        salaryEffectiveDate: '2024-03-10',
        paidLeaveAllowance: 1,
        salaryHistory: [
          SalaryHistoryItem(
            amount: 32000.0,
            currency: 'INR',
            effectiveDate: '2024-03-10',
            changedBy: 'System Initializer',
            reason: 'Joining Base Salary',
            timestamp: '2024-03-10 09:00:00',
          )
        ],
        dateOfBirth: '1992-10-29',
      ),
      Staff(
        id: 'staff_4',
        name: 'Vikram Singh',
        email: 'vikram@company.com',
        phoneNumber: '9876543213',
        department: 'Tech',
        role: 'Staff',
        joinDate: '2024-04-05',
        status: 'resigned',
        onLeaveToday: false,
        designation: 'Backend Developer',
        workMode: 'Office',
        salary: 68000.0,
        salaryCurrency: 'INR',
        salaryEffectiveDate: '2024-04-05',
        paidLeaveAllowance: 1,
        salaryHistory: [
          SalaryHistoryItem(
            amount: 68000.0,
            currency: 'INR',
            effectiveDate: '2024-04-05',
            changedBy: 'System Initializer',
            reason: 'Joining Base Salary',
            timestamp: '2024-04-05 09:00:00',
          )
        ],
      ),
      Staff(
        id: 'staff_5',
        name: 'Rahul Menon',
        email: 'rahul@company.com',
        phoneNumber: '9876543214',
        department: 'Telecalling',
        role: 'Staff',
        joinDate: '2024-05-20',
        status: 'active',
        onLeaveToday: true,
        designation: 'Support Specialist',
        workMode: 'WFH',
        salary: 35000.0,
        salaryCurrency: 'INR',
        salaryEffectiveDate: '2024-05-20',
        paidLeaveAllowance: 1,
        salaryHistory: [
          SalaryHistoryItem(
            amount: 35000.0,
            currency: 'INR',
            effectiveDate: '2024-05-20',
            changedBy: 'System Initializer',
            reason: 'Joining Base Salary',
            timestamp: '2024-05-20 09:00:00',
          )
        ],
      ),
      Staff(
        id: 'staff_6',
        name: 'Priya Patel',
        email: 'priya@company.com',
        phoneNumber: '9876543215',
        department: 'Tech',
        role: 'Staff',
        joinDate: '2024-06-01',
        status: 'active',
        onLeaveToday: false,
        designation: 'UI/UX Designer',
        workMode: 'Office',
        salary: 60000.0,
        salaryCurrency: 'INR',
        salaryEffectiveDate: '2024-06-01',
        paidLeaveAllowance: 1,
        salaryHistory: [
          SalaryHistoryItem(
            amount: 60000.0,
            currency: 'INR',
            effectiveDate: '2024-06-01',
            changedBy: 'System Initializer',
            reason: 'Joining Base Salary',
            timestamp: '2024-06-01 09:00:00',
          )
        ],
      ),
    ];

    attendanceList = [
      Attendance(
        id: 'att_1',
        staffId: 'staff_1',
        employeeName: 'Anita Rao',
        department: 'Tech',
        date: '2026-10-12',
        checkInTime: '08:55 AM',
        checkOutTime: null,
        workedDuration: '4h 10m',
        breakDuration: '0h 30m',
        isLate: false,
        status: 'Present',
        workMode: 'Office',
        location: 'LY HQ - 4th Floor',
        remarks: 'Punched at front desk',
        workingHours: 4.17,
      ),
      Attendance(
        id: 'att_2',
        staffId: 'staff_2',
        employeeName: 'Arjun Desai',
        department: 'Tech',
        date: '2026-10-12',
        checkInTime: '09:05 AM',
        checkOutTime: '05:30 PM',
        workedDuration: '8h 25m',
        breakDuration: '1h 00m',
        isLate: false,
        status: 'Checked Out',
        workMode: 'Office',
        location: 'LY HQ - Desk 12',
        remarks: 'Full day completed',
        workingHours: 8.42,
      ),
      Attendance(
        id: 'att_3',
        staffId: 'staff_3',
        employeeName: 'Neha Sharma',
        department: 'Telecalling',
        date: '2026-10-12',
        checkInTime: '10:15 AM',
        checkOutTime: null,
        workedDuration: '3h 45m',
        breakDuration: '0h 15m',
        isLate: true,
        status: 'Late',
        workMode: 'Office',
        location: 'Telecalling Wing B',
        remarks: 'Traffic delay reported',
        workingHours: 3.75,
      ),
      Attendance(
        id: 'att_4',
        staffId: 'staff_6',
        employeeName: 'Priya Patel',
        department: 'Tech',
        date: '2026-10-12',
        checkInTime: '09:12 AM',
        checkOutTime: null,
        workedDuration: '4h 00m',
        breakDuration: '0h 45m',
        isLate: false,
        status: 'Present',
        workMode: 'WFH',
        location: 'Remote - Bangalore',
        remarks: 'Approved WFH sprint',
        workingHours: 4.0,
      ),
      Attendance(
        id: 'att_5',
        staffId: 'staff_2',
        employeeName: 'Arjun Desai',
        department: 'Tech',
        date: '2026-10-11',
        checkInTime: '09:00 AM',
        checkOutTime: '06:00 PM',
        workedDuration: '9h 00m',
        breakDuration: '1h 00m',
        isLate: false,
        status: 'Checked Out',
        workMode: 'Office',
        location: 'LY HQ - Desk 12',
        remarks: 'Normal sprint day',
        workingHours: 9.0,
      ),
      Attendance(
        id: 'att_6',
        staffId: 'staff_3',
        employeeName: 'Neha Sharma',
        department: 'Telecalling',
        date: '2026-10-11',
        checkInTime: '09:30 AM',
        checkOutTime: '05:30 PM',
        workedDuration: '8h 00m',
        breakDuration: '0h 45m',
        isLate: false,
        status: 'Checked Out',
        workMode: 'Office',
        location: 'Telecalling Wing B',
        remarks: 'Called 65 accounts',
        workingHours: 8.0,
      ),
    ];

    tasksList = [
      Task(
        id: 'task_1',
        staffId: 'staff_2',
        department: 'Tech',
        description: 'Complete LY SOFTWARE HR Dashboard Enhancement & Testing',
        status: 'in-progress',
        date: '2026-10-12',
        dueDate: '2026-10-15',
      ),
      Task(
        id: 'task_2',
        staffId: 'staff_3',
        department: 'Telecalling',
        description: 'Follow up with 50 high-value candidate leads',
        status: 'pending',
        date: '2026-10-12',
        dueDate: '2026-10-13',
      ),
      Task(
        id: 'task_3',
        staffId: 'staff_6',
        department: 'Tech',
        description:
            'Finalize Leave Management UI & Attendance responsive tables',
        status: 'done',
        date: '2026-10-10',
        dueDate: '2026-10-12',
      ),
    ];

    leaveRequests = [
      LeaveRequest(
        id: 'leave_1',
        staffId: 'staff_5',
        employeeName: 'Rahul Menon',
        employeeEmail: 'rahul@company.com',
        department: 'Telecalling',
        leaveType: 'Medical',
        fromDate: '2026-10-12',
        toDate: '2026-10-14',
        daysCount: 3,
        reason: 'Severe viral fever and physician recommended rest.',
        status: 'Pending',
        submissionDate: '2026-10-11',
        hasMedicalProof: true,
        medicalProofFileName: 'dr_sharma_medical_certificate.jpg',
        medicalProofFileType: 'image/jpeg',
        medicalProofUrl: '/uploads/medical/leave_1_cert.jpg',
      ),
      LeaveRequest(
        id: 'leave_2',
        staffId: 'staff_2',
        employeeName: 'Arjun Desai',
        employeeEmail: 'arjun@company.com',
        department: 'Tech',
        leaveType: 'Casual',
        fromDate: '2026-10-20',
        toDate: '2026-10-21',
        daysCount: 2,
        reason: 'Family function and travel.',
        status: 'Pending',
        submissionDate: '2026-10-10',
        hasMedicalProof: false,
      ),
      LeaveRequest(
        id: 'leave_3',
        staffId: 'staff_3',
        employeeName: 'Neha Sharma',
        employeeEmail: 'neha@company.com',
        department: 'Telecalling',
        leaveType: 'Medical',
        fromDate: '2026-10-08',
        toDate: '2026-10-09',
        daysCount: 2,
        reason: 'Migraine and clinical checkup.',
        status: 'Pending',
        submissionDate: '2026-10-08',
        hasMedicalProof: false, // Document not uploaded
      ),
      LeaveRequest(
        id: 'leave_4',
        staffId: 'staff_6',
        employeeName: 'Priya Patel',
        employeeEmail: 'priya@company.com',
        department: 'Tech',
        leaveType: 'Earned',
        fromDate: '2026-10-01',
        toDate: '2026-10-03',
        daysCount: 3,
        reason: 'Annual family festival leave.',
        status: 'Approved',
        submissionDate: '2026-09-25',
        approvedBy: 'Anita Rao',
        approvedAt: '2026-09-26',
        hasMedicalProof: false,
      ),
      LeaveRequest(
        id: 'leave_5',
        staffId: 'staff_4',
        employeeName: 'Vikram Singh',
        employeeEmail: 'vikram@company.com',
        department: 'Tech',
        leaveType: 'Medical',
        fromDate: '2026-09-15',
        toDate: '2026-09-17',
        daysCount: 3,
        reason: 'Back pain physiotherapy.',
        status: 'Rejected',
        submissionDate: '2026-09-14',
        approvedBy: 'Anita Rao',
        approvedAt: '2026-09-14',
        rejectionReason:
            'Notice submitted after sprint freeze with no prior communication.',
        hasMedicalProof: true,
        medicalProofFileName: 'physio_prescription.pdf',
        medicalProofFileType: 'application/pdf',
        medicalProofUrl: '/uploads/medical/leave_5_presc.pdf',
      ),
    ];

    dailyUpdatesList = [
      DailyUpdate(
        id: 'upd_1',
        staffId: 'staff_2',
        date: '2026-10-11',
        updateText:
            'Integrated attendance and leave filters in Flutter HR Web client.',
      ),
      DailyUpdate(
        id: 'upd_2',
        staffId: 'staff_3',
        date: '2026-10-11',
        updateText: 'Completed 65 telecalling customer feedback calls.',
      ),
    ];
    _initMockChatData();
  }

  void _initMockChatData() {
    final now = DateTime.now();
    chatThreads = [
      ChatThread(
        participantId: 'staff_2',
        participantName: 'Arjun Desai',
        participantRole: 'Senior Frontend Engineer',
        participantDept: 'Tech',
        messages: [
          ChatMessage(
            id: 'msg_1',
            senderId: 'staff_2',
            receiverId: 'admin_1',
            text:
                'Hi Anita, can I take a half day tomorrow for a dental appointment?',
            timestamp: now.subtract(const Duration(hours: 3, minutes: 10)),
            isRead: true,
          ),
          ChatMessage(
            id: 'msg_2',
            senderId: 'admin_1',
            receiverId: 'staff_2',
            text:
                'Sure Arjun, please submit a leave request in the system as well.',
            timestamp: now.subtract(const Duration(hours: 2, minutes: 50)),
            isRead: true,
          ),
          ChatMessage(
            id: 'msg_3',
            senderId: 'staff_2',
            receiverId: 'admin_1',
            text: 'Done! I have submitted the request. Thank you 🙏',
            timestamp: now.subtract(const Duration(hours: 2, minutes: 30)),
            isRead: true,
          ),
          ChatMessage(
            id: 'msg_4',
            senderId: 'staff_2',
            receiverId: 'admin_1',
            text:
                'Also, the sprint review is at 4 PM today — should I prepare a demo?',
            timestamp: now.subtract(const Duration(minutes: 18)),
            isRead: false,
          ),
        ],
      ),
      ChatThread(
        participantId: 'staff_3',
        participantName: 'Neha Sharma',
        participantRole: 'Telecalling Executive',
        participantDept: 'Telecalling',
        messages: [
          ChatMessage(
            id: 'msg_5',
            senderId: 'admin_1',
            receiverId: 'staff_3',
            text:
                'Neha, you were 45 minutes late today. Please ensure timely check-in.',
            timestamp: now.subtract(const Duration(hours: 1, minutes: 20)),
            isRead: true,
          ),
          ChatMessage(
            id: 'msg_6',
            senderId: 'staff_3',
            receiverId: 'admin_1',
            text:
                "Sorry ma'am, there was a traffic jam on the highway. I will be on time tomorrow.",
            timestamp: now.subtract(const Duration(hours: 1)),
            isRead: false,
          ),
        ],
      ),
      ChatThread(
        participantId: 'staff_5',
        participantName: 'Rahul Menon',
        participantRole: 'Support Specialist',
        participantDept: 'Telecalling',
        messages: [
          ChatMessage(
            id: 'msg_7',
            senderId: 'staff_5',
            receiverId: 'admin_1',
            text: 'Good morning! My leave request is pending, any update?',
            timestamp: now.subtract(const Duration(hours: 4)),
            isRead: true,
          ),
          ChatMessage(
            id: 'msg_8',
            senderId: 'admin_1',
            receiverId: 'staff_5',
            text: 'Good morning Rahul! We will review it by EOD today.',
            timestamp: now.subtract(const Duration(hours: 3, minutes: 45)),
            isRead: true,
          ),
        ],
      ),
      ChatThread(
        participantId: 'staff_6',
        participantName: 'Priya Patel',
        participantRole: 'UI/UX Designer',
        participantDept: 'Tech',
        messages: [
          ChatMessage(
            id: 'msg_9',
            senderId: 'staff_6',
            receiverId: 'admin_1',
            text:
                'Hi! The new Figma designs for the HR portal are ready for review.',
            timestamp: now.subtract(const Duration(days: 1, hours: 2)),
            isRead: true,
          ),
          ChatMessage(
            id: 'msg_10',
            senderId: 'admin_1',
            receiverId: 'staff_6',
            text: 'Great work Priya! I will review them today.',
            timestamp: now.subtract(const Duration(days: 1, hours: 1)),
            isRead: true,
          ),
        ],
      ),
    ];

    departmentChatThreads = [
      DepartmentChatThread(
        departmentKey: 'tech',
        departmentName: 'Tech & Engineering',
        icon: '💻',
        memberIds: ['staff_2', 'staff_6'],
        messages: [
          ChatMessage(
            id: 'dept_tech_1',
            senderId: 'admin_1',
            senderName: 'Anita Roy (HR Manager)',
            receiverId: 'dept_tech',
            text:
                'Good morning Tech team! Please make sure your daily updates are logged before 6 PM today.',
            timestamp: now.subtract(const Duration(hours: 4, minutes: 15)),
            isRead: true,
          ),
          ChatMessage(
            id: 'dept_tech_2',
            senderId: 'staff_2',
            senderName: 'Arjun Desai',
            receiverId: 'dept_tech',
            text:
                'Noted! Working on the leave management API integration today.',
            timestamp: now.subtract(const Duration(hours: 3, minutes: 40)),
            isRead: true,
          ),
          ChatMessage(
            id: 'dept_tech_3',
            senderId: 'staff_6',
            senderName: 'Priya Patel',
            receiverId: 'dept_tech',
            text:
                'Design tokens and component updates have been pushed to Figma for the HR portal.',
            timestamp: now.subtract(const Duration(hours: 2, minutes: 10)),
            isRead: true,
          ),
          ChatMessage(
            id: 'dept_tech_4',
            senderId: 'staff_2',
            senderName: 'Arjun Desai',
            receiverId: 'dept_tech',
            text: 'All unit tests passing. Ready for deployment review.',
            timestamp: now.subtract(const Duration(minutes: 25)),
            isRead: false,
          ),
        ],
      ),
      DepartmentChatThread(
        departmentKey: 'telecalling',
        departmentName: 'Telecalling & Client Relations',
        icon: '📞',
        memberIds: ['staff_1', 'staff_3', 'staff_4', 'staff_5'],
        messages: [
          ChatMessage(
            id: 'dept_tele_1',
            senderId: 'admin_1',
            senderName: 'Anita Roy (HR Manager)',
            receiverId: 'dept_telecalling',
            text:
                'Welcome team! Today’s target is 120 client reach-outs with 30 follow-ups.',
            timestamp: now.subtract(const Duration(hours: 5)),
            isRead: true,
          ),
          ChatMessage(
            id: 'dept_tele_2',
            senderId: 'staff_1',
            senderName: 'Aarav Sharma',
            receiverId: 'dept_telecalling',
            text: 'Campaign lead batch #4 has been distributed to everyone.',
            timestamp: now.subtract(const Duration(hours: 3, minutes: 15)),
            isRead: true,
          ),
          ChatMessage(
            id: 'dept_tele_3',
            senderId: 'staff_3',
            senderName: 'Neha Sharma',
            receiverId: 'dept_telecalling',
            text:
                'First 20 calls completed. High interest in the enterprise demo.',
            timestamp: now.subtract(const Duration(hours: 1, minutes: 45)),
            isRead: false,
          ),
          ChatMessage(
            id: 'dept_tele_4',
            senderId: 'staff_5',
            senderName: 'Rahul Menon',
            receiverId: 'dept_telecalling',
            text: 'Support ticket queue is down to 2 pending items.',
            timestamp: now.subtract(const Duration(minutes: 40)),
            isRead: false,
          ),
        ],
      ),
    ];

    // Initial HR Documents for Tech and Telecalling staff
    documentsList = [
      HRDocumentItem(
        id: 'doc_init_1',
        employeeId: 'staff_1',
        title: 'Master Employment Agreement',
        category: 'Employment Agreement',
        description:
            'Signed full-time employment agreement for Lead HR Tech Ops',
        fileName: 'Anita_Rao_Employment_Agreement.pdf',
        originalName: 'Anita_Rao_Employment_Agreement.pdf',
        filePath: '/uploads/documents/Anita_Rao_Employment_Agreement.pdf',
        fileType: 'application/pdf',
        fileSize: 524288,
        issueDate: '2024-01-15',
        expiryDate: '',
        uploadedBy: 'HR Director',
        status: 'ACTIVE',
        version: 1,
        createdAt: DateTime(2024, 1, 15),
      ),
      HRDocumentItem(
        id: 'doc_init_2',
        employeeId: 'staff_1',
        title: 'B.Tech Degree Certificate',
        category: 'Educational Certificates',
        description: 'Verified Bachelor of Technology certificate',
        fileName: 'Anita_Degree_Cert.pdf',
        originalName: 'Anita_Degree_Cert.pdf',
        filePath: '/uploads/documents/Anita_Degree_Cert.pdf',
        fileType: 'application/pdf',
        fileSize: 1048576,
        issueDate: '2020-07-20',
        expiryDate: '',
        uploadedBy: 'HR Admin',
        status: 'ACTIVE',
        version: 1,
        createdAt: DateTime(2024, 1, 16),
      ),
      HRDocumentItem(
        id: 'doc_init_3',
        employeeId: 'staff_2',
        title: 'Arjun Desai Resume & Portfolio',
        category: 'Resume',
        description:
            'Updated engineering resume and frontend architectural portfolio',
        fileName: 'Arjun_Desai_Resume.pdf',
        originalName: 'Arjun_Desai_Resume.pdf',
        filePath: '/uploads/documents/Arjun_Desai_Resume.pdf',
        fileType: 'application/pdf',
        fileSize: 450560,
        issueDate: '2024-02-01',
        expiryDate: '',
        uploadedBy: 'HR Admin',
        status: 'ACTIVE',
        version: 1,
        createdAt: DateTime(2024, 2, 1),
      ),
      HRDocumentItem(
        id: 'doc_init_4',
        employeeId: 'staff_2',
        title: 'National Identity Proof (Aadhaar)',
        category: 'Identity Proof',
        description: 'Government issued identity card copy verified',
        fileName: 'Arjun_Aadhaar_ID.jpg',
        originalName: 'Arjun_Aadhaar_ID.jpg',
        filePath: '/uploads/documents/Arjun_Aadhaar_ID.jpg',
        fileType: 'image/jpeg',
        fileSize: 327680,
        issueDate: '2023-01-10',
        expiryDate: '',
        uploadedBy: 'HR Admin',
        status: 'ACTIVE',
        version: 1,
        createdAt: DateTime(2024, 2, 2),
      ),
      HRDocumentItem(
        id: 'doc_init_5',
        employeeId: 'staff_3',
        title: 'Neha Sharma Appointment Letter',
        category: 'Appointment Letter',
        description:
            'Official appointment letter for Telecalling Executive position',
        fileName: 'Neha_Sharma_Appointment_Letter.pdf',
        originalName: 'Neha_Sharma_Appointment_Letter.pdf',
        filePath: '/uploads/documents/Neha_Sharma_Appointment_Letter.pdf',
        fileType: 'application/pdf',
        fileSize: 614400,
        issueDate: '2024-03-10',
        expiryDate: '',
        uploadedBy: 'HR Operations',
        status: 'ACTIVE',
        version: 1,
        createdAt: DateTime(2024, 3, 10),
      ),
      HRDocumentItem(
        id: 'doc_init_6',
        employeeId: 'staff_3',
        title: 'National Identity Card (PAN)',
        category: 'Identity Proof',
        description: 'Verified PAN card document for tax compliance',
        fileName: 'Neha_Sharma_PAN.png',
        originalName: 'Neha_Sharma_PAN.png',
        filePath: '/uploads/documents/Neha_Sharma_PAN.png',
        fileType: 'image/png',
        fileSize: 256000,
        issueDate: '2022-05-14',
        expiryDate: '',
        uploadedBy: 'HR Admin',
        status: 'ACTIVE',
        version: 1,
        createdAt: DateTime(2024, 3, 11),
      ),
      HRDocumentItem(
        id: 'doc_init_7',
        employeeId: 'staff_5',
        title: 'Medical Fitness Certificate',
        category: 'Medical Certificate',
        description: 'Registered physician fitness certification',
        fileName: 'Rahul_Menon_Medical_Cert.pdf',
        originalName: 'Rahul_Menon_Medical_Cert.pdf',
        filePath: '/uploads/documents/Rahul_Menon_Medical_Cert.pdf',
        fileType: 'application/pdf',
        fileSize: 409600,
        issueDate: '2024-05-18',
        expiryDate: '2025-05-18',
        uploadedBy: 'HR Admin',
        status: 'ACTIVE',
        version: 1,
        createdAt: DateTime(2024, 5, 18),
      ),
    ];
    _computeLocalBirthdays();
    _initDepartments();
  }

  // --- Live API Sync ---
  Future<bool> fetchDashboardData() async {
    isApiStaffLoading = true;
    isDashboardLoading = true;
    apiStaffError = '';
    dashboardError = null;
    notifyListeners();

    bool syncSuccess = false;

    // 1. Live dashboard statistics from GET /api/hr/dashboard
    try {
      final metricsRes = await ApiService.getDashboardMetrics()
          .timeout(const Duration(seconds: 4));
      if (metricsRes['data'] is Map<String, dynamic>) {
        apiDashboardMetrics = metricsRes['data'] as Map<String, dynamic>;
        hasLoadedApiDashboard = true;
        syncSuccess = true;
      }
    } catch (e) {
      dashboardError = e.toString().replaceFirst('Exception: ', '');
      hasLoadedApiDashboard = false;
    }

    // 2. Live employee workforce from GET /api/hr/employees
    try {
      final liveEmployees =
          await ApiService.getEmployees().timeout(const Duration(seconds: 4));
      staffList = liveEmployees;
      employeeDirectory = liveEmployees;
      hasLoadedApiEmployees = true;
    } catch (_) {}

    // 3. Live attendance records from GET /api/hr/attendance
    try {
      final liveAttendance =
          await ApiService.getAttendance().timeout(const Duration(seconds: 4));
      apiAttendanceRecords = liveAttendance;
      attendanceList = liveAttendance;
      hasLoadedApiAttendance = true;
    } catch (_) {}

    // 4. Seed stable leave metrics from dashboard stats (pendingLeaves & approvedLeaves)
    if (apiDashboardMetrics != null) {
      final dm = apiDashboardMetrics!;
      if (dm['pendingLeaves'] is num) {
        companyPendingLeavesCount = (dm['pendingLeaves'] as num).toInt();
        _hasLoadedLeaveMetrics = true;
      }
      if (dm['approvedLeaves'] is num) {
        companyApprovedLeavesCount = (dm['approvedLeaves'] as num).toInt();
      }
    }
    // Fetch remaining counts (rejected, on-leave-today) in background.
    unawaited(_fetchLeaveMetrics());
    hasLoadedApiLeaves =
        false; // table loads lazily via loadLeaves() on screen visit

    // 5. Live department roster from GET /api/hr/departments
    try {
      final liveDepts =
          await ApiService.getDepartments().timeout(const Duration(seconds: 4));
      if (liveDepts.isNotEmpty) {
        departments = DepartmentHelper.deduplicateDepartments(liveDepts);
      }
    } catch (_) {}

    isApiStaffLoading = false;
    isDashboardLoading = false;
    notifyListeners();
    return syncSuccess && hasLoadedApiDashboard;
  }

  String? birthdaysError;
  bool hasLoadedApiBirthdays = false;

  Future<void> fetchBirthdays({bool? isStaff}) async {
    isBirthdaysLoading = true;
    birthdaysError = null;
    notifyListeners();

    final effectiveIsStaff = isStaff ??
        (currentUser != null &&
            currentUser!.role != 'HR Manager' &&
            currentUser!.role != 'HR');

    if (ApiService.hasToken || hasLoadedApiBirthdays) {
      try {
        final result = await ApiService.getCompanyBirthdays(
          daysAhead: 30,
          isStaff: effectiveIsStaff,
        ).timeout(const Duration(seconds: 4));

        if (result['error'] != null) {
          birthdaysError =
              result['error'].toString().replaceFirst('Exception: ', '');
          todayBirthdays = [];
          upcomingBirthdays = [];
        } else {
          final apiToday = (result['today'] as List).cast<BirthdayItem>();
          final apiUpcoming = (result['upcoming'] as List).cast<BirthdayItem>();

          todayBirthdays = apiToday;
          upcomingBirthdays = apiUpcoming;
          hasLoadedApiBirthdays = true;
          birthdaysError = null;
        }
      } catch (e) {
        birthdaysError = e.toString().replaceFirst('Exception: ', '');
        todayBirthdays = [];
        upcomingBirthdays = [];
      }
    } else {
      if (_isTestModeSeeded) {
        _computeLocalBirthdays();
      } else {
        todayBirthdays = [];
        upcomingBirthdays = [];
      }
    }

    isBirthdaysLoading = false;
    notifyListeners();
  }

  void _computeLocalBirthdays() {
    final now = DateTime.now();
    todayBirthdays = [];
    upcomingBirthdays = [];
    for (final staff in staffList) {
      if (staff.dateOfBirth.isEmpty) continue;
      if (staff.status == 'resigned') continue;
      try {
        final parts = staff.dateOfBirth.split('-');
        if (parts.length < 3) continue;
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        // Adjust Feb 29 for non-leap years
        int effectiveDay = day;
        if (month == 2 && day == 29) {
          final isLeap =
              (now.year % 4 == 0 && now.year % 100 != 0) || now.year % 400 == 0;
          if (!isLeap) effectiveDay = 28;
        }
        final birthdayThisYear = DateTime(now.year, month, effectiveDay);
        final isToday = birthdayThisYear.month == now.month &&
            birthdayThisYear.day == now.day;
        int daysUntil = birthdayThisYear
            .difference(DateTime(now.year, now.month, now.day))
            .inDays;
        if (daysUntil < 0) {
          // Birthday has passed this year, check next year
          final birthdayNextYear = DateTime(now.year + 1, month, effectiveDay);
          daysUntil = birthdayNextYear
              .difference(DateTime(now.year, now.month, now.day))
              .inDays;
        }
        const monthNames = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec'
        ];
        final item = BirthdayItem(
          id: staff.id,
          employeeId: staff.id,
          name: staff.name,
          department: staff.department,
          designation: staff.designation,
          birthdayFormatted: '${monthNames[month - 1]} $effectiveDay',
          birthdayMonth: month,
          birthdayDay: effectiveDay,
          daysUntil: daysUntil,
          isToday: isToday,
        );
        if (isToday) {
          todayBirthdays.add(item);
        } else if (daysUntil <= 30 && daysUntil > 0) {
          upcomingBirthdays.add(item);
        }
      } catch (_) {}
    }
    upcomingBirthdays.sort((a, b) => a.daysUntil.compareTo(b.daysUntil));
  }

  void _initDepartments() {
    departments =
        DepartmentHelper.deduplicateDepartments(_getDefaultDepartments());
  }

  List<Department> _getDefaultDepartments() {
    final techStaff = staffList
        .where((s) => DepartmentHelper.areSameDepartment(s.department, 'tech'))
        .toList();
    final teleStaff = staffList
        .where((s) =>
            DepartmentHelper.areSameDepartment(s.department, 'telecalling'))
        .toList();
    return [
      Department(
        deptKey: 'tech',
        title: 'Tech & Engineering',
        subtitle: 'Frontend, Backend, Infrastructure & QA',
        staffCount: techStaff.length,
        activeCount: techStaff.where((s) => s.status == 'active').length,
        leadName: '',
        iconName: 'computer',
        colorHex: '#2563EB',
      ),
      Department(
        deptKey: 'telecalling',
        title: 'Telecalling & Client Relations',
        subtitle: 'Candidate Outreach, Lead Calling & Customer Support',
        staffCount: teleStaff.length,
        activeCount: teleStaff.where((s) => s.status == 'active').length,
        leadName: '',
        iconName: 'headset_mic',
        colorHex: '#DB2777',
      ),
    ];
  }

  /// Fetches departments from `GET /api/hr/departments`.
  Future<void> fetchDepartments() async {
    isDepartmentsLoading = true;
    departmentsError = null;
    notifyListeners();
    try {
      final list =
          await ApiService.getDepartments().timeout(const Duration(seconds: 4));
      departments = DepartmentHelper.deduplicateDepartments(list);
      departmentsError = null;
    } catch (e) {
      departmentsError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isDepartmentsLoading = false;
      notifyListeners();
    }
  }

  /// Fetches department details from `GET /api/hr/departments/:deptKey`.
  Future<Department?> fetchDepartmentDetail(String deptKey) async {
    isDepartmentDetailLoading = true;
    departmentDetailError = null;
    notifyListeners();
    try {
      final detail = await ApiService.getDepartmentDetail(deptKey)
          .timeout(const Duration(seconds: 4));
      selectedDepartmentDetail = detail;
      return detail;
    } catch (e) {
      departmentDetailError = e.toString().replaceFirst('Exception: ', '');
      selectedDepartmentDetail = null;
      return null;
    } finally {
      isDepartmentDetailLoading = false;
      notifyListeners();
    }
  }

  // --- Employee Management Actions ---
  Future<bool> addStaff(Map<String, dynamic> staffData) async {
    if (isApiStaffLoading) return false;
    isApiStaffLoading = true;
    apiStaffError = '';
    notifyListeners();

    void syncLocal([Staff? createdStaff]) {
      final double salaryVal =
          double.tryParse(staffData['salary']?.toString() ?? '') ?? 0.0;
      final history = <SalaryHistoryItem>[];
      if (salaryVal > 0) {
        history.add(SalaryHistoryItem(
          amount: salaryVal,
          currency: (staffData['salaryCurrency'] ?? 'INR').toString(),
          effectiveDate: (staffData['salaryEffectiveDate'] ?? '').toString(),
          changedBy: _currentUser?.name ?? 'HR Manager',
          reason: 'Joining Base Salary',
          timestamp: DateTime.now().toIso8601String().split('.').first,
        ));
      }
      final newStaff = createdStaff ??
          Staff(
            id: 'staff_${DateTime.now().millisecondsSinceEpoch}',
            name: (staffData['name'] ?? '').toString(),
            email: (staffData['email'] ?? '').toString(),
            phoneNumber: (staffData['phoneNumber'] ?? '').toString(),
            department: (staffData['department'] ?? 'Tech').toString(),
            role: (staffData['role'] ?? 'Staff').toString(),
            joinDate: (staffData['joinDate'] ??
                    DateTime.now().toIso8601String().split('T')[0])
                .toString(),
            status: (staffData['status'] ?? 'active').toString(),
            onLeaveToday: false,
            designation: (staffData['designation'] ?? 'Staff').toString(),
            workMode: (staffData['workMode'] ?? 'Office').toString(),
            salary: salaryVal,
            salaryCurrency: (staffData['salaryCurrency'] ?? 'INR').toString(),
            salaryEffectiveDate:
                (staffData['salaryEffectiveDate'] ?? '').toString(),
            paidLeaveAllowance: int.tryParse(
                    staffData['paidLeaveAllowance']?.toString() ?? '') ??
                1,
            salaryHistory: history,
            dateOfBirth: (staffData['dateOfBirth'] ?? '').toString(),
          );
      staffList.add(newStaff);
      _computeLocalBirthdays();
    }

    final rawName = (staffData['name'] as String? ?? '').trim();
    final parts = rawName.split(RegExp(r'\s+'));
    final firstName =
        parts.isNotEmpty && parts.first.isNotEmpty ? parts.first : 'Staff';
    final lastName = parts.length > 1 ? parts.skip(1).join(' ') : firstName;

    final payload = <String, dynamic>{
      'firstName': firstName,
      'lastName': lastName,
      'email': staffData['email'],
      'phone': staffData['phoneNumber'] ?? '',
      'department': staffData['department'] ?? 'Tech',
      'designation': staffData['designation'] ?? 'Staff',
      'workMode': staffData['workMode'] ?? 'Office',
      'salary': staffData['salary'] ?? 0.0,
      'salaryCurrency': staffData['salaryCurrency'] ?? 'INR',
      'salaryEffectiveDate': staffData['salaryEffectiveDate'] ?? '',
      'paidLeaveAllowance': staffData['paidLeaveAllowance'] ?? 1,
      if ((staffData['dateOfBirth'] as String?)?.isNotEmpty == true)
        'dateOfBirth': staffData['dateOfBirth'],
      if ((staffData['password'] as String?)?.isNotEmpty == true)
        'password': staffData['password'],
    };

    try {
      if (ApiService.hasToken || hasLoadedApiEmployees || !_isTestModeSeeded) {
        await ApiService.addEmployee(payload);
        await loadEmployeeDirectory(page: 1);
        final created = employeeDirectory
            .where((e) =>
                e.email.toLowerCase() ==
                (staffData['email'] ?? '').toString().toLowerCase())
            .firstOrNull;
        syncLocal(created);
        return true;
      } else {
        syncLocal();
        return true;
      }
    } catch (e) {
      apiStaffError = _cleanEmployeeError(e);
      return false;
    } finally {
      isApiStaffLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateStaff(String id, Map<String, dynamic> staffData) async {
    if (isApiStaffLoading) return false;
    isApiStaffLoading = true;
    apiStaffError = '';
    notifyListeners();

    void syncLocal() {
      final idx = staffList.indexWhere((s) => s.id == id);
      if (idx != -1) {
        final old = staffList[idx];
        staffList[idx] = Staff(
          id: old.id,
          name: (staffData['name'] ?? old.name).toString(),
          email: (staffData['email'] ?? old.email).toString(),
          phoneNumber: (staffData['phoneNumber'] ?? old.phoneNumber).toString(),
          department: (staffData['department'] ?? old.department).toString(),
          role: (staffData['role'] ?? old.role).toString(),
          joinDate: (staffData['joinDate'] ?? old.joinDate).toString(),
          status: (staffData['status'] ?? old.status).toString(),
          onLeaveToday: old.onLeaveToday,
          designation: (staffData['designation'] ?? old.designation).toString(),
          workMode: (staffData['workMode'] ?? old.workMode).toString(),
          salary: double.tryParse(staffData['salary']?.toString() ?? '') ??
              old.salary,
          salaryCurrency:
              (staffData['salaryCurrency'] ?? old.salaryCurrency).toString(),
          salaryEffectiveDate:
              (staffData['salaryEffectiveDate'] ?? old.salaryEffectiveDate)
                  .toString(),
          paidLeaveAllowance:
              int.tryParse(staffData['paidLeaveAllowance']?.toString() ?? '') ??
                  old.paidLeaveAllowance,
          salaryHistory: old.salaryHistory,
          dateOfBirth: (staffData['dateOfBirth'] ?? old.dateOfBirth).toString(),
        );
      }
      _computeLocalBirthdays();
    }

    try {
      Staff? old;
      try {
        old = employeeDirectory.where((s) => s.id == id).firstOrNull ??
            staffList.where((s) => s.id == id).firstOrNull ??
            (ApiService.hasToken ? await ApiService.getEmployee(id) : null);
      } catch (_) {}

      final backendPayload = <String, dynamic>{};
      if (staffData.containsKey('name') && staffData['name'] != null) {
        final rawName = (staffData['name'] as String).trim();
        final parts = rawName.split(RegExp(r'\s+'));
        final firstName =
            parts.isNotEmpty && parts.first.isNotEmpty ? parts.first : 'Staff';
        final lastName = parts.length > 1 ? parts.skip(1).join(' ') : firstName;
        backendPayload['name'] = rawName;
        backendPayload['firstName'] = firstName;
        backendPayload['lastName'] = lastName;
      }
      if (staffData.containsKey('email') &&
          staffData['email'] != null &&
          staffData['email'].toString().trim().isNotEmpty) {
        backendPayload['email'] = staffData['email'].toString().trim();
      }
      if (staffData.containsKey('phoneNumber') &&
          staffData['phoneNumber'] != null) {
        backendPayload['phone'] = staffData['phoneNumber'].toString().trim();
      } else if (staffData.containsKey('phone') && staffData['phone'] != null) {
        backendPayload['phone'] = staffData['phone'].toString().trim();
      }
      if (staffData.containsKey('department') &&
          staffData['department'] != null &&
          staffData['department'].toString().trim().isNotEmpty) {
        backendPayload['department'] =
            staffData['department'].toString().trim();
      }
      if (staffData.containsKey('designation') &&
          staffData['designation'] != null &&
          staffData['designation'].toString().trim().isNotEmpty) {
        backendPayload['designation'] =
            staffData['designation'].toString().trim();
      }
      if (staffData.containsKey('workMode') &&
          staffData['workMode'] != null &&
          staffData['workMode'].toString().trim().isNotEmpty) {
        backendPayload['workMode'] = staffData['workMode'].toString().trim();
      }
      if (staffData.containsKey('dateOfBirth') &&
          staffData['dateOfBirth'] != null) {
        final dob = staffData['dateOfBirth'].toString().trim();
        if (dob.isNotEmpty) {
          backendPayload['dateOfBirth'] = dob;
        }
      }
      if (staffData.containsKey('password') &&
          staffData['password'] != null &&
          staffData['password'].toString().trim().isNotEmpty) {
        backendPayload['password'] = staffData['password'].toString().trim();
      }

      if (ApiService.hasToken || hasLoadedApiEmployees || !_isTestModeSeeded) {
        final salary = double.tryParse(staffData['salary']?.toString() ?? '');
        final salaryChanged = salary != null &&
            (salary != old?.salary ||
                staffData['salaryCurrency'] != old?.salaryCurrency ||
                staffData['salaryEffectiveDate'] != old?.salaryEffectiveDate);
        if (salaryChanged) {
          if (backendPayload.isNotEmpty) {
            await ApiService.updateEmployee(id, backendPayload);
          }
          await ApiService.updateEmployeeSalary(id, {
            'salary': salary,
            'salaryCurrency':
                staffData['salaryCurrency'] ?? old?.salaryCurrency ?? 'INR',
            'salaryEffectiveDate': staffData['salaryEffectiveDate'] ??
                old?.salaryEffectiveDate ??
                '',
            'reason':
                staffData['salaryChangeReason'] ?? 'Salary details updated',
          });
        } else if (backendPayload.isNotEmpty) {
          await ApiService.updateEmployee(id, backendPayload);
        }
        await loadEmployeeDirectory();
        await fetchEmployeeDetails(id);
      }
      syncLocal();
      return true;
    } catch (e) {
      final message = _cleanEmployeeError(e);
      apiStaffError = message;
      return false;
    } finally {
      isApiStaffLoading = false;
      notifyListeners();
    }
  }

  Future<bool> editSalary({
    required String staffId,
    required double newSalary,
    required String effectiveDate,
    String currency = 'INR',
    String reason = 'Annual Review / Appraisal',
  }) async {
    if (isApiStaffLoading) return false;
    isApiStaffLoading = true;
    apiStaffError = '';
    notifyListeners();

    void syncLocal() {
      final historyItem = SalaryHistoryItem(
        amount: newSalary,
        currency: currency,
        effectiveDate: effectiveDate,
        changedBy: _currentUser?.name ?? 'HR Manager',
        reason: reason,
        timestamp: DateTime.now().toIso8601String().split('.').first,
      );

      final idx = staffList.indexWhere((s) => s.id == staffId);
      if (idx != -1) {
        final current = staffList[idx];
        staffList[idx] = current.copyWith(
          salary: newSalary,
          salaryCurrency: currency,
          salaryEffectiveDate: effectiveDate,
          salaryHistory: [historyItem, ...current.salaryHistory],
        );
      }

      final dirIdx = employeeDirectory.indexWhere((s) => s.id == staffId);
      if (dirIdx != -1) {
        final current = employeeDirectory[dirIdx];
        employeeDirectory[dirIdx] = current.copyWith(
          salary: newSalary,
          salaryCurrency: currency,
          salaryEffectiveDate: effectiveDate,
          salaryHistory: [historyItem, ...current.salaryHistory],
        );
      }
    }

    try {
      await ApiService.updateEmployeeSalary(staffId, {
        'salary': newSalary,
        'salaryCurrency': currency,
        'salaryEffectiveDate': effectiveDate,
        'reason': reason,
      });
      await loadEmployeeDirectory();
      await fetchEmployeeDetails(staffId);
      syncLocal();
      return true;
    } catch (e) {
      apiStaffError = _cleanEmployeeError(e);
      if (_isTestModeSeeded && !hasLoadedApiEmployees) {
        syncLocal();
        return true;
      }
      return false;
    } finally {
      isApiStaffLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deactivateStaff(String id) async {
    if (isApiStaffLoading) return false;
    isApiStaffLoading = true;
    apiStaffError = '';
    notifyListeners();

    try {
      await ApiService.deleteEmployee(id);
      await loadEmployeeDirectory();
      return true;
    } catch (e) {
      apiStaffError = _cleanEmployeeError(e);
      return false;
    } finally {
      isApiStaffLoading = false;
      notifyListeners();
    }
  }

  String _cleanEmployeeError(Object error) =>
      error.toString().replaceFirst('Exception: ', '');

  Future<void> loadEmployeeDirectory({int? page}) async {
    final version = ++_employeeRequestVersion;
    employeePage = page ?? employeePage;
    isApiStaffLoading = true;
    apiStaffError = '';
    notifyListeners();
    try {
      final result = await ApiService.getEmployeePage(
        page: employeePage,
        limit: employeeLimit,
        search: employeeSearchQuery,
        department: employeeDeptFilter,
        status: employeeStatusFilter,
      );
      if (version != _employeeRequestVersion) return;
      employeeDirectory = result.employees;
      employeePage = result.page;
      employeeLimit = result.limit;
      employeeTotal = result.total;
      employeeTotalPages = result.totalPages;
      hasLoadedApiEmployees = true;
    } catch (e) {
      if (version == _employeeRequestVersion) {
        apiStaffError = _cleanEmployeeError(e);
      }
    } finally {
      if (version == _employeeRequestVersion) {
        isApiStaffLoading = false;
        notifyListeners();
      }
    }
  }

  void _scheduleEmployeeDirectoryLoad({bool immediate = false}) {
    _employeeSearchTimer?.cancel();
    employeePage = 1;
    if (immediate) {
      loadEmployeeDirectory(page: 1);
    } else {
      _employeeSearchTimer = Timer(const Duration(milliseconds: 350),
          () => loadEmployeeDirectory(page: 1));
    }
  }

  Future<void> setEmployeePage(int page) => loadEmployeeDirectory(page: page);

  Future<Staff?> fetchEmployeeDetails(String id) async {
    final requestVersion = ++_employeeDetailRequestVersion;
    isEmployeeDetailLoading = true;
    employeeDetailError = null;
    notifyListeners();
    try {
      final detail = await ApiService.getEmployee(id);
      if (requestVersion != _employeeDetailRequestVersion) return null;
      final index = staffList.indexWhere((s) => s.id == id);
      if (index >= 0) staffList[index] = detail;
      final directoryIndex = employeeDirectory.indexWhere((s) => s.id == id);
      if (directoryIndex >= 0) employeeDirectory[directoryIndex] = detail;
      notifyListeners();
      return detail;
    } catch (e) {
      if (requestVersion != _employeeDetailRequestVersion) return null;
      employeeDetailError = _cleanEmployeeError(e);
      notifyListeners();
      return null;
    } finally {
      if (requestVersion == _employeeDetailRequestVersion) {
        isEmployeeDetailLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> setEmployeeStatus(String id, String status) async {
    if (isApiStaffLoading) return false;
    isApiStaffLoading = true;
    apiStaffError = '';
    notifyListeners();
    try {
      await ApiService.updateEmployeeStatus(id, status);
      await loadEmployeeDirectory();
      return true;
    } catch (e) {
      apiStaffError = _cleanEmployeeError(e);
      return false;
    } finally {
      isApiStaffLoading = false;
      notifyListeners();
    }
  }

  // --- Priority One: Leave Management Actions ---
  Future<bool> approveLeave(String id) async {
    isProcessingAction = true;
    leavesError = null;
    notifyListeners();

    try {
      await ApiService.approveLeaveRequest(id);
      if (hasLoadedApiLeaves || ApiService.hasToken || !_isTestModeSeeded) {
        await loadLeaves();
        if (_hasLoadedLeaveMetrics) {
          unawaited(_fetchLeaveMetrics()); // refresh stable metric cards
        }
      } else {
        _updateLocalLeave(id, 'Approved');
      }
      isProcessingAction = false;
      notifyListeners();
      return true;
    } catch (e) {
      isProcessingAction = false;
      leavesError = e.toString().replaceFirst('Exception: ', '');
      if (_isTestModeSeeded && !hasLoadedApiLeaves) {
        _updateLocalLeave(id, 'Approved');
        notifyListeners();
        return true;
      }
      notifyListeners();
      return false;
    }
  }

  void _updateLocalLeave(String id, String status, {String? reason}) {
    final index = leaveRequests.indexWhere((r) => r.id == id);
    if (index != -1) {
      final old = leaveRequests[index];
      leaveRequests[index] = LeaveRequest(
        id: old.id,
        staffId: old.staffId,
        fromDate: old.fromDate,
        toDate: old.toDate,
        reason: old.reason,
        status: status,
        employeeName: old.employeeName,
        employeeEmail: old.employeeEmail,
        department: old.department,
        leaveType: old.leaveType,
        daysCount: old.daysCount,
        submissionDate: old.submissionDate,
        hasMedicalProof: old.hasMedicalProof,
        medicalProofUrl: old.medicalProofUrl,
        medicalProofFileName: old.medicalProofFileName,
        medicalProofFileType: old.medicalProofFileType,
        approvedBy: _currentUser?.name ?? 'HR Manager',
        approvedAt: DateTime.now().toIso8601String().split('T')[0],
        rejectionReason: reason ?? old.rejectionReason,
      );

      if (status == 'Approved') {
        final staffIndex = staffList.indexWhere((s) => s.id == old.staffId);
        if (staffIndex != -1) {
          final st = staffList[staffIndex];
          staffList[staffIndex] = Staff(
            id: st.id,
            name: st.name,
            email: st.email,
            phoneNumber: st.phoneNumber,
            department: st.department,
            role: st.role,
            joinDate: st.joinDate,
            status: st.status,
            onLeaveToday: true,
            designation: st.designation,
            workMode: st.workMode,
          );
        }
      }
    }
  }

  Future<bool> rejectLeave(String id, String reason) async {
    isProcessingAction = true;
    leavesError = null;
    notifyListeners();

    try {
      await ApiService.rejectLeaveRequest(id, reason);
      if (hasLoadedApiLeaves || ApiService.hasToken || !_isTestModeSeeded) {
        await loadLeaves();
        if (_hasLoadedLeaveMetrics) {
          unawaited(_fetchLeaveMetrics()); // refresh stable metric cards
        }
      } else {
        _updateLocalLeave(id, 'Rejected', reason: reason);
      }
      isProcessingAction = false;
      notifyListeners();
      return true;
    } catch (e) {
      isProcessingAction = false;
      leavesError = e.toString().replaceFirst('Exception: ', '');
      if (_isTestModeSeeded && !hasLoadedApiLeaves) {
        _updateLocalLeave(id, 'Rejected', reason: reason);
        notifyListeners();
        return true;
      }
      notifyListeners();
      return false;
    }
  }

  // Backward compatibility alias for reviewLeave
  Future<void> reviewLeave(String id, bool approved, [String? reason]) async {
    if (approved) {
      await approveLeave(id);
    } else {
      await rejectLeave(id, reason ?? 'Request rejected by HR');
    }
  }

  // --- Task Assignment & Management (Screen 9 API Integration) ---
  Future<bool> assignTask(
    String staffId,
    String department,
    String description,
    String dueDate, {
    String? title,
  }) async {
    isProcessingAction = true;
    tasksError = null;
    notifyListeners();

    try {
      await ApiService.createTask(
        staffId: staffId,
        department: department,
        description: description,
        dueDate: dueDate,
        title: title,
      );
      await loadTasks();
      isProcessingAction = false;
      notifyListeners();
      return true;
    } catch (e) {
      isProcessingAction = false;
      tasksError = e.toString().replaceFirst('Exception: ', '');
      if (_isTestModeSeeded && !hasLoadedApiTasks) {
        final newTask = Task(
          id: 'task_${DateTime.now().millisecondsSinceEpoch}',
          staffId: staffId,
          department: department,
          description: description,
          status: 'pending',
          date: DateTime.now().toIso8601String().split('T')[0],
          dueDate: dueDate.isNotEmpty
              ? dueDate
              : DateTime.now()
                  .add(const Duration(days: 3))
                  .toIso8601String()
                  .split('T')[0],
          title: title ?? '',
        );
        tasksList.insert(0, newTask);
        notifyListeners();
        return true;
      }
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTaskStatus(String taskId, String newStatus) async {
    try {
      await ApiService.updateTask(taskId, status: newStatus.toLowerCase());
      await loadTasks();
      return true;
    } catch (e) {
      tasksError = e.toString().replaceFirst('Exception: ', '');
      if (_isTestModeSeeded && !hasLoadedApiTasks) {
        final index = tasksList.indexWhere((t) => t.id == taskId);
        if (index != -1) {
          final old = tasksList[index];
          tasksList[index] = old.copyWith(status: newStatus.toLowerCase());
          notifyListeners();
        }
        return true;
      }
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTask(String taskId) async {
    try {
      await ApiService.deleteTask(taskId);
      // The DELETE is confirmed. Remove it from the current cache immediately,
      // then let the backend GET below replace the list and its pagination data.
      tasksList.removeWhere((task) => task.id == taskId);
      apiTasksList.removeWhere((task) => task.id == taskId);
      if (tasksTotal > 0) tasksTotal--;
      await loadTasks();
      return true;
    } catch (e) {
      tasksError = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void setTaskStatusFilter(String status) {
    if (taskStatusFilter == status) return;
    taskStatusFilter = status;
    tasksPage = 1;
    notifyListeners();
    if (hasLoadedApiTasks) {
      loadTasks(page: 1);
    }
  }

  void setTaskDeptFilter(String dept) {
    if (taskDeptFilter == dept) return;
    taskDeptFilter = dept;
    tasksPage = 1;
    notifyListeners();
    if (hasLoadedApiTasks) {
      loadTasks(page: 1);
    }
  }

  void setTaskSearchQuery(String query) {
    taskSearchQuery = query;
    tasksPage = 1;
    notifyListeners();
    if (hasLoadedApiTasks) {
      final q = query.trim();
      if (q.startsWith('EMP') || q.length == 24 || q.isEmpty) {
        loadTasks(page: 1);
      }
    }
  }

  void setTasksPage(int page) {
    if (page < 1 || (tasksTotalPages > 0 && page > tasksTotalPages)) return;
    loadTasks(page: page);
  }

  void setDailyUpdatesDepartment(String department) {
    if (dailyUpdatesDeptFilter == department) return;
    dailyUpdatesDeptFilter = department;
    loadDailyUpdates(page: 1);
  }

  void setDailyUpdatesSearch(String query) {
    if (dailyUpdatesSearchQuery == query) return;
    dailyUpdatesSearchQuery = query;
    dailyUpdatesPage = 1;
    notifyListeners();
  }

  void setDailyUpdatesPage(int page) {
    if (page < 1 || page > dailyUpdatesTotalPages) return;
    loadDailyUpdates(page: page);
  }

  Future<void> loadDailyUpdates({int? page}) async {
    final targetPage = page ?? dailyUpdatesPage;
    dailyUpdatesPage = targetPage;
    isDailyUpdatesLoading = true;
    dailyUpdatesError = null;
    notifyListeners();
    final requestVersion = ++_dailyUpdatesRequestVersion;
    try {
      final result = await ApiService.getDailyUpdatesPage(
        page: targetPage,
        limit: dailyUpdatesLimit,
        department: dailyUpdatesDeptFilter,
      );
      if (_dailyUpdatesRequestVersion != requestVersion) return;
      apiDailyUpdatesList = result.updates;
      dailyUpdatesPage = result.page;
      dailyUpdatesLimit = result.limit;
      dailyUpdatesTotal = result.total;
      dailyUpdatesTotalPages = result.totalPages;
      hasLoadedApiDailyUpdates = true;
      isDailyUpdatesLoading = false;
      notifyListeners();
    } catch (e) {
      if (_dailyUpdatesRequestVersion != requestVersion) return;
      isDailyUpdatesLoading = false;
      dailyUpdatesError = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  List<DailyUpdate> get filteredDailyUpdates {
    final query = dailyUpdatesSearchQuery.trim().toLowerCase();
    return apiDailyUpdatesList.where((update) {
      final matchesDepartment = dailyUpdatesDeptFilter == 'all' ||
          update.department.toLowerCase() ==
              dailyUpdatesDeptFilter.toLowerCase();
      if (!matchesDepartment) return false;
      if (query.isEmpty) return true;
      return update.title.toLowerCase().contains(query) ||
          update.updateText.toLowerCase().contains(query) ||
          update.employeeName.toLowerCase().contains(query) ||
          update.employeeId.toLowerCase().contains(query) ||
          update.staffId.toLowerCase().contains(query) ||
          update.department.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> loadEmployeeDailyUpdates(String employeeId, {int? page}) async {
    final cleanEmployeeId = employeeId.trim();
    if (cleanEmployeeId.isEmpty) return;
    final targetPage = page ??
        (employeeDailyUpdatesStaffId == cleanEmployeeId
            ? employeeDailyUpdatesPage
            : 1);
    if (employeeDailyUpdatesStaffId != cleanEmployeeId) {
      employeeDailyUpdates = [];
      employeeDailyUpdatesPage = 1;
      employeeDailyUpdatesTotal = 0;
      employeeDailyUpdatesTotalPages = 1;
      employeeDailyUpdatesStaffId = cleanEmployeeId;
    }
    isEmployeeDailyUpdatesLoading = true;
    employeeDailyUpdatesError = null;
    notifyListeners();
    final requestVersion = ++_employeeDailyUpdatesRequestVersion;
    try {
      final result = await ApiService.getDailyUpdatesPage(
        page: targetPage,
        limit: 100,
        employeeId: cleanEmployeeId,
      );
      if (_employeeDailyUpdatesRequestVersion != requestVersion ||
          employeeDailyUpdatesStaffId != cleanEmployeeId) {
        return;
      }
      employeeDailyUpdates = result.updates
          .where((update) =>
              update.staffId == cleanEmployeeId ||
              update.employeeId == cleanEmployeeId)
          .toList();
      employeeDailyUpdatesPage = result.page;
      employeeDailyUpdatesTotal = result.total;
      employeeDailyUpdatesTotalPages = result.totalPages;
      isEmployeeDailyUpdatesLoading = false;
      notifyListeners();
    } catch (e) {
      if (_employeeDailyUpdatesRequestVersion != requestVersion ||
          employeeDailyUpdatesStaffId != cleanEmployeeId) {
        return;
      }
      isEmployeeDailyUpdatesLoading = false;
      employeeDailyUpdatesError = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  void setEmployeeDailyUpdatesPage(String employeeId, int page) {
    if (page < 1 || page > employeeDailyUpdatesTotalPages) return;
    loadEmployeeDailyUpdates(employeeId, page: page);
  }

  Future<void> loadTasks({int? page}) async {
    final targetPage = page ?? tasksPage;
    tasksPage = targetPage;
    isTasksLoading = true;
    tasksError = null;
    notifyListeners();

    final currentVersion = ++_tasksRequestVersion;

    try {
      String? backendStatus;
      if (taskStatusFilter != 'all') {
        backendStatus = taskStatusFilter.toLowerCase();
      }

      String? backendDept;
      if (taskDeptFilter != 'all') {
        backendDept = taskDeptFilter;
      }

      String? empIdQuery;
      if (taskSearchQuery.isNotEmpty) {
        final q = taskSearchQuery.trim();
        if (q.toUpperCase().startsWith('EMP') || q.length == 24) {
          empIdQuery = q;
        }
      }

      final pageResult = await ApiService.getTasksPage(
        page: targetPage,
        limit: tasksLimit,
        status: backendStatus,
        department: backendDept,
        employeeId: empIdQuery,
      );

      if (_tasksRequestVersion != currentVersion) return;

      apiTasksList = pageResult.tasks;
      tasksTotal = pageResult.total;
      tasksTotalPages = pageResult.totalPages;
      tasksPage = pageResult.page;
      hasLoadedApiTasks = true;
      tasksError = null;
      isTasksLoading = false;
      notifyListeners();
    } catch (e) {
      if (_tasksRequestVersion != currentVersion) return;
      isTasksLoading = false;
      tasksError = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  List<Task> get filteredTasksList {
    if (hasLoadedApiTasks) {
      final source = apiTasksList;
      return source.where((t) {
        final matchesStatus = taskStatusFilter == 'all' ||
            t.status.toLowerCase() == taskStatusFilter.toLowerCase();
        final matchesDept = taskDeptFilter == 'all' ||
            t.department.toLowerCase() == taskDeptFilter.toLowerCase();

        bool matchesSearch = true;
        if (taskSearchQuery.trim().isNotEmpty) {
          final q = taskSearchQuery.toLowerCase();
          matchesSearch = t.description.toLowerCase().contains(q) ||
              t.title.toLowerCase().contains(q) ||
              t.department.toLowerCase().contains(q) ||
              t.employeeName.toLowerCase().contains(q) ||
              t.employeeId.toLowerCase().contains(q) ||
              t.staffId.toLowerCase().contains(q);
        }

        return matchesStatus && matchesDept && matchesSearch;
      }).toList();
    }

    if (!_isTestModeSeeded || tasksError != null || ApiService.hasToken) {
      return const [];
    }
    return tasksList.where((t) {
      final matchesStatus = taskStatusFilter == 'all' ||
          t.status.toLowerCase() == taskStatusFilter.toLowerCase();
      final matchesDept = taskDeptFilter == 'all' ||
          t.department.toLowerCase() == taskDeptFilter.toLowerCase();

      bool matchesSearch = true;
      if (taskSearchQuery.trim().isNotEmpty) {
        final q = taskSearchQuery.toLowerCase();
        matchesSearch = t.description.toLowerCase().contains(q) ||
            t.title.toLowerCase().contains(q) ||
            t.department.toLowerCase().contains(q) ||
            t.employeeName.toLowerCase().contains(q) ||
            t.employeeId.toLowerCase().contains(q) ||
            t.staffId.toLowerCase().contains(q);
      }

      return matchesStatus && matchesDept && matchesSearch;
    }).toList();
  }

  // --- Authentication ---
  void clearLoginError() {
    loginError = '';
    notifyListeners();
  }

  Future<bool> loginWithApi(String email, String password) async {
    isLoginLoading = true;
    loginError = '';
    notifyListeners();

    final result = await ApiService.login(email, password);

    if (result['success'] != true) {
      isLoginLoading = false;
      loginError =
          result['message']?.toString() ?? 'Login failed. Please try again.';
      notifyListeners();
      return false;
    }

    final userMap = result['user'];
    if (userMap is! Map<String, dynamic>) {
      isLoginLoading = false;
      loginError = 'Malformed user data received from server.';
      notifyListeners();
      return false;
    }

    final rawRole = (userMap['role'] ?? '').toString().toUpperCase();
    final isActive = userMap['isActive'] != false;

    if (!isActive) {
      isLoginLoading = false;
      loginError = 'Your account has been deactivated. Please contact HR.';
      ApiService.clearTokens();
      notifyListeners();
      return false;
    }

    // Role-based routing: HR/ADMIN/SUPER_ADMIN access HR dashboard; STAFF accesses staff-portal
    final isAuthorizedAdmin = rawRole == 'HR' ||
        rawRole == 'HR MANAGER' ||
        rawRole == 'ADMIN' ||
        rawRole == 'SUPER_ADMIN' ||
        rawRole == 'SUPERADMIN';
    final isStaff = rawRole == 'STAFF' || rawRole == 'EMPLOYEE';

    if (!isAuthorizedAdmin && !isStaff) {
      isLoginLoading = false;
      ApiService.clearTokens();
      loginError =
          'Access denied: You do not have permission to access the portal.';
      notifyListeners();
      return false;
    }

    final isSuperAdmin = rawRole == 'SUPER_ADMIN' || rawRole == 'SUPERADMIN';
    final roleDisplay = isSuperAdmin
        ? 'Super Admin'
        : (isStaff
            ? 'Staff'
            : (rawRole == 'ADMIN' ? 'Administrator' : 'HR Manager'));
    final defaultDesignation = isSuperAdmin
        ? 'Super Administrator'
        : (isStaff ? 'Staff Member' : 'HR Director');
    final defaultDept = isSuperAdmin
        ? (userMap['department'] != null &&
                userMap['department'].toString().isNotEmpty
            ? userMap['department'].toString()
            : 'Executive Management')
        : (isStaff
            ? (userMap['department']?.toString() ?? 'General')
            : (userMap['department']?.toString() ?? 'Human Resources'));

    final firstName = userMap['firstName']?.toString() ?? '';
    final lastName = userMap['lastName']?.toString() ?? '';
    final fullName = ('$firstName $lastName').trim();

    final empMap = (userMap['employee'] is Map<String, dynamic>)
        ? userMap['employee'] as Map<String, dynamic>
        : (userMap['employee'] is Map
            ? Map<String, dynamic>.from(userMap['employee'] as Map)
            : null);

    final staffId = empMap?['_id']?.toString() ??
        empMap?['id']?.toString() ??
        userMap['employeeId']?.toString() ??
        userMap['id']?.toString() ??
        userMap['_id']?.toString() ??
        (isStaff ? 'staff_user' : 'hr_user');

    final staffDept = empMap?['department']?.toString() ?? defaultDept;
    final staffDesig = empMap?['designation']?.toString() ??
        userMap['designation']?.toString() ??
        defaultDesignation;
    final staffPhone = empMap?['phone']?.toString() ??
        userMap['phone']?.toString() ??
        userMap['phoneNumber']?.toString() ??
        '';
    final staffSalary =
        empMap?['salary'] is num ? (empMap!['salary'] as num).toDouble() : 0.0;
    final staffCurrency = empMap?['salaryCurrency']?.toString() ?? 'INR';
    final staffDob = empMap?['dateOfBirth']?.toString() ?? '';

    _currentUser = Staff(
      id: staffId,
      name: fullName.isNotEmpty
          ? fullName
          : (userMap['name']?.toString() ??
              (isSuperAdmin
                  ? 'Super Administrator'
                  : (isStaff ? 'Staff Member' : 'HR Administrator'))),
      email: userMap['email']?.toString() ?? email,
      phoneNumber: staffPhone,
      department: staffDept,
      role: roleDisplay,
      joinDate: empMap?['joiningDate'] != null
          ? empMap!['joiningDate'].toString().split('T').first
          : (userMap['createdAt'] != null
              ? userMap['createdAt'].toString().split('T').first
              : DateTime.now().toString().split(' ').first),
      status: 'active',
      onLeaveToday: false,
      designation: staffDesig,
      workMode: empMap?['workMode']?.toString() ?? 'Office',
      salary: staffSalary,
      salaryCurrency: staffCurrency,
      dateOfBirth: staffDob,
    );

    ApiService.setUserRole(rawRole);

    if (isStaff) {
      _currentScreen = 'staff-portal';
      isLoginLoading = false;
      loginError = '';
      notifyListeners();
      return true;
    }

    _currentScreen = 'hr-dashboard';
    isLoginLoading = false;
    loginError = '';
    fetchDashboardData();
    notifyListeners();
    return true;
  }

  void login(String email, String password) {
    _currentUser = Staff(
      id: 'admin_1',
      name: 'HR Administrator',
      email: email.isNotEmpty ? email : 'admin@company.com',
      phoneNumber: '9876543210',
      department: 'Tech',
      role: 'HR Manager',
      joinDate: '2024-01-01',
      status: 'active',
      onLeaveToday: false,
      designation: 'Lead HR Administrator',
      workMode: 'Office',
    );
    _currentScreen = 'hr-dashboard';
    fetchDashboardData();
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    _currentScreen = 'login';
    _selectedStaffId = null;
    loginError = '';
    isLoginLoading = false;
    ApiService.clearTokens();
    notifyListeners();
  }

  // --- Navigation Methods ---
  void setScreen(String screen) {
    // Prevent ordinary staff accounts from navigating into administrative HR screens
    if (_currentUser != null &&
        (_currentUser!.role.toLowerCase() == 'staff' ||
            ApiService.isStaffRole)) {
      const allowedStaffScreens = {
        'staff-portal',
        'dept-chat',
        'chat',
        'login'
      };
      if (!allowedStaffScreens.contains(screen)) {
        _currentScreen = 'staff-portal';
        notifyListeners();
        return;
      }
    }

    _currentScreen = screen;
    notifyListeners();
  }

  void navigateTo(String screen) => setScreen(screen);

  void viewStaffProfile(String id) {
    _selectedStaffId = id;
    fetchEmployeeDetails(id);
    loadEmployeeDocuments(id);
    setScreen('staff-profile');
  }

  Future<void> loadEmployeeDocuments(String employeeId) async {
    final requestVersion = ++_employeeDocumentsRequestVersion;
    isDocumentsLoading = true;
    employeeDocumentsError = null;
    notifyListeners();
    try {
      final docs = await ApiService.getEmployeeDocuments(employeeId);
      if (requestVersion != _employeeDocumentsRequestVersion) return;
      documentsList.removeWhere((d) => d.employeeId == employeeId);
      documentsList.addAll(docs);
    } catch (e) {
      if (requestVersion == _employeeDocumentsRequestVersion) {
        final existingDocs =
            documentsList.where((d) => d.employeeId == employeeId).toList();
        if (existingDocs.isEmpty) {
          employeeDocumentsError = _cleanEmployeeError(e);
        }
      }
    } finally {
      if (requestVersion == _employeeDocumentsRequestVersion) {
        isDocumentsLoading = false;
        notifyListeners();
      }
    }
  }

  Future<HRDocumentItem?> fetchEmployeeDocument(String documentId) async {
    try {
      final document = await ApiService.getEmployeeDocument(documentId);
      final index = documentsList.indexWhere((item) => item.id == documentId);
      if (index >= 0) documentsList[index] = document;
      notifyListeners();
      return document;
    } catch (e) {
      employeeDocumentsError = _cleanEmployeeError(e);
      notifyListeners();
      return null;
    }
  }

  List<HRDocumentItem> getDocumentsForStaff(String staffId) {
    return documentsList.where((d) => d.employeeId == staffId).toList();
  }

  Future<bool> uploadDocument({
    required String employeeId,
    required String title,
    required String category,
    String? description,
    String? issueDate,
    String? expiryDate,
    required String fileName,
    required List<int> fileBytes,
  }) async {
    if (isProcessingAction) return false;
    isProcessingAction = true;
    employeeDocumentsError = null;
    notifyListeners();

    void syncLocal() {
      final docItem = HRDocumentItem(
        id: 'doc_${DateTime.now().millisecondsSinceEpoch}',
        employeeId: employeeId,
        title: title,
        category: category,
        description: description ?? '',
        fileName: fileName,
        originalName: fileName,
        filePath: '/uploads/documents/$fileName',
        fileType: fileName.endsWith('.pdf') ? 'application/pdf' : 'image/png',
        fileSize: fileBytes.length,
        issueDate: issueDate ?? '',
        expiryDate: expiryDate ?? '',
        uploadedBy: _currentUser?.name ?? 'HR Manager',
        status: 'ACTIVE',
        version: 1,
        createdAt: DateTime.now(),
      );
      documentsList.insert(0, docItem);
    }

    try {
      final success = await ApiService.uploadEmployeeDocument(
        employeeId: employeeId,
        title: title,
        category: category,
        description: description,
        issueDate: issueDate,
        expiryDate: expiryDate,
        fileName: fileName,
        fileBytes: fileBytes,
      );
      if (!success) {
        throw Exception(
            'Document upload failed. Check the file and try again.');
      }
      await loadEmployeeDocuments(employeeId);
      return true;
    } catch (e) {
      employeeDocumentsError = _cleanEmployeeError(e);
      if (_isTestModeSeeded) {
        employeeDocumentsError = null;
        syncLocal();
        return true;
      }
      return false;
    } finally {
      isProcessingAction = false;
      notifyListeners();
    }
  }

  Future<bool> replaceDocument({
    required String docId,
    required String employeeId,
    required String title,
    String? description,
    String? issueDate,
    String? expiryDate,
    required String fileName,
    required List<int> fileBytes,
  }) async {
    if (isProcessingAction) return false;
    isProcessingAction = true;
    employeeDocumentsError = null;
    notifyListeners();

    void syncLocal() {
      final idx = documentsList.indexWhere((d) => d.id == docId);
      if (idx != -1) {
        final old = documentsList[idx];
        documentsList[idx] = HRDocumentItem(
          id: old.id,
          employeeId: employeeId,
          title: title,
          category: old.category,
          description: description ?? old.description,
          fileName: fileName,
          originalName: fileName,
          filePath: '/uploads/documents/$fileName',
          fileType: fileName.endsWith('.pdf') ? 'application/pdf' : 'image/png',
          fileSize: fileBytes.length,
          issueDate: issueDate ?? old.issueDate,
          expiryDate: expiryDate ?? old.expiryDate,
          uploadedBy: _currentUser?.name ?? 'HR Manager',
          status: 'ACTIVE',
          version: old.version + 1,
          createdAt: DateTime.now(),
        );
      }
    }

    try {
      final success = await ApiService.replaceEmployeeDocument(
        docId: docId,
        title: title,
        description: description,
        issueDate: issueDate,
        expiryDate: expiryDate,
        fileName: fileName,
        fileBytes: fileBytes,
      );
      if (!success) {
        throw Exception('Document replacement failed. Please retry.');
      }
      await loadEmployeeDocuments(employeeId);
      return true;
    } catch (e) {
      employeeDocumentsError = _cleanEmployeeError(e);
      if (_isTestModeSeeded) {
        employeeDocumentsError = null;
        syncLocal();
        return true;
      }
      return false;
    } finally {
      isProcessingAction = false;
      notifyListeners();
    }
  }

  Future<bool> archiveDocument(String docId, String employeeId) async {
    if (isProcessingAction) return false;
    isProcessingAction = true;
    employeeDocumentsError = null;
    notifyListeners();

    void syncLocal() {
      final idx = documentsList.indexWhere((d) => d.id == docId);
      if (idx != -1) {
        final old = documentsList[idx];
        documentsList[idx] = HRDocumentItem(
          id: old.id,
          employeeId: old.employeeId,
          title: old.title,
          category: old.category,
          description: old.description,
          fileName: old.fileName,
          originalName: old.originalName,
          filePath: old.filePath,
          fileType: old.fileType,
          fileSize: old.fileSize,
          issueDate: old.issueDate,
          expiryDate: old.expiryDate,
          uploadedBy: old.uploadedBy,
          status: 'ARCHIVED',
          version: old.version,
          createdAt: old.createdAt,
        );
      }
    }

    try {
      final success = await ApiService.archiveEmployeeDocument(docId);
      if (!success) throw Exception('Document archive failed. Please retry.');
      await loadEmployeeDocuments(employeeId);
      return true;
    } catch (e) {
      employeeDocumentsError = _cleanEmployeeError(e);
      if (_isTestModeSeeded) {
        employeeDocumentsError = null;
        syncLocal();
        return true;
      }
      return false;
    } finally {
      isProcessingAction = false;
      notifyListeners();
    }
  }

  Future<DownloadedEmployeeDocument?> fetchMedicalDocument(
    String documentUrlOrId, {
    String? expectedFileName,
    String? expectedFileType,
  }) async {
    if (isProcessingAction) return null;
    isProcessingAction = true;
    employeeDocumentsError = null;
    notifyListeners();
    try {
      final res = await ApiService.fetchMedicalDocumentSecurely(
        documentUrlOrId,
        expectedFileName: expectedFileName,
        expectedFileType: expectedFileType,
      );
      final bytes = res['bytes'] as Uint8List;
      final cType = res['contentType'] as String? ?? 'application/pdf';
      return DownloadedEmployeeDocument(bytes, cType);
    } catch (e) {
      employeeDocumentsError = _cleanEmployeeError(e);
      return null;
    } finally {
      isProcessingAction = false;
      notifyListeners();
    }
  }

  Future<DownloadedEmployeeDocument?> downloadEmployeeDocument(
      String documentId) async {
    if (isProcessingAction) return null;
    isProcessingAction = true;
    employeeDocumentsError = null;
    notifyListeners();
    try {
      final response = await ApiService.downloadEmployeeDocument(documentId);
      var cType =
          response.headers['content-type'] ?? 'application/octet-stream';
      if (cType.contains('octet-stream')) {
        final matchingDoc =
            documentsList.where((d) => d.id == documentId).firstOrNull;
        if (matchingDoc != null) {
          if (matchingDoc.isPdf) {
            cType = 'application/pdf';
          } else if (matchingDoc.isImage) {
            cType = matchingDoc.originalName.toLowerCase().endsWith('.png')
                ? 'image/png'
                : 'image/jpeg';
          }
        }
      }
      return DownloadedEmployeeDocument(
        response.bodyBytes,
        cType,
      );
    } catch (e) {
      employeeDocumentsError = _cleanEmployeeError(e);
      return null;
    } finally {
      isProcessingAction = false;
      notifyListeners();
    }
  }

  void navigateToLeaveManagement({String? statusFilter}) {
    if (statusFilter != null) {
      leaveStatusFilter = statusFilter;
    }
    leavesPage = 1;
    setScreen('leave-management');
    if (hasLoadedApiLeaves) {
      loadLeaves(page: 1);
    }
  }

  void navigateToAttendance({String? statusFilter, String? workMode}) {
    if (statusFilter != null) {
      attendanceStatusFilter = statusFilter;
    }
    if (workMode != null) {
      attendanceWorkModeFilter = workMode;
    }
    setScreen('attendance');
  }

  void navigateToEmployees({String? statusFilter, String? deptFilter}) {
    if (statusFilter != null) {
      employeeStatusFilter = statusFilter;
    }
    if (deptFilter != null) {
      employeeDeptFilter = deptFilter;
    }
    setScreen('employees');
  }

  void navigateToTasks() => setScreen('tasks');
  void navigateToReports() {
    setScreen('reports');
    if (hasLoadedApiReports) {
      loadReports();
    }
  }

  void navigateToDepartments() {
    setScreen('departments');
    fetchDepartments();
  }

  void navigateToChat({String? participantId}) {
    selectedChatParticipantId = participantId;
    setScreen('chat');
  }

  void navigateToDepartmentChat(String deptKey) {
    activeDepartmentChatKey = deptKey;
    markDepartmentChatAsRead(deptKey);
    setScreen('dept-chat');
  }

  // --- Department Chat Actions (Screen 11 API Integration) ---

  DepartmentChatThread? getDepartmentThread(String deptKey) {
    try {
      final thread = departmentChatThreads.firstWhere(
        (d) => d.departmentKey.toLowerCase() == deptKey.toLowerCase(),
      );
      if (departmentChatError != null && !hasLoadedApiDepartmentChat) {
        // Prevent mock data from being presented as live server data on error
        return thread.copyWith(messages: const []);
      }
      return thread;
    } catch (_) {
      return null;
    }
  }

  int getDepartmentUnreadCount(String deptKey) {
    final thread = getDepartmentThread(deptKey);
    return thread?.unreadCount ?? 0;
  }

  Future<void> loadDepartmentMessages(String deptKey) async {
    isDepartmentChatLoading = true;
    departmentChatError = null;
    notifyListeners();

    final currentVersion = ++_departmentChatRequestVersion;
    final isStaff = currentUser != null &&
        currentUser!.role != 'HR Manager' &&
        currentUser!.role != 'HR';

    try {
      final messages =
          await ApiService.getDepartmentMessages(deptKey, isStaff: isStaff);
      if (_departmentChatRequestVersion != currentVersion) return;

      final idx = departmentChatThreads.indexWhere(
        (d) => d.departmentKey.toLowerCase() == deptKey.toLowerCase(),
      );

      if (idx != -1) {
        final thread = departmentChatThreads[idx];
        final updated = thread.copyWith(messages: messages);
        departmentChatThreads = [
          ...departmentChatThreads.sublist(0, idx),
          updated,
          ...departmentChatThreads.sublist(idx + 1),
        ];
      } else {
        final newThread = DepartmentChatThread(
          departmentKey: deptKey,
          departmentName: deptKey == 'tech'
              ? 'Tech & Engineering'
              : 'Telecalling & Client Relations',
          icon: deptKey == 'tech' ? '💻' : '📞',
          memberIds: staffList
              .where((s) =>
                  s.department.toLowerCase().contains(deptKey.toLowerCase()))
              .map((s) => s.id)
              .toList(),
          messages: messages,
        );
        departmentChatThreads = [...departmentChatThreads, newThread];
      }

      hasLoadedApiDepartmentChat = true;
      departmentChatError = null;
      isDepartmentChatLoading = false;
      notifyListeners();
    } catch (e) {
      if (_departmentChatRequestVersion != currentVersion) return;
      isDepartmentChatLoading = false;
      departmentChatError = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> sendDepartmentMessage(
    String deptKey,
    String text, {
    String? senderId,
    String? senderName,
  }) async {
    if (text.trim().isEmpty) return;

    final sId = senderId ?? (currentUser?.id ?? 'admin_1');
    final sName = senderName ??
        (currentUser?.name != null
            ? '${currentUser!.name} (${currentUser!.role})'
            : 'HR Manager');

    final newMsg = ChatMessage(
      id: 'dept_msg_${DateTime.now().microsecondsSinceEpoch}_${(1000 + (DateTime.now().millisecond * 7))}',
      senderId: sId,
      senderName: sName,
      receiverId: 'dept_$deptKey',
      text: text.trim(),
      timestamp: DateTime.now(),
      isRead: sId == 'admin_1',
    );

    final idx = departmentChatThreads.indexWhere(
      (d) => d.departmentKey.toLowerCase() == deptKey.toLowerCase(),
    );

    if (idx != -1) {
      final thread = departmentChatThreads[idx];
      final updated = thread.copyWith(
        messages: [...thread.messages, newMsg],
      );
      departmentChatThreads = [
        ...departmentChatThreads.sublist(0, idx),
        updated,
        ...departmentChatThreads.sublist(idx + 1),
      ];
    } else {
      final newThread = DepartmentChatThread(
        departmentKey: deptKey,
        departmentName: deptKey == 'tech'
            ? 'Tech & Engineering'
            : 'Telecalling & Client Relations',
        icon: deptKey == 'tech' ? '💻' : '📞',
        memberIds: staffList
            .where((s) =>
                s.department.toLowerCase().contains(deptKey.toLowerCase()))
            .map((s) => s.id)
            .toList(),
        messages: [newMsg],
      );
      departmentChatThreads = [...departmentChatThreads, newThread];
    }
    notifyListeners();

    final isStaff = currentUser != null &&
        currentUser!.role != 'HR Manager' &&
        currentUser!.role != 'HR';

    try {
      await ApiService.sendDepartmentMessage(
        deptKey,
        text.trim(),
        senderName: sName,
        isStaff: isStaff,
      );
      if (hasLoadedApiDepartmentChat) {
        await loadDepartmentMessages(deptKey);
      }
    } catch (_) {
      // Retain locally in state if backend offline
    }
  }

  /// Sends a simulated reply from an authorized department employee.
  /// Used for live multi-party chat verification directly inside the UI.
  Future<void> sendStaffReply(
      String deptKey, String staffId, String text) async {
    final staff = staffList.firstWhere(
      (s) => s.id == staffId,
      orElse: () => Staff(
        id: staffId,
        name: 'Staff Member',
        email: '',
        phoneNumber: '',
        department: deptKey == 'tech' ? 'Tech' : 'Telecalling',
        role: 'Staff',
        joinDate: '',
        status: 'active',
        onLeaveToday: false,
        designation: 'Engineer',
        workMode: 'Office',
      ),
    );

    await sendDepartmentMessage(
      deptKey,
      text,
      senderId: staff.id,
      senderName: staff.name,
    );
  }

  void markDepartmentChatAsRead(String deptKey) {
    final idx = departmentChatThreads.indexWhere(
      (d) => d.departmentKey.toLowerCase() == deptKey.toLowerCase(),
    );
    if (idx == -1) return;
    final thread = departmentChatThreads[idx];
    final updatedMessages = thread.messages
        .map((m) => m.senderId != 'admin_1' ? m.copyWith(isRead: true) : m)
        .toList();
    final updated = thread.copyWith(messages: updatedMessages);
    departmentChatThreads = [
      ...departmentChatThreads.sublist(0, idx),
      updated,
      ...departmentChatThreads.sublist(idx + 1),
    ];
    notifyListeners();
  }

  // ── Message Deletion ──────────────────────────────────────────────────────

  /// Hides a message only for [callerId] in the local state and synchronises
  /// the preference to the backend. Other group members are unaffected.
  Future<DeletionResult> deleteDepartmentMessageForMe(
    String deptKey,
    String messageId,
    String callerId,
  ) async {
    final isStaff = currentUser != null &&
        currentUser!.role != 'HR Manager' &&
        currentUser!.role != 'HR';

    // Synchronise with backend
    try {
      await ApiService.deleteDepartmentMessageForMe(
          deptKey, messageId, callerId,
          isStaff: isStaff);
      if (hasLoadedApiDepartmentChat) {
        await loadDepartmentMessages(deptKey);
      } else {
        _applyDeleteForMe(deptKey, messageId, callerId);
      }
    } on DeletionPermissionException catch (e) {
      return DeletionResult.permissionDenied(e.message);
    } catch (e) {
      return DeletionResult.failure(
          e.toString().replaceFirst('Exception: ', ''));
    }
    return DeletionResult.success();
  }

  void _applyDeleteForMe(String deptKey, String messageId, String callerId) {
    final idx = departmentChatThreads.indexWhere(
      (d) => d.departmentKey.toLowerCase() == deptKey.toLowerCase(),
    );
    if (idx == -1) return;
    final thread = departmentChatThreads[idx];
    final updatedMessages = thread.messages.map((m) {
      if (m.id != messageId) return m;
      final newIds = Set<String>.from(m.deletedByIds)..add(callerId);
      return m.copyWith(deletedByIds: newIds);
    }).toList();
    departmentChatThreads = [
      ...departmentChatThreads.sublist(0, idx),
      thread.copyWith(messages: updatedMessages),
      ...departmentChatThreads.sublist(idx + 1),
    ];
    notifyListeners();
  }

  /// Deletes a message for everyone. Only the sender or an HR Manager may do this.
  /// Permission is validated both locally (fast feedback) and on the backend.
  Future<DeletionResult> deleteDepartmentMessageForEveryone(
    String deptKey,
    String messageId,
    String callerId,
  ) async {
    // Local permission pre-check (sender or HR Manager)
    final isHR = currentUser?.role == 'HR Manager';
    final isOwner = _findMessage(deptKey, messageId)?.senderId == callerId;
    if (!isHR && !isOwner) {
      return DeletionResult.permissionDenied(
          'Only the message sender or an HR Manager can delete for everyone.');
    }

    final isStaffCaller = !isHR;

    try {
      final ok = await ApiService.deleteDepartmentMessageForEveryone(
          deptKey, messageId,
          isStaff: isStaffCaller);
      if (!ok) {
        return DeletionResult.failure(
            'Server did not confirm deletion. Message preserved.');
      }
      if (hasLoadedApiDepartmentChat) {
        await loadDepartmentMessages(deptKey);
      } else {
        _removeMessageFromThread(deptKey, messageId);
      }
      return DeletionResult.success();
    } on DeletionPermissionException catch (e) {
      return DeletionResult.permissionDenied(e.message);
    } catch (e) {
      return DeletionResult.failure(
          e.toString().replaceFirst('Exception: ', ''));
    }
  }

  ChatMessage? _findMessage(String deptKey, String messageId) {
    try {
      return getDepartmentThread(deptKey)
          ?.messages
          .firstWhere((m) => m.id == messageId);
    } catch (_) {
      return null;
    }
  }

  void _removeMessageFromThread(String deptKey, String messageId) {
    final idx = departmentChatThreads.indexWhere(
      (d) => d.departmentKey.toLowerCase() == deptKey.toLowerCase(),
    );
    if (idx == -1) return;
    final thread = departmentChatThreads[idx];
    final updatedMessages =
        thread.messages.where((m) => m.id != messageId).toList();
    departmentChatThreads = [
      ...departmentChatThreads.sublist(0, idx),
      thread.copyWith(messages: updatedMessages),
      ...departmentChatThreads.sublist(idx + 1),
    ];
    notifyListeners();
  }

  // --- Chat Actions ---

  void sendMessage(String participantId, String text) {
    if (text.trim().isEmpty) return;
    final newMsg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'admin_1',
      senderName: 'Anita Roy (HR Manager)',
      receiverId: participantId,
      text: text.trim(),
      timestamp: DateTime.now(),
      isRead: true,
    );

    final idx = chatThreads.indexWhere((t) => t.participantId == participantId);
    if (idx != -1) {
      final thread = chatThreads[idx];
      final updated = ChatThread(
        participantId: thread.participantId,
        participantName: thread.participantName,
        participantRole: thread.participantRole,
        participantDept: thread.participantDept,
        messages: [...thread.messages, newMsg],
      );
      chatThreads = [
        ...chatThreads.sublist(0, idx),
        updated,
        ...chatThreads.sublist(idx + 1),
      ];
    } else {
      // Create a new thread for staff not in list yet
      final staff = staffList.firstWhere(
        (s) => s.id == participantId,
        orElse: () => Staff(
          id: participantId,
          name: 'Unknown',
          email: '',
          phoneNumber: '',
          department: '',
          role: '',
          joinDate: '',
          status: 'active',
          onLeaveToday: false,
          designation: '',
          workMode: 'Office',
        ),
      );
      chatThreads = [
        ChatThread(
          participantId: participantId,
          participantName: staff.name,
          participantRole: staff.designation,
          participantDept: staff.department,
          messages: [newMsg],
        ),
        ...chatThreads,
      ];
    }
    notifyListeners();
  }

  void markThreadAsRead(String participantId) {
    final idx = chatThreads.indexWhere((t) => t.participantId == participantId);
    if (idx == -1) return;
    final thread = chatThreads[idx];
    final updatedMessages = thread.messages
        .map((m) => m.senderId != 'admin_1' ? m.copyWith(isRead: true) : m)
        .toList();
    final updated = ChatThread(
      participantId: thread.participantId,
      participantName: thread.participantName,
      participantRole: thread.participantRole,
      participantDept: thread.participantDept,
      messages: updatedMessages,
    );
    chatThreads = [
      ...chatThreads.sublist(0, idx),
      updated,
      ...chatThreads.sublist(idx + 1),
    ];
    notifyListeners();
  }

  int get totalUnreadMessages {
    return departmentChatThreads.fold(0, (sum, d) => sum + d.unreadCount);
  }

  // --- Filter Updaters ---
  void setDashboardFilter(String filter) {
    dashboardFilter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  void setLeaveSearchQuery(String query) {
    leaveSearchQuery = query;
    leavesPage = 1;
    notifyListeners();
    if (hasLoadedApiLeaves) {
      final q = query.trim();
      if (q.startsWith('EMP') || q.length == 24 || q.isEmpty) {
        loadLeaves(page: 1);
      }
    }
  }

  void setLeaveStatusFilter(String status) {
    leaveFilterOnLeaveToday = false;
    leaveStatusFilter = status;
    leavesPage = 1;
    notifyListeners();
    if (hasLoadedApiLeaves) {
      loadLeaves(page: 1);
    }
  }

  void toggleLeaveFilterOnLeaveToday() {
    leaveFilterOnLeaveToday = !leaveFilterOnLeaveToday;
    if (leaveFilterOnLeaveToday) {
      if (leaveStatusFilter != 'all' && leaveStatusFilter != 'Approved') {
        leaveStatusFilter = 'all';
      }
    }
    leavesPage = 1;
    notifyListeners();
    if (hasLoadedApiLeaves) {
      loadLeaves(page: 1);
    }
  }

  void setLeaveDeptFilter(String dept) {
    leaveDeptFilter = dept;
    notifyListeners();
  }

  void setLeaveTypeFilter(String type) {
    leaveTypeFilter = type;
    leavesPage = 1;
    notifyListeners();
    if (hasLoadedApiLeaves) {
      loadLeaves(page: 1);
    }
  }

  void setLeaveDateRange(DateTime? start, DateTime? end) {
    leaveStartDate = start;
    leaveEndDate = end;
    leavesPage = 1;
    notifyListeners();
    if (hasLoadedApiLeaves) {
      loadLeaves(page: 1);
    }
  }

  Future<void> loadLeaves({int? page}) async {
    final targetPage = page ?? leavesPage;
    leavesPage = targetPage;
    isLeavesLoading = true;
    leavesError = null;
    notifyListeners();

    final currentVersion = ++_leavesRequestVersion;

    try {
      String? backendStatus;
      if (leaveFilterOnLeaveToday) {
        backendStatus = 'APPROVED';
      } else if (leaveStatusFilter == 'Pending') {
        backendStatus = 'PENDING';
      } else if (leaveStatusFilter == 'Approved') {
        backendStatus = 'APPROVED';
      } else if (leaveStatusFilter == 'Rejected') {
        backendStatus = 'REJECTED';
      }

      String? backendType;
      if (leaveTypeFilter == 'Casual') {
        backendType = 'CASUAL';
      } else if (leaveTypeFilter == 'Medical') {
        backendType = 'SICK';
      } else if (leaveTypeFilter == 'Earned') {
        backendType = 'ANNUAL';
      }

      String? startDate;
      String? endDate;
      if (leaveStartDate != null) {
        startDate = leaveStartDate!.toIso8601String().split('T')[0];
      }
      if (leaveEndDate != null) {
        endDate = leaveEndDate!.toIso8601String().split('T')[0];
      }

      String? empIdQuery;
      if (leaveSearchQuery.isNotEmpty) {
        final q = leaveSearchQuery.trim();
        if (q.startsWith('EMP') || q.length == 24) {
          empIdQuery = q;
        }
      }

      final result = await ApiService.getLeavesPage(
        page: targetPage,
        limit: leavesLimit,
        employeeId: empIdQuery,
        status: backendStatus,
        leaveType: backendType,
        startDate: startDate,
        endDate: endDate,
      );

      if (_leavesRequestVersion != currentVersion) return;

      apiLeaveRecords = result.leaves;
      leavesTotal = result.total;
      leavesTotalPages = result.totalPages;
      leavesPage = result.page;
      hasLoadedApiLeaves = true;
      leavesError = null;
      isLeavesLoading = false;
      notifyListeners();
    } catch (e) {
      if (_leavesRequestVersion != currentVersion) return;
      isLeavesLoading = false;
      leavesError = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  void setLeavesPage(int page) {
    if (page < 1 || (leavesTotalPages > 0 && page > leavesTotalPages)) {
      return;
    }
    loadLeaves(page: page);
  }

  Future<void> fetchLeaveMetrics() async => _fetchLeaveMetrics();

  /// Fetches company-wide leave status counts in the background.
  /// These are stored separately and are NEVER overwritten by table-level
  /// status filters -- keeping metric cards stable while the table is filtered.
  Future<void> _fetchLeaveMetrics() async {
    final currentVersion = ++_leaveMetricsRequestVersion;
    try {
      final today = DateTime.now();

      final results = await Future.wait([
        ApiService.getLeavesPage(status: 'PENDING', limit: 1, page: 1),
        ApiService.getLeavesPage(status: 'APPROVED', limit: 1, page: 1),
        ApiService.getLeavesPage(status: 'REJECTED', limit: 1, page: 1),
        // Fetch approved leaves to compute on-leave-today locally.
        // The backend startDate/endDate filter does not support range-overlap
        // queries (startDate <= today <= endDate), so we compute it client-side.
        ApiService.getLeavesPage(status: 'APPROVED', limit: 100, page: 1),
      ]);

      if (_leaveMetricsRequestVersion != currentVersion) return;

      companyPendingLeavesCount = results[0].total;
      companyApprovedLeavesCount = results[1].total;
      companyRejectedLeavesCount = results[2].total;

      // Compute on-leave-today: approved leaves whose date window covers today.
      final approvedPage = results[3];
      companyOnLeaveTodayCount = approvedPage.leaves.where((l) {
        try {
          final start = DateTime.parse(l.fromDate);
          final end = DateTime.parse(l.toDate);
          final todayDate = DateTime(today.year, today.month, today.day);
          final startDate = DateTime(start.year, start.month, start.day);
          final endDate = DateTime(end.year, end.month, end.day);
          return !todayDate.isBefore(startDate) && !todayDate.isAfter(endDate);
        } catch (_) {
          return false;
        }
      }).length;

      _hasLoadedLeaveMetrics = true;
      notifyListeners();
    } catch (_) {
      // Silently swallow -- metric cards keep their last known value.
    }
  }

  void setAttendanceSearchQuery(String query) {
    attendanceSearchQuery = query;
    notifyListeners();
    _attendanceSearchTimer?.cancel();
    if (hasLoadedApiAttendance) {
      _attendanceSearchTimer = Timer(const Duration(milliseconds: 350), () {
        attendancePage = 1;
        loadAttendance(page: 1);
      });
    }
  }

  void setAttendanceDeptFilter(String dept) {
    attendanceDeptFilter = dept;
    attendancePage = 1;
    notifyListeners();
    if (hasLoadedApiAttendance) loadAttendance(page: 1);
  }

  Future<void> loadLateArrivalsSummary({DateTime? date}) async {
    final requestVersion = ++_lateArrivalsRequestVersion;
    isLateArrivalsLoading = true;
    lateArrivalsError = null;
    notifyListeners();
    try {
      final response = await ApiService.getDashboardMetrics(
        date: date == null ? null : _attendanceDateKey(date),
      );
      final data = response['data'];
      if (data is! Map<String, dynamic> ||
          data['lateArrivals'] is! num ||
          data['todayPresent'] is! num) {
        throw const FormatException(
            'Dashboard response is missing numeric lateArrivals or todayPresent.');
      }
      if (_lateArrivalsRequestVersion != requestVersion) return;
      _lateArrivalsSummaryCount = (data['lateArrivals'] as num).toInt();
      _presentTodaySummaryCount = (data['todayPresent'] as num).toInt();
      // Preserve existing dashboard values if this response omits other fields.
      apiDashboardMetrics = {...?apiDashboardMetrics, ...data};
      hasLoadedApiDashboard = true;
      isLateArrivalsLoading = false;
      lateArrivalsError = null;
    } catch (e) {
      if (_lateArrivalsRequestVersion != requestVersion) return;
      isLateArrivalsLoading = false;
      lateArrivalsError = e.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
  }

  Future<void> loadAttendance({int? page}) async {
    final targetPage = page ?? attendancePage;
    attendancePage = targetPage;
    isAttendanceLoading = true;
    attendanceError = null;
    notifyListeners();

    final currentVersion = ++_attendanceRequestVersion;

    try {
      String? backendStatus;
      if (attendanceStatusFilter == 'Present') {
        backendStatus = 'PRESENT';
      } else if (attendanceStatusFilter == 'Checked Out') {
        backendStatus = 'PRESENT';
      } else if (attendanceStatusFilter == 'Late') {
        backendStatus = 'LATE';
      } else if (attendanceStatusFilter == 'Absent') {
        backendStatus = 'ABSENT';
      } else if (attendanceStatusFilter == 'On Leave') {
        backendStatus = 'LEAVE';
      }

      String? startDate;
      String? endDate;
      if (attendanceSelectedDate != null) {
        final dateStr = _attendanceDateKey(attendanceSelectedDate!);
        startDate = dateStr;
        endDate = dateStr;
      } else if (attendanceTab == 'today') {
        final todayStr = _attendanceDateKey(_kolkataToday());
        startDate = todayStr;
        endDate = todayStr;
      } else if (attendanceTab == 'history') {
        if (attendanceDateRangeStart != null ||
            attendanceDateRangeEnd != null) {
          startDate = attendanceDateRangeStart == null
              ? null
              : _attendanceDateKey(attendanceDateRangeStart!);
          endDate = attendanceDateRangeEnd == null
              ? null
              : _attendanceDateKey(attendanceDateRangeEnd!);
        }
      }

      String? empIdQuery;
      if (attendanceSearchQuery.isNotEmpty) {
        final q = attendanceSearchQuery.trim();
        if (q.startsWith('EMP') || q.length == 24) {
          empIdQuery = q;
        }
      }

      final result = await ApiService.getAttendancePage(
        page: targetPage,
        limit: attendanceLimit,
        employeeId: empIdQuery,
        department: attendanceDeptFilter,
        search: attendanceSearchQuery.trim().isEmpty
            ? null
            : attendanceSearchQuery.trim(),
        workMode: attendanceWorkModeFilter,
        startDate: startDate,
        endDate: endDate,
        status: backendStatus,
      );

      if (_attendanceRequestVersion != currentVersion) return;

      apiAttendanceRecords = result.records;
      attendanceTotal = result.total;
      attendanceTotalPages = result.totalPages;
      attendancePage = result.page;
      hasLoadedApiAttendance = true;
      attendanceError = null;
      isAttendanceLoading = false;
      notifyListeners();
    } catch (e) {
      if (_attendanceRequestVersion != currentVersion) return;
      isAttendanceLoading = false;
      attendanceError = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  void setAttendancePage(int page) {
    if (page < 1 || (attendanceTotalPages > 0 && page > attendanceTotalPages)) {
      return;
    }
    loadAttendance(page: page);
  }

  void setAttendanceStatusFilter(String status) {
    attendanceStatusFilter = status;
    attendancePage = 1;
    notifyListeners();
    if (hasLoadedApiAttendance) {
      loadAttendance(page: 1);
    }
  }

  void setAttendanceWorkModeFilter(String mode) {
    attendanceWorkModeFilter = mode;
    attendancePage = 1;
    notifyListeners();
    if (hasLoadedApiAttendance) loadAttendance(page: 1);
  }

  void setAttendanceTab(String tab) {
    attendanceTab = tab;
    if (tab == 'today') {
      attendanceSelectedDate = null;
      attendanceDateRangeStart = null;
      attendanceDateRangeEnd = null;
    }
    attendancePage = 1;
    notifyListeners();
    if (hasLoadedApiAttendance) {
      loadAttendance(page: 1);
    }
    if (hasLoadedApiDashboard) {
      loadLateArrivalsSummary(date: attendanceSelectedDate);
    }
  }

  void setAttendanceSelectedDate(DateTime? date) {
    attendanceSelectedDate = date;
    attendancePage = 1;
    notifyListeners();
    if (hasLoadedApiAttendance) {
      loadAttendance(page: 1);
    }
    if (hasLoadedApiDashboard) {
      loadLateArrivalsSummary(date: date);
    }
  }

  void setAttendanceDateRange(DateTime? start, DateTime? end) {
    attendanceDateRangeStart = start;
    attendanceDateRangeEnd = end;
    attendancePage = 1;
    notifyListeners();
    if (hasLoadedApiAttendance) {
      loadAttendance(page: 1);
    }
  }

  void setEmployeeSearchQuery(String q) {
    employeeSearchQuery = q;
    notifyListeners();
    _scheduleEmployeeDirectoryLoad();
  }

  void setEmployeeDeptFilter(String dept) {
    employeeDeptFilter = dept;
    notifyListeners();
    _scheduleEmployeeDirectoryLoad(immediate: true);
  }

  void setEmployeeStatusFilter(String status) {
    employeeStatusFilter = status;
    notifyListeners();
    _scheduleEmployeeDirectoryLoad(immediate: true);
  }

  // --- Computed Getters for Metrics ---
  DashboardMetrics get dashboardMetrics {
    if (hasLoadedApiDashboard && apiDashboardMetrics != null) {
      final total = apiDashboardMetrics!['totalEmployees'] as int? ?? 0;
      final active = apiDashboardMetrics!['activeEmployees'] as int? ?? 0;
      final inactive = apiDashboardMetrics!['inactiveEmployees'] as int? ?? 0;
      final present = apiDashboardMetrics!['todayPresent'] as int? ?? 0;
      final pendingLeaves = apiDashboardMetrics!['pendingLeaves'] as int? ?? 0;
      final notCheckedIn = active - present > 0 ? active - present : 0;

      return DashboardMetrics(
        presentToday: present,
        lateCheckIns:
            (apiDashboardMetrics!['lateArrivals'] as num?)?.toInt() ?? 0,
        openTasks: hasLoadedApiTasks
            ? apiTasksList.where((t) => t.status != 'done').length
            : 0,
        onLeaveToday: 0,
        resignedLast30Days: inactive,
        totalStaff: total,
        activeStaff: active,
        pendingLeaves: pendingLeaves,
        notCheckedIn: notCheckedIn,
      );
    }

    if (_isTestModeSeeded) {
      final activeCount = staffList.where((s) => s.status == 'active').length;
      final totalCount = staffList.length;
      final presentToday =
          attendanceList.where((a) => a.status != 'Absent').length;
      final lateCheckIns = attendanceList.where((a) => a.isLate).length;
      final openTasks = tasksList.where((t) => t.status != 'done').length;
      final onLeaveToday = staffList.where((s) => s.onLeaveToday).length;
      final resignedCount =
          staffList.where((s) => s.status == 'resigned').length;
      final pendingLeaves = leaveRequests
          .where((r) => r.status.toLowerCase() == 'pending')
          .length;
      final notCheckedIn = activeCount - presentToday - onLeaveToday > 0
          ? activeCount - presentToday - onLeaveToday
          : 0;

      return DashboardMetrics(
        presentToday: presentToday > 0 ? presentToday : attendanceList.length,
        lateCheckIns: lateCheckIns > 0
            ? lateCheckIns
            : attendanceList.where((a) => a.isLate).length,
        openTasks: openTasks,
        onLeaveToday: onLeaveToday,
        resignedLast30Days: resignedCount,
        totalStaff: totalCount,
        activeStaff: activeCount,
        pendingLeaves: pendingLeaves,
        notCheckedIn: notCheckedIn,
      );
    }

    return DashboardMetrics(
      presentToday: 0,
      lateCheckIns: 0,
      openTasks: 0,
      onLeaveToday: 0,
      resignedLast30Days: 0,
      totalStaff: 0,
      activeStaff: 0,
      pendingLeaves: 0,
      notCheckedIn: 0,
    );
  }

  // --- Filtered Getters ---
  List<Staff> get filteredStaffList {
    final list = (hasLoadedApiEmployees || ApiService.hasToken)
        ? (employeeDirectory.isNotEmpty ? employeeDirectory : staffList)
        : (_isTestModeSeeded
            ? staffList
            : (employeeDirectory.isNotEmpty ? employeeDirectory : staffList));
    return list.where((s) {
      final matchesQuery = searchQuery.isEmpty ||
          s.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          s.email.toLowerCase().contains(searchQuery.toLowerCase());

      bool matchesDashboard = true;
      switch (dashboardFilter) {
        case 'active':
          matchesDashboard = s.status == 'active';
          break;
        case 'present':
          matchesDashboard =
              (hasLoadedApiAttendance ? apiAttendanceRecords : attendanceList)
                  .any((a) => a.staffId == s.id);
          break;
        case 'leave':
          matchesDashboard = s.onLeaveToday;
          break;
        case 'late':
          matchesDashboard =
              (hasLoadedApiAttendance ? apiAttendanceRecords : attendanceList)
                  .any((a) => a.staffId == s.id && a.isLate);
          break;
        case 'tasks':
          matchesDashboard = (hasLoadedApiTasks ? apiTasksList : tasksList)
              .any((t) => t.staffId == s.id && t.status != 'done');
          break;
        case 'resigned':
          matchesDashboard = s.status == 'resigned';
          break;
      }

      return matchesQuery && matchesDashboard;
    }).toList();
  }

  List<Staff> get filteredEmployeeList {
    return employeeDirectory;
  }

  List<LeaveRequest> get filteredLeaveRequests {
    if (hasLoadedApiLeaves) {
      final sourceList = apiLeaveRecords;
      return sourceList.where((r) {
        final matchesQuery = leaveSearchQuery.isEmpty ||
            r.employeeName
                .toLowerCase()
                .contains(leaveSearchQuery.toLowerCase()) ||
            r.employeeEmail
                .toLowerCase()
                .contains(leaveSearchQuery.toLowerCase()) ||
            r.staffId.toLowerCase().contains(leaveSearchQuery.toLowerCase()) ||
            r.reason.toLowerCase().contains(leaveSearchQuery.toLowerCase());

        final matchesStatus = leaveStatusFilter == 'all' ||
            r.status.toLowerCase() == leaveStatusFilter.toLowerCase();
        final matchesDept = leaveDeptFilter == 'all' ||
            r.department.toLowerCase() == leaveDeptFilter.toLowerCase();
        final matchesType = leaveTypeFilter == 'all' ||
            r.leaveType.toLowerCase() == leaveTypeFilter.toLowerCase();

        bool matchesToday = true;
        if (leaveFilterOnLeaveToday) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          try {
            final start = DateTime.parse(r.fromDate);
            final end = DateTime.parse(r.toDate);
            final s = DateTime(start.year, start.month, start.day);
            final e = DateTime(end.year, end.month, end.day);
            matchesToday = r.status.toLowerCase() == 'approved' &&
                !today.isBefore(s) &&
                !today.isAfter(e);
          } catch (_) {
            matchesToday = false;
          }
        }

        return matchesQuery &&
            matchesStatus &&
            matchesDept &&
            matchesType &&
            matchesToday;
      }).toList();
    }

    if (!_isTestModeSeeded || leavesError != null || ApiService.hasToken) {
      return const [];
    }

    final sourceList = leaveRequests;
    return sourceList.where((r) {
      final matchesQuery = leaveSearchQuery.isEmpty ||
          r.employeeName
              .toLowerCase()
              .contains(leaveSearchQuery.toLowerCase()) ||
          r.employeeEmail
              .toLowerCase()
              .contains(leaveSearchQuery.toLowerCase()) ||
          r.staffId.toLowerCase().contains(leaveSearchQuery.toLowerCase()) ||
          r.reason.toLowerCase().contains(leaveSearchQuery.toLowerCase());

      final matchesStatus = leaveStatusFilter == 'all' ||
          r.status.toLowerCase() == leaveStatusFilter.toLowerCase();
      final matchesDept = leaveDeptFilter == 'all' ||
          r.department.toLowerCase() == leaveDeptFilter.toLowerCase();
      final matchesType = leaveTypeFilter == 'all' ||
          r.leaveType.toLowerCase() == leaveTypeFilter.toLowerCase();

      bool matchesDate = true;
      if (leaveStartDate != null) {
        try {
          final start = DateTime.parse(r.fromDate);
          if (start.isBefore(leaveStartDate!)) matchesDate = false;
        } catch (_) {}
      }
      if (leaveEndDate != null) {
        try {
          final end = DateTime.parse(r.toDate);
          if (end.isAfter(leaveEndDate!)) matchesDate = false;
        } catch (_) {}
      }

      bool matchesToday = true;
      if (leaveFilterOnLeaveToday) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        try {
          final start = DateTime.parse(r.fromDate);
          final end = DateTime.parse(r.toDate);
          final s = DateTime(start.year, start.month, start.day);
          final e = DateTime(end.year, end.month, end.day);
          matchesToday = r.status.toLowerCase() == 'approved' &&
              !today.isBefore(s) &&
              !today.isAfter(e);
        } catch (_) {
          matchesToday = false;
        }
      }

      return matchesQuery &&
          matchesStatus &&
          matchesDept &&
          matchesType &&
          matchesDate &&
          matchesToday;
    }).toList();
  }

  /// Returns the company-wide pending leave count.
  /// Always reflects ALL pending leaves, not just the current filtered page.
  int get pendingLeavesCount {
    if (_hasLoadedLeaveMetrics) return companyPendingLeavesCount;
    if (hasLoadedApiLeaves) {
      return apiLeaveRecords
          .where((r) => r.status.toLowerCase() == 'pending')
          .length;
    }
    if (_isTestModeSeeded && !ApiService.hasToken && leavesError == null) {
      return leaveRequests
          .where((r) => r.status.toLowerCase() == 'pending')
          .length;
    }
    return 0;
  }

  /// Returns the company-wide approved leave count.
  int get approvedLeavesCount {
    if (_hasLoadedLeaveMetrics) return companyApprovedLeavesCount;
    if (hasLoadedApiLeaves) {
      return apiLeaveRecords
          .where((r) => r.status.toLowerCase() == 'approved')
          .length;
    }
    if (_isTestModeSeeded && !ApiService.hasToken && leavesError == null) {
      return leaveRequests
          .where((r) => r.status.toLowerCase() == 'approved')
          .length;
    }
    return 0;
  }

  /// Returns the company-wide rejected leave count.
  int get rejectedLeavesCount {
    if (_hasLoadedLeaveMetrics) return companyRejectedLeavesCount;
    if (hasLoadedApiLeaves) {
      return apiLeaveRecords
          .where((r) => r.status.toLowerCase() == 'rejected')
          .length;
    }
    if (_isTestModeSeeded && !ApiService.hasToken && leavesError == null) {
      return leaveRequests
          .where((r) => r.status.toLowerCase() == 'rejected')
          .length;
    }
    return 0;
  }

  /// Number of employees on approved leave today.
  /// Uses the stable metric count computed by _fetchLeaveMetrics().
  int get onLeaveTodayCount {
    if (_hasLoadedLeaveMetrics) return companyOnLeaveTodayCount;
    // Fall back to employee directory onLeaveToday flag while metrics load.
    return (hasLoadedApiEmployees
            ? employeeDirectory
            : (_isTestModeSeeded ? staffList : <Staff>[]))
        .where((s) => s.onLeaveToday)
        .length;
  }

  List<Attendance> get filteredAttendanceList {
    if (hasLoadedApiAttendance) {
      final sourceList = apiAttendanceRecords;
      return sourceList.where((a) {
        final matchesQuery = attendanceSearchQuery.isEmpty ||
            a.employeeName
                .toLowerCase()
                .contains(attendanceSearchQuery.toLowerCase()) ||
            a.department
                .toLowerCase()
                .contains(attendanceSearchQuery.toLowerCase()) ||
            a.staffId
                .toLowerCase()
                .contains(attendanceSearchQuery.toLowerCase());

        final matchesDept = attendanceDeptFilter == 'all' ||
            a.department.toLowerCase() == attendanceDeptFilter.toLowerCase();

        bool matchesStatus = true;
        if (attendanceStatusFilter != 'all') {
          matchesStatus =
              a.status.toLowerCase() == attendanceStatusFilter.toLowerCase();
        }

        bool matchesWorkMode = true;
        if (attendanceWorkModeFilter != 'all') {
          matchesWorkMode = a.workMode.toLowerCase() ==
              attendanceWorkModeFilter.toLowerCase();
        }

        return matchesQuery && matchesDept && matchesStatus && matchesWorkMode;
      }).toList();
    }

    if (!_isTestModeSeeded || attendanceError != null || ApiService.hasToken) {
      return const [];
    }

    final sourceList = attendanceList;
    return sourceList.where((a) {
      final matchesQuery = attendanceSearchQuery.isEmpty ||
          a.employeeName
              .toLowerCase()
              .contains(attendanceSearchQuery.toLowerCase()) ||
          a.department
              .toLowerCase()
              .contains(attendanceSearchQuery.toLowerCase()) ||
          a.staffId.toLowerCase().contains(attendanceSearchQuery.toLowerCase());

      final matchesDept = attendanceDeptFilter == 'all' ||
          a.department.toLowerCase() == attendanceDeptFilter.toLowerCase();

      bool matchesStatus = true;
      if (attendanceStatusFilter != 'all') {
        matchesStatus =
            a.status.toLowerCase() == attendanceStatusFilter.toLowerCase();
      }

      bool matchesWorkMode = true;
      if (attendanceWorkModeFilter != 'all') {
        matchesWorkMode =
            a.workMode.toLowerCase() == attendanceWorkModeFilter.toLowerCase();
      }

      bool matchesDate = true;
      if (attendanceSelectedDate != null) {
        final dateStr = attendanceSelectedDate!.toIso8601String().split('T')[0];
        matchesDate = a.date == dateStr;
      }

      return matchesQuery &&
          matchesDept &&
          matchesStatus &&
          matchesWorkMode &&
          matchesDate;
    }).toList();
  }

  int get presentTodayCount {
    final summaryCount =
        _presentTodaySummaryCount ?? _dashboardCount('todayPresent');
    if (summaryCount != null) return summaryCount;
    if (!_isTestModeSeeded || attendanceError != null || ApiService.hasToken) {
      return 0;
    }
    return attendanceList.where((a) => a.status != 'Absent').length;
  }

  int get lateTodayCount {
    final summaryCount =
        _lateArrivalsSummaryCount ?? _dashboardCount('lateArrivals');
    if (summaryCount != null) return summaryCount;
    if (!_isTestModeSeeded || attendanceError != null || ApiService.hasToken) {
      return 0;
    }
    return attendanceList.where((a) => a.isLate).length;
  }

  // --- Payroll Actions & Loaders (Screen 8 API Integration) ---

  void setPayrollMonth(int month) {
    if (payrollMonth == month) return;
    payrollMonth = month;
    payrollPage = 1;
    notifyListeners();
    if (hasLoadedApiPayroll) {
      loadPayroll();
    }
  }

  void setPayrollYear(int year) {
    if (payrollYear == year) return;
    payrollYear = year;
    payrollPage = 1;
    notifyListeners();
    if (hasLoadedApiPayroll) {
      loadPayroll();
    }
  }

  void setPayrollDepartment(String dept) {
    if (payrollDepartment == dept) return;
    payrollDepartment = dept;
    payrollPage = 1;
    notifyListeners();
    if (hasLoadedApiPayroll) {
      loadPayroll();
    }
  }

  void setPayrollSearchQuery(String query) {
    payrollSearchQuery = query;
    payrollPage = 1;
    notifyListeners();
    if (hasLoadedApiPayroll) {
      loadPayroll();
    }
  }

  void setPayrollPage(int page) {
    if (page < 1 || (payrollTotalPages > 0 && page > payrollTotalPages)) {
      return;
    }
    loadPayroll(page: page);
  }

  Future<void> loadPayroll({int? page}) async {
    final targetPage = page ?? payrollPage;
    payrollPage = targetPage;
    isPayrollLoading = true;
    payrollError = null;
    notifyListeners();

    final currentVersion = ++_payrollRequestVersion;

    try {
      final summaryFuture = ApiService.getPayrollSummary(
        month: payrollMonth,
        year: payrollYear,
        department: payrollDepartment != 'all' ? payrollDepartment : null,
      );

      final employeesFuture = ApiService.getEmployeesPayroll(
        month: payrollMonth,
        year: payrollYear,
        department: payrollDepartment != 'all' ? payrollDepartment : null,
        search: payrollSearchQuery.trim().isNotEmpty
            ? payrollSearchQuery.trim()
            : null,
        page: targetPage,
        limit: payrollLimit,
      );

      final results = await Future.wait([summaryFuture, employeesFuture]);

      if (_payrollRequestVersion != currentVersion) return;

      apiPayrollSummary = results[0] as PayrollSummary;
      final employeesPage = results[1] as EmployeePayrollPage;

      apiPayrollRecords = employeesPage.records;
      payrollTotal = employeesPage.total;
      payrollTotalPages = employeesPage.totalPages;
      payrollPage = employeesPage.page;
      hasLoadedApiPayroll = true;
      payrollError = null;
      isPayrollLoading = false;
      notifyListeners();
    } catch (e) {
      if (_payrollRequestVersion != currentVersion) return;
      isPayrollLoading = false;
      payrollError = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  List<EmployeePayrollRecord> get filteredPayrollRecords {
    if (hasLoadedApiPayroll) {
      return apiPayrollRecords;
    }
    if (!_isTestModeSeeded || payrollError != null || ApiService.hasToken) {
      return const [];
    }

    // Fallback calculation for explicitly seeded mock state in offline tests
    final daysInMonth = DateTime(payrollYear, payrollMonth + 1, 0).day;
    int techStandardWorkingDays = 0;
    int teleStandardWorkingDays = 0;

    for (int day = 1; day <= daysInMonth; day++) {
      final dt = DateTime(payrollYear, payrollMonth, day);
      if (dt.weekday >= DateTime.monday && dt.weekday <= DateTime.friday) {
        techStandardWorkingDays++;
      }
      if (dt.weekday >= DateTime.monday && dt.weekday <= DateTime.saturday) {
        teleStandardWorkingDays++;
      }
    }

    final filteredStaff = staffList.where((s) {
      if (payrollDepartment != 'all' &&
          s.department.toLowerCase() != payrollDepartment.toLowerCase()) {
        return false;
      }
      if (payrollSearchQuery.isNotEmpty) {
        final q = payrollSearchQuery.toLowerCase();
        return s.name.toLowerCase().contains(q) ||
            s.email.toLowerCase().contains(q) ||
            s.designation.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return filteredStaff.map((staff) {
      final isTech = staff.department.toLowerCase() == 'tech';
      final standardWorkingDays =
          isTech ? techStandardWorkingDays : teleStandardWorkingDays;

      final staffAttendance = attendanceList.where((a) {
        if (a.staffId != staff.id) return false;
        final parts = a.date.split('-');
        if (parts.length >= 2) {
          final y = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          return y == payrollYear && m == payrollMonth;
        }
        return false;
      }).toList();

      final actualPresentDays = staffAttendance
          .where((a) =>
              a.status.toLowerCase() == 'present' ||
              a.status.toLowerCase() == 'checked out' ||
              a.status.toLowerCase() == 'late')
          .length;

      final approvedLeaves = leaveRequests.where((l) {
        if (l.staffId != staff.id || l.status.toLowerCase() != 'approved') {
          return false;
        }
        final parts = l.fromDate.split('-');
        if (parts.length >= 2) {
          final y = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          return y == payrollYear && m == payrollMonth;
        }
        return false;
      }).fold<int>(0, (sum, item) => sum + item.daysCount);

      final paidLeaveAllowance = staff.paidLeaveAllowance;
      final paidLeaveDays = approvedLeaves > paidLeaveAllowance
          ? paidLeaveAllowance
          : approvedLeaves;
      final unpaidLeaveDays = approvedLeaves > paidLeaveAllowance
          ? approvedLeaves - paidLeaveAllowance
          : 0;

      int effectivePresent = actualPresentDays > 0
          ? actualPresentDays
          : (staff.status == 'active'
              ? (standardWorkingDays - approvedLeaves > 0
                  ? standardWorkingDays - approvedLeaves
                  : 0)
              : 0);

      final payableDays = effectivePresent + paidLeaveDays;
      final dailyRate =
          standardWorkingDays > 0 ? staff.salary / standardWorkingDays : 0.0;
      final salaryDeduction = unpaidLeaveDays * dailyRate;
      final netPay =
          (staff.salary - salaryDeduction).clamp(0.0, double.infinity);

      final nameParts = staff.name.split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      return EmployeePayrollRecord(
        id: staff.id,
        employeeId: staff.id,
        firstName: firstName,
        lastName: lastName,
        name: staff.name,
        department: staff.department,
        designation: staff.designation,
        status: staff.status.toUpperCase(),
        salary: staff.salary,
        salaryCurrency: staff.salaryCurrency,
        year: payrollYear,
        month: payrollMonth,
        standardWorkingDays: standardWorkingDays,
        presentDays: effectivePresent,
        approvedLeaves: approvedLeaves,
        paidLeaveDays: paidLeaveDays,
        unpaidLeaveDays: unpaidLeaveDays,
        payableDays: payableDays,
        grossSalary: staff.salary,
        dailyRate: dailyRate,
        deductions: salaryDeduction,
        netPay: netPay,
      );
    }).toList();
  }

  PayrollSummary get effectivePayrollSummary {
    if (payrollError != null && !hasLoadedApiPayroll) {
      return PayrollSummary(
        year: payrollYear,
        month: payrollMonth,
        department: payrollDepartment,
        totalEmployees: 0,
        totalPayrollExpenditure: 0.0,
        totalDeductions: 0.0,
        totalNetPayout: 0.0,
      );
    }
    if (hasLoadedApiPayroll && apiPayrollSummary != null) {
      return apiPayrollSummary!;
    }
    if (!_isTestModeSeeded) {
      return PayrollSummary(
        year: payrollYear,
        month: payrollMonth,
        department: payrollDepartment,
        totalEmployees: 0,
        totalPayrollExpenditure: 0.0,
        totalDeductions: 0.0,
        totalNetPayout: 0.0,
      );
    }

    final records = filteredPayrollRecords;
    double totalGross = 0.0;
    double totalDeductions = 0.0;
    double totalNet = 0.0;

    for (final r in records) {
      totalGross += r.grossSalary;
      totalDeductions += r.deductions;
      totalNet += r.netPay;
    }

    return PayrollSummary(
      year: payrollYear,
      month: payrollMonth,
      department: payrollDepartment,
      totalEmployees: records.length,
      totalPayrollExpenditure: totalGross,
      totalDeductions: totalDeductions,
      totalNetPayout: totalNet,
    );
  }

  // --- Reports & Analytics Actions & Loaders (Screen 12 API Integration) ---

  void setReportsDepartmentFilter(String dept) {
    if (reportsDepartmentFilter == dept) return;
    reportsDepartmentFilter = dept;
    notifyListeners();
    if (hasLoadedApiReports) {
      loadReports();
    }
  }

  void setReportsDateRange(DateTime? start, DateTime? end) {
    reportsStartDate = start;
    reportsEndDate = end;
    notifyListeners();
    if (hasLoadedApiReports) {
      loadReports();
    }
  }

  Future<void> loadReports() async {
    isReportsLoading = true;
    reportsError = null;
    notifyListeners();

    final currentVersion = ++_reportsRequestVersion;

    try {
      final startStr = reportsStartDate?.toIso8601String().split('T')[0];
      final endStr = reportsEndDate?.toIso8601String().split('T')[0];
      final deptStr =
          reportsDepartmentFilter != 'all' ? reportsDepartmentFilter : null;

      final results = await Future.wait([
        ApiService.getAttendanceReport(
          startDate: startStr,
          endDate: endStr,
          department: deptStr,
        ),
        ApiService.getLeavesReport(
          startDate: startStr,
          endDate: endStr,
        ),
      ]);

      if (_reportsRequestVersion != currentVersion) return;

      apiAttendanceReport = results[0] as AttendanceReportData;
      apiLeaveReport = results[1] as LeaveReportData;
      hasLoadedApiReports = true;
      reportsError = null;
      isReportsLoading = false;
      notifyListeners();
    } catch (e) {
      if (_reportsRequestVersion != currentVersion) return;
      isReportsLoading = false;
      reportsError = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  AttendanceReportData get effectiveAttendanceReport {
    if (hasLoadedApiReports && apiAttendanceReport != null) {
      return apiAttendanceReport!;
    }
    return const AttendanceReportData();
  }

  LeaveReportData get effectiveLeaveReport {
    if (hasLoadedApiReports && apiLeaveReport != null) {
      return apiLeaveReport!;
    }
    return const LeaveReportData();
  }
}

// ── Deletion result returned by provider deletion methods ─────────────────

enum _DeletionStatus { success, offlineSuccess, permissionDenied, failure }

class DeletionResult {
  final _DeletionStatus _status;
  final String message;

  const DeletionResult._(this._status, this.message);

  factory DeletionResult.success() =>
      const DeletionResult._(_DeletionStatus.success, 'Message deleted.');

  factory DeletionResult.offlineSuccess() => const DeletionResult._(
      _DeletionStatus.offlineSuccess,
      'Message hidden locally. Will sync when back online.');

  factory DeletionResult.permissionDenied(String msg) =>
      DeletionResult._(_DeletionStatus.permissionDenied, msg);

  factory DeletionResult.failure(String msg) =>
      DeletionResult._(_DeletionStatus.failure, msg);

  bool get isSuccess =>
      _status == _DeletionStatus.success ||
      _status == _DeletionStatus.offlineSuccess;

  bool get isPermissionDenied => _status == _DeletionStatus.permissionDenied;
  bool get isHardFailure => _status == _DeletionStatus.failure;
  bool get isOfflineSuccess => _status == _DeletionStatus.offlineSuccess;
}
