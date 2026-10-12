import '../models/staff.dart';
import '../models/hr_models.dart';

abstract class HrRepository {
  Future<Map<String, dynamic>> getDashboardMetrics();
  Future<List<Staff>> getEmployees();
  Future<bool> addEmployee(Map<String, dynamic> staffData);
  Future<bool> updateEmployee(String id, Map<String, dynamic> staffData);
  Future<bool> deleteEmployee(String id);
  
  Future<List<Attendance>> getAttendance();
  Future<List<Attendance>> getAttendanceForEmployee(String employeeId);
  
  Future<List<LeaveRequest>> getLeaves();
  Future<LeaveRequest?> getLeaveDetails(String id);
  Future<bool> approveLeave(String id);
  Future<bool> rejectLeave(String id);
  
  Future<Map<String, dynamic>> getAttendanceReport();
  Future<Map<String, dynamic>> getLeavesReport();
}
