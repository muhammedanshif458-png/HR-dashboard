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
    String resolvedStaffId = '';
    if (json['staffId'] != null && json['staffId'].toString().isNotEmpty) {
      resolvedStaffId = json['staffId'].toString();
    } else if (json['employee'] is Map) {
      final empMap = json['employee'] as Map;
      resolvedStaffId = (empMap['_id'] ?? empMap['id'] ?? empMap['employeeId'] ?? '').toString();
    } else if (json['employee'] != null) {
      resolvedStaffId = json['employee'].toString();
    } else if (json['employeeId'] != null) {
      resolvedStaffId = json['employeeId'].toString();
    }

    String? parseTime(dynamic val) {
      if (val == null) return null;
      final str = val.toString();
      return str.isEmpty ? null : str;
    }

    final bool resolvedIsLate = json['isLate'] == true ||
        json['late'] == true ||
        json['status'] == 'LATE';

    String resolvedWorkedDuration = '';
    if (json['workedDuration'] != null && json['workedDuration'].toString().isNotEmpty) {
      resolvedWorkedDuration = json['workedDuration'].toString();
    } else if (json['workingHours'] != null) {
      resolvedWorkedDuration = '${json['workingHours']}h';
    }

    return Attendance(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      staffId: resolvedStaffId,
      date: (json['date'] ?? '').toString(),
      checkInTime: parseTime(json['checkInTime'] ?? json['checkIn'] ?? json['checkInAt']),
      checkOutTime: parseTime(json['checkOutTime'] ?? json['checkOut']),
      workedDuration: resolvedWorkedDuration,
      breakDuration: (json['breakDuration'] ?? '0m').toString(),
      isLate: resolvedIsLate,
      checkInAt: parseTime(json['checkInAt'] ?? json['checkIn']),
      breakStartedAt: parseTime(json['breakStartedAt']),
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

  factory DailyUpdate.fromJson(Map<String, dynamic> json) {
    String resolvedStaffId = '';
    if (json['staffId'] != null) {
      resolvedStaffId = json['staffId'].toString();
    } else if (json['employee'] is Map && json['employee']['_id'] != null) {
      resolvedStaffId = json['employee']['_id'].toString();
    } else if (json['employee'] is Map && json['employee']['id'] != null) {
      resolvedStaffId = json['employee']['id'].toString();
    }

    return DailyUpdate(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      staffId: resolvedStaffId,
      date: (json['date'] ?? '').toString(),
      updateText: (json['updateText'] ?? json['workUpdate'] ?? json['description'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'staffId': staffId,
      'date': date,
      'updateText': updateText,
    };
  }
}
