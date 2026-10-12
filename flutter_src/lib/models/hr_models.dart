class Attendance {
  final String id;
  final String staffId;
  final String date;
  final String? checkInTime;
  final String? checkOutTime;
  final String workedDuration;
  final String breakDuration;
  final bool isLate;
  final String? checkInAt;
  final String? breakStartedAt;

  Attendance({
    required this.id,
    required this.staffId,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    required this.workedDuration,
    required this.breakDuration,
    required this.isLate,
    this.checkInAt,
    this.breakStartedAt,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['_id'] ?? json['id'] ?? '',
      staffId: json['staffId'] ?? '',
      date: json['date'] ?? '',
      checkInTime: json['checkInTime'],
      checkOutTime: json['checkOutTime'],
      workedDuration: json['workedDuration'] ?? '',
      breakDuration: json['breakDuration'] ?? '',
      isLate: json['isLate'] ?? false,
      checkInAt: json['checkInAt'],
      breakStartedAt: json['breakStartedAt'],
    );
  }
}

class Task {
  final String id;
  final String staffId;
  final String department;
  final String description;
  final String status;
  final String date;
  final String dueDate;

  Task({
    required this.id,
    required this.staffId,
    required this.department,
    required this.description,
    required this.status,
    required this.date,
    required this.dueDate,
  });
}

class LeaveRequest {
  final String id;
  final String staffId;
  final String fromDate;
  final String toDate;
  final String reason;
  String status;

  LeaveRequest({
    required this.id,
    required this.staffId,
    required this.fromDate,
    required this.toDate,
    required this.reason,
    required this.status,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['_id'] ?? json['id'] ?? '',
      staffId: json['staffId'] ?? '',
      fromDate: json['fromDate'] ?? '',
      toDate: json['toDate'] ?? '',
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'Pending',
    );
  }
}

class ResignationRequest {
  final String id;
  final String staffId;
  final String lastWorkingDate;
  final String reason;
  String status;

  ResignationRequest({
    required this.id,
    required this.staffId,
    required this.lastWorkingDate,
    required this.reason,
    required this.status,
  });
}

class DailyUpdate {
  final String id;
  final String staffId;
  final String date;
  final String updateText;

  DailyUpdate({
    required this.id,
    required this.staffId,
    required this.date,
    required this.updateText,
  });
}
