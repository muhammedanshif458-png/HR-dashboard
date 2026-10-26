import 'package:flutter/material.dart';
import '../models/staff.dart';
import '../models/hr_models.dart';
import '../services/api_service.dart'; // TODO: integrate real API later

class DashboardMetrics {
  final int presentToday;
  final int lateCheckIns;
  final int openTasks;
  final int onLeaveToday;
  final int resignedLast30Days;

  DashboardMetrics({
    required this.presentToday,
    required this.lateCheckIns,
    required this.openTasks,
    required this.onLeaveToday,
    required this.resignedLast30Days,
  });
}

class HRProvider extends ChangeNotifier {
  Staff? _currentUser;
  String _currentScreen = 'login';
  String? _selectedStaffId;
  
  Staff? get currentUser => _currentUser;
  String get currentScreen => _currentScreen;
  String? get selectedStaffId => _selectedStaffId;
  
  // Local Mock State
  List<Staff> staffList = [];
  List<Attendance> attendanceList = [];
  List<Task> tasksList = [];
  List<LeaveRequest> leaveRequests = [];
  List<ResignationRequest> resignationRequests = [];
  List<DailyUpdate> dailyUpdatesList = [];
  
  String dashboardFilter = 'all';
  String searchQuery = '';
  
  bool isApiStaffLoading = false;
  String apiStaffError = '';

  HRProvider() {
    _initMockData();
  }

  void _initMockData() {
    staffList = [
      Staff(id: 'staff_1', name: 'Anita Rao', email: 'anita@company.com', phoneNumber: '9876543210', department: 'Tech', role: 'HR Manager', joinDate: '2024-01-15', status: 'active', onLeaveToday: false),
      Staff(id: 'staff_2', name: 'Arjun Desai', email: 'arjun@company.com', phoneNumber: '9876543211', department: 'Tech', role: 'Staff', joinDate: '2024-02-01', status: 'active', onLeaveToday: false),
      Staff(id: 'staff_3', name: 'Neha Sharma', email: 'neha@company.com', phoneNumber: '9876543212', department: 'Telecalling', role: 'Staff', joinDate: '2024-03-10', status: 'active', onLeaveToday: false),
      Staff(id: 'staff_4', name: 'Vikram Singh', email: 'vikram@company.com', phoneNumber: '9876543213', department: 'Tech', role: 'Staff', joinDate: '2024-04-05', status: 'resigned', onLeaveToday: false),
      Staff(id: 'staff_5', name: 'Rahul Menon', email: 'rahul@company.com', phoneNumber: '9876543214', department: 'Telecalling', role: 'Staff', joinDate: '2024-05-20', status: 'active', onLeaveToday: true),
    ];

    attendanceList = [
      Attendance(id: 'att_1', staffId: 'staff_2', date: '2026-10-09', checkInTime: '09:00 AM', checkOutTime: '05:00 PM', workedDuration: '8h 00m', breakDuration: '1h 00m', isLate: false),
      Attendance(id: 'att_2', staffId: 'staff_3', date: '2026-10-09', checkInTime: '10:15 AM', checkOutTime: null, workedDuration: '5h 00m', breakDuration: '0h 00m', isLate: true),
    ];

    tasksList = [
      Task(id: 'task_1', staffId: 'staff_2', department: 'Tech', description: 'Complete Flutter UI Migration', status: 'in-progress', date: '2026-10-09', dueDate: '2026-10-15'),
      Task(id: 'task_2', staffId: 'staff_3', department: 'Telecalling', description: 'Follow up with 50 leads', status: 'pending', date: '2026-10-09', dueDate: '2026-10-10'),
    ];

    leaveRequests = [
      LeaveRequest(id: 'leave_1', staffId: 'staff_5', fromDate: '2026-10-09', toDate: '2026-10-09', reason: 'Medical appointment', status: 'Pending')
    ];

    dailyUpdatesList = [
      DailyUpdate(id: 'upd_1', staffId: 'staff_2', date: '2026-10-08', updateText: 'Finished phase 2 of the API integration.'),
    ];
  }

  Future<void> fetchDashboardData() async {
    isApiStaffLoading = true;
    apiStaffError = '';
    notifyListeners();
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // TODO: Integrate actual ApiService calls here when backend is ready
    // e.g., staffList = await ApiService.getEmployees();
    try {
      final updates = await ApiService.getDailyUpdates();
      if (updates.isNotEmpty) {
        dailyUpdatesList = updates;
      }
    } catch (_) {}
    
    isApiStaffLoading = false;
    notifyListeners();
  }

  Future<bool> addStaff(Map<String, dynamic> staffData) async {
    isApiStaffLoading = true;
    apiStaffError = '';
    notifyListeners();
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    // TODO: Replace with real API POST request later
    final newStaff = Staff(
      id: 'staff_${DateTime.now().millisecondsSinceEpoch}',
      name: staffData['name'] ?? '',
      email: staffData['email'] ?? '',
      phoneNumber: staffData['phoneNumber'] ?? '',
      department: staffData['department'] ?? 'Tech',
      role: 'Staff',
      joinDate: '2026-10-09',
      status: 'active',
      onLeaveToday: false,
    );
    staffList.add(newStaff);
    
    isApiStaffLoading = false;
    notifyListeners();
    return true; // Successfully added to local mock state
  }

  Future<bool> updateStaff(String id, Map<String, dynamic> staffData) async {
    isApiStaffLoading = true;
    apiStaffError = '';
    notifyListeners();
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    // TODO: Replace with real API PUT request later
    final index = staffList.indexWhere((s) => s.id == id);
    if (index != -1) {
      final oldStaff = staffList[index];
      staffList[index] = Staff(
        id: oldStaff.id,
        name: staffData['name'] ?? oldStaff.name,
        email: staffData['email'] ?? oldStaff.email,
        phoneNumber: staffData['phoneNumber'] ?? oldStaff.phoneNumber,
        department: staffData['department'] ?? oldStaff.department,
        role: oldStaff.role,
        joinDate: oldStaff.joinDate,
        status: oldStaff.status,
        onLeaveToday: oldStaff.onLeaveToday,
      );
    }
    
    isApiStaffLoading = false;
    notifyListeners();
    return true; // Successfully updated local mock state
  }

  Future<bool> deactivateStaff(String id) async {
    isApiStaffLoading = true;
    apiStaffError = '';
    notifyListeners();
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    // TODO: Replace with real API DELETE/PUT request later
    final index = staffList.indexWhere((s) => s.id == id);
    if (index != -1) {
      final oldStaff = staffList[index];
      staffList[index] = Staff(
        id: oldStaff.id,
        name: oldStaff.name,
        email: oldStaff.email,
        phoneNumber: oldStaff.phoneNumber,
        department: oldStaff.department,
        role: oldStaff.role,
        joinDate: oldStaff.joinDate,
        status: 'resigned',
        onLeaveToday: oldStaff.onLeaveToday,
      );
    }
    
    isApiStaffLoading = false;
    notifyListeners();
    return true; // Successfully deactivated in local mock state
  }

  void login(String email, String password) {
    _currentUser = Staff(
      id: 'admin_1', 
      name: 'Admin User', 
      email: email, 
      phoneNumber: '9876543210', 
      department: 'Tech', 
      role: 'HR Manager', 
      joinDate: '2024-01-01', 
      status: 'active', 
      onLeaveToday: false
    );
    _currentScreen = 'hr-dashboard';
    fetchDashboardData();
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    _currentScreen = 'login';
    _selectedStaffId = null;
    notifyListeners();
  }

  void setScreen(String screen) {
    _currentScreen = screen;
    notifyListeners();
  }

  void viewStaffProfile(String id) {
    _selectedStaffId = id;
    setScreen('staff-profile');
  }

  void setDashboardFilter(String filter) {
    dashboardFilter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  Future<void> reviewLeave(String id, bool approved) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // TODO: Integrate actual PUT API approve/reject later
    final index = leaveRequests.indexWhere((r) => r.id == id);
    if (index != -1) {
      leaveRequests[index].status = approved ? 'Approved' : 'Rejected';
      notifyListeners();
    }
  }

  DashboardMetrics get dashboardMetrics {
    int present = attendanceList.length;
    int late = attendanceList.where((a) => a.isLate).length;
    int tasks = tasksList.where((t) => t.status != 'done').length;
    int leave = staffList.where((s) => s.onLeaveToday).length;
    int resigned = staffList.where((s) => s.status == 'resigned').length;

    return DashboardMetrics(
      presentToday: present,
      lateCheckIns: late,
      openTasks: tasks,
      onLeaveToday: leave,
      resignedLast30Days: resigned,
    );
  }

  List<Staff> get filteredStaffList {
    return staffList.where((s) {
      final matchesQuery = searchQuery.isEmpty || 
          s.name.toLowerCase().contains(searchQuery.toLowerCase()) || 
          s.email.toLowerCase().contains(searchQuery.toLowerCase());
      
      bool matchesDashboard = true;
      switch (dashboardFilter) {
        case 'active': matchesDashboard = s.status == 'active'; break;
        case 'present': matchesDashboard = attendanceList.any((a) => a.staffId == s.id); break;
        case 'leave': matchesDashboard = s.onLeaveToday; break;
        case 'late': matchesDashboard = attendanceList.any((a) => a.staffId == s.id && a.isLate); break;
        case 'tasks': matchesDashboard = tasksList.any((t) => t.staffId == s.id && t.status != 'done'); break;
        case 'resigned': matchesDashboard = s.status == 'resigned'; break;
      }
      
      return matchesQuery && matchesDashboard;
    }).toList();
  }
}
