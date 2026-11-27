import 'staff.dart';
import '../utils/date_time_utils.dart';

class AttendanceBreakItem {
  final String id;
  final String breakType;
  final String? startTime;
  final String? endTime;
  final int durationMinutes;
  final String remarks;

  const AttendanceBreakItem({
    this.id = '',
    required this.breakType,
    this.startTime,
    this.endTime,
    this.durationMinutes = 0,
    this.remarks = '',
  });

  bool get isActive =>
      endTime == null ||
      endTime!.trim().isEmpty ||
      endTime!.trim() == '—' ||
      endTime!.trim().toLowerCase() == 'in progress' ||
      endTime!.trim().toLowerCase() == 'active';

  String get durationDisplay {
    if (isActive) return 'In Progress';
    if (durationMinutes <= 0) return '0m';
    final hours = durationMinutes ~/ 60;
    final mins = durationMinutes % 60;
    if (hours > 0 && mins > 0) return '${hours}h ${mins}m';
    if (hours > 0) return '${hours}h';
    return '${mins}m';
  }

  factory AttendanceBreakItem.fromJson(Map<String, dynamic> json) {
    final rawDuration = json['durationMinutes'] ?? json['duration'];
    final duration = rawDuration is num
        ? rawDuration.toInt()
        : int.tryParse(rawDuration?.toString() ?? '') ?? 0;

    return AttendanceBreakItem(
      id: (json['_id'] ?? json['id'] ?? json['breakId'] ?? '').toString(),
      breakType: (json['breakType'] ?? json['type'] ?? 'Break').toString(),
      startTime: json['startTime']?.toString() ?? json['breakStartedAt']?.toString(),
      endTime: json['endTime']?.toString(),
      durationMinutes: duration,
      remarks: json['remarks']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'breakType': breakType,
    'startTime': startTime,
    'endTime': endTime,
    'durationMinutes': durationMinutes,
    'remarks': remarks,
  };
}

class Attendance {
  final String id;
  final String staffId;
  final String employeeId;
  final String date;
  final String? checkInTime;
  final String? checkOutTime;
  final String workedDuration;
  final String breakDuration;
  final bool isLate;
  final int? minutesLate;
  final int? gracePeriodMinutes;
  final Map<String, dynamic>? scheduleSnapshot;
  final String? scheduledCheckIn;
  final String? scheduledCheckOut;
  final String? scheduleTimeZone;
  final bool scheduleConfigured;
  final String? checkInAt;
  final String? breakStartedAt;
  final String employeeName;
  final String department;
  final String designation;
  final String status;
  final String rawStatus;
  final String workMode;
  final String location;
  final String remarks;
  final double workingHours;
  final int totalBreakMinutes;
  final List<AttendanceBreakItem> breaks;
  final Map<String, dynamic>? activeBreak;
  final bool hasBreakDataContract;

  Attendance({
    required this.id,
    required this.staffId,
    this.employeeId = '',
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    required this.workedDuration,
    required this.breakDuration,
    required this.isLate,
    this.minutesLate,
    this.gracePeriodMinutes,
    this.scheduleSnapshot,
    this.scheduledCheckIn,
    this.scheduledCheckOut,
    this.scheduleTimeZone,
    this.scheduleConfigured = true,
    this.checkInAt,
    this.breakStartedAt,
    this.employeeName = '',
    this.department = '',
    this.designation = '',
    this.status = 'Present',
    this.rawStatus = 'PRESENT',
    this.workMode = '—',
    this.location = '—',
    this.remarks = '',
    this.workingHours = 0.0,
    this.totalBreakMinutes = 0,
    this.breaks = const [],
    this.activeBreak,
    this.hasBreakDataContract = true,
  });

  bool matchesStaff(Staff s) {
    if (employeeId.isNotEmpty && s.employeeId.isNotEmpty && employeeId.toLowerCase() == s.employeeId.toLowerCase()) {
      return true;
    }
    if (staffId.isNotEmpty && s.id.isNotEmpty && staffId == s.id) {
      return true;
    }
    return false;
  }

  bool get isOnBreak =>
      (activeBreak != null && activeBreak!.isNotEmpty) ||
      (breakStartedAt != null &&
          breakStartedAt!.trim().isNotEmpty &&
          breakStartedAt != '—') ||
      breaks.any((b) => b.isActive);

  AttendanceBreakItem? get currentActiveBreak {
    try {
      return breaks.firstWhere((b) => b.isActive);
    } catch (_) {
      if (activeBreak != null && activeBreak!.isNotEmpty) {
        return AttendanceBreakItem.fromJson(activeBreak!);
      }
      return null;
    }
  }

  factory Attendance.fromJson(Map<String, dynamic> json) {
    // 1. Employee IDs: Resolve both Database ID (staffId) and Business Employee ID (employeeId)
    String resolvedStaffId = '';
    String resolvedEmployeeId = '';

    // Business Employee ID (e.g. EMP1065): prefer top-level employeeId, then employee.employeeId
    if (json['employeeId'] != null && json['employeeId'].toString().trim().isNotEmpty) {
      resolvedEmployeeId = json['employeeId'].toString().trim();
    } else if (json['employee'] is Map) {
      final empMap = json['employee'] as Map;
      if (empMap['employeeId'] != null && empMap['employeeId'].toString().trim().isNotEmpty) {
        resolvedEmployeeId = empMap['employeeId'].toString().trim();
      }
    }

    // Database ID (staffId): prefer top-level staffId from backend, falling back to resolvedEmployeeId, then employee._id / employee.id
    if (json['staffId'] != null && json['staffId'].toString().trim().isNotEmpty) {
      resolvedStaffId = json['staffId'].toString().trim();
    } else if (json['employee'] is Map &&
        (json['employee'] as Map)['_id'] != null &&
        RegExp(r'^[0-9a-fA-F]{24}$').hasMatch((json['employee'] as Map)['_id'].toString().trim()) &&
        json['employeeId'] == null) {
      resolvedStaffId = (json['employee'] as Map)['_id'].toString().trim();
    } else if (resolvedEmployeeId.isNotEmpty) {
      resolvedStaffId = resolvedEmployeeId;
    } else if (json['employee'] is Map) {
      final empMap = json['employee'] as Map;
      if (empMap['_id'] != null && empMap['_id'].toString().trim().isNotEmpty) {
        resolvedStaffId = empMap['_id'].toString().trim();
      } else if (empMap['id'] != null && empMap['id'].toString().trim().isNotEmpty) {
        resolvedStaffId = empMap['id'].toString().trim();
      }
    } else if (json['employee'] != null && json['employee'] is String && json['employee'].toString().trim().isNotEmpty) {
      resolvedStaffId = json['employee'].toString().trim();
    }

    // Fallbacks if only one ID is present
    if (resolvedStaffId.isEmpty && resolvedEmployeeId.isNotEmpty) {
      resolvedStaffId = resolvedEmployeeId;
    }
    if (resolvedEmployeeId.isEmpty && resolvedStaffId.isNotEmpty) {
      resolvedEmployeeId = resolvedStaffId;
    }

    // 2. Department: prefer top-level department, with employee.department as a fallback
    String dept = '';
    if (json['department'] != null &&
        json['department'].toString().trim().isNotEmpty) {
      dept = json['department'].toString().trim();
    } else if (json['employee'] is Map) {
      dept = (json['employee'] as Map)['department']?.toString().trim() ?? '';
    }

    // 3. Employee Name: employee.firstName + employee.lastName
    String empName = '';
    if (json['employee'] is Map) {
      final emp = json['employee'] as Map;
      final fName = (emp['firstName'] ?? '').toString().trim();
      final lName = (emp['lastName'] ?? '').toString().trim();
      empName = '$fName $lName'.trim();
    }
    if (empName.isEmpty && json['employeeName'] != null) {
      empName = json['employeeName'].toString().trim();
    }

    // 4. Designation: employee.designation
    String designation = '';
    if (json['employee'] is Map &&
        (json['employee'] as Map)['designation'] != null) {
      designation = (json['employee'] as Map)['designation'].toString().trim();
    } else if (json['designation'] != null) {
      designation = json['designation'].toString().trim();
    }

    // 5. Work mode: employee.workMode (falling back to top-level workMode)
    String workMode = '—';
    if (json['workMode'] != null &&
        json['workMode'].toString().trim().isNotEmpty) {
      workMode = json['workMode'].toString().trim();
    } else if (json['employee'] is Map &&
        (json['employee'] as Map)['workMode'] != null) {
      workMode = (json['employee'] as Map)['workMode'].toString().trim();
    }
    if (workMode.isEmpty) workMode = '—';

    // 6. Check-in: checkInTime, falling back to checkIn or checkInAt
    String? checkInIso;
    if (json['checkIn'] != null) {
      checkInIso = json['checkIn'].toString();
    } else if (json['checkInAt'] != null) {
      checkInIso = json['checkInAt'].toString();
    }

    final rawCheckIn =
        (json['checkInTime'] ?? json['checkIn'] ?? json['checkInAt'])
            ?.toString();
    final resolvedCheckInTime = formatAttendanceTimeNullable(rawCheckIn);

    // 7. Check-out: checkOutTime, falling back to checkOut
    final rawCheckOut =
        (json['checkOutTime'] ?? json['checkOut'])?.toString();
    final resolvedCheckOutTime = (rawCheckOut?.trim() == 'Active')
        ? 'Active'
        : formatAttendanceTimeNullable(rawCheckOut);

    // 8. Late indicator: prefer isLate, falling back to late
    final bool resolvedIsLate = json['isLate'] == true ||
        json['late'] == true ||
        json['isLate']?.toString().toLowerCase() == 'true' ||
        json['late']?.toString().toLowerCase() == 'true' ||
        json['status']?.toString().toUpperCase() == 'LATE';

    // 9. Late minutes: minutesLate
    final rawMinutesLate = json['minutesLate'];
    final int? minutesLate = rawMinutesLate is num
        ? rawMinutesLate.toInt()
        : int.tryParse(rawMinutesLate?.toString() ?? '');

    // 10. Attendance status: top-level status
    final rawStatus = (json['status'] ?? 'PRESENT').toString().toUpperCase();
    String normStatus = 'Present';
    if (rawStatus == 'ABSENT') {
      normStatus = 'Absent';
    } else if (rawStatus == 'HALF_DAY') {
      normStatus = 'Half Day';
    } else if (rawStatus == 'LEAVE') {
      normStatus = 'On Leave';
    } else if (rawStatus == 'CHECKED_OUT' || rawStatus == 'CHECKED OUT') {
      normStatus = 'Checked Out';
    } else if (rawStatus == 'PRESENT') {
      if ((resolvedCheckOutTime != null && resolvedCheckOutTime.isNotEmpty) ||
          (rawCheckOut != null && rawCheckOut.isNotEmpty)) {
        normStatus = 'Checked Out';
      } else {
        normStatus = 'Present';
      }
    } else if (json['status'] != null) {
      normStatus = json['status'].toString();
    }
    if (resolvedIsLate) {
      normStatus = 'Late';
    }

    // 11. Working hours: workingHours
    double hours = 0.0;
    if (json['workingHours'] != null) {
      hours = (json['workingHours'] as num).toDouble();
    }

    // 12. Worked duration: workedDuration
    String worked = json['workedDuration']?.toString() ?? '';
    if (worked.isEmpty && hours > 0) {
      final h = hours.floor();
      final m = ((hours - h) * 60).round();
      worked = m > 0 ? '${h}h ${m}m' : '${h}h';
    }

    // 13. Break duration: breakDuration
    final bool hasBreakDuration = json.containsKey('breakDuration') && json['breakDuration'] != null;
    final String breakDur = hasBreakDuration
        ? json['breakDuration'].toString()
        : (json['totalBreakMinutes'] != null
            ? '${json['totalBreakMinutes']}m'
            : '—');

    // 14. Total break minutes: totalBreakMinutes
    final bool hasTotalBreakMinutes = json.containsKey('totalBreakMinutes') && json['totalBreakMinutes'] != null;
    final rawTotalBreak = json['totalBreakMinutes'];
    final int totalBreakMinutes = rawTotalBreak is num
        ? rawTotalBreak.toInt()
        : int.tryParse(rawTotalBreak?.toString() ?? '') ?? 0;

    // 15. Break list: breaks
    final bool hasBreaksField = json.containsKey('breaks') && json['breaks'] != null;
    final List<AttendanceBreakItem> resolvedBreaks = [];
    if (json['breaks'] is List) {
      for (final item in json['breaks'] as List) {
        if (item is AttendanceBreakItem) {
          resolvedBreaks.add(item);
        } else if (item is Map<String, dynamic>) {
          resolvedBreaks.add(AttendanceBreakItem.fromJson(item));
        } else if (item is Map) {
          resolvedBreaks.add(AttendanceBreakItem.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    // 16. Active break: activeBreak
    final bool hasActiveBreakField = json.containsKey('activeBreak') && json['activeBreak'] != null;
    final Map<String, dynamic>? activeBreak = json['activeBreak'] is Map
        ? Map<String, dynamic>.from(json['activeBreak'] as Map)
        : null;

    final bool hasBreakDataContract = hasBreaksField || hasActiveBreakField || hasTotalBreakMinutes || hasBreakDuration;

    // If activeBreak is provided and not already in breaks list, add it as an active break item
    if (activeBreak != null && activeBreak.isNotEmpty) {
      final activeBreakType = (activeBreak['breakType'] ?? '').toString();
      final activeBreakId = (activeBreak['breakId'] ?? activeBreak['_id'] ?? '').toString();
      final activeStartTime = activeBreak['startTime']?.toString() ?? json['breakStartedAt']?.toString();
      final hasActiveInBreaks = resolvedBreaks.any((b) =>
          b.isActive ||
          (activeBreakId.isNotEmpty && b.id == activeBreakId) ||
          (activeBreakType.isNotEmpty && b.breakType == activeBreakType && b.endTime == null));
      if (!hasActiveInBreaks && activeBreakType.isNotEmpty) {
        resolvedBreaks.add(AttendanceBreakItem(
          id: activeBreakId,
          breakType: activeBreakType,
          startTime: activeStartTime,
          endTime: null,
          durationMinutes: 0,
        ));
      }
    }

    // 17. Schedule handling
    final rawScheduleSnapshot = json['scheduleSnapshot'];
    final scheduleSnapshot = rawScheduleSnapshot is Map
        ? Map<String, dynamic>.from(rawScheduleSnapshot)
        : null;

    final rawGracePeriod = json['gracePeriodMinutes'] ??
        scheduleSnapshot?['gracePeriodMinutes'];
    final int? gracePeriodMinutes = rawGracePeriod is num
        ? rawGracePeriod.toInt()
        : int.tryParse(rawGracePeriod?.toString() ?? '');

    final scheduledCheckIn = json['scheduledCheckIn']?.toString() ??
        scheduleSnapshot?['scheduledCheckIn']?.toString() ??
        scheduleSnapshot?['checkInTime']?.toString();
    final scheduledCheckOut = json['scheduledCheckOut']?.toString() ??
        scheduleSnapshot?['scheduledCheckOut']?.toString() ??
        scheduleSnapshot?['checkOutTime']?.toString();
    final scheduleTimeZone = json['scheduleTimeZone']?.toString() ??
        scheduleSnapshot?['timeZone']?.toString() ??
        scheduleSnapshot?['timezone']?.toString() ??
        json['timezone']?.toString();

    final String? cleanScheduledCheckIn = (scheduledCheckIn != null &&
            scheduledCheckIn.trim().isNotEmpty &&
            scheduledCheckIn.trim() != '—' &&
            scheduledCheckIn.trim() != '-' &&
            scheduledCheckIn.trim().toLowerCase() != 'null')
        ? scheduledCheckIn.trim()
        : null;

    final String? cleanScheduledCheckOut = (scheduledCheckOut != null &&
            scheduledCheckOut.trim().isNotEmpty &&
            scheduledCheckOut.trim() != '—' &&
            scheduledCheckOut.trim() != '-' &&
            scheduledCheckOut.trim().toLowerCase() != 'null')
        ? scheduledCheckOut.trim()
        : null;

    final String? cleanScheduleTimeZone = (scheduleTimeZone != null &&
            scheduleTimeZone.trim().isNotEmpty &&
            scheduleTimeZone.trim() != '—' &&
            scheduleTimeZone.trim() != '-' &&
            scheduleTimeZone.trim().toLowerCase() != 'null')
        ? scheduleTimeZone.trim()
        : null;

    final bool isExplicitlyUnconfigured =
        json['scheduleConfigured'] == false ||
        json['scheduleConfigured']?.toString().toLowerCase() == 'false' ||
        json['scheduleStatus']?.toString().toUpperCase() == 'UNCONFIGURED';

    final bool isExplicitlyConfigured =
        json['scheduleConfigured'] == true ||
        json['scheduleConfigured']?.toString().toLowerCase() == 'true' ||
        json['scheduleStatus']?.toString().toUpperCase() == 'CONFIGURED';

    final bool scheduleConfigured = !isExplicitlyUnconfigured &&
        cleanScheduledCheckIn != null &&
        (isExplicitlyConfigured || json['scheduleConfigured'] == null);

    // 18. Attendance date: date
    String attDate =
        formatAttendanceDate((json['date'] ?? checkInIso)?.toString());
    if (attDate == '—') {
      attDate = '';
    }

    final breakStarted = json['breakStartedAt']?.toString() ??
        activeBreak?['startTime']?.toString() ??
        activeBreak?['startedAt']?.toString() ??
        (resolvedBreaks.any((b) => b.isActive)
            ? resolvedBreaks.firstWhere((b) => b.isActive).startTime
            : null);

    return Attendance(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      staffId: resolvedStaffId,
      employeeId: resolvedEmployeeId,
      date: attDate,
      checkInTime: resolvedCheckInTime,
      checkOutTime: resolvedCheckOutTime,
      workedDuration: worked.isNotEmpty
          ? worked
          : (hours > 0 ? '${hours}h' : '0h'),
      breakDuration: breakDur,
      isLate: resolvedIsLate,
      minutesLate: minutesLate,
      gracePeriodMinutes: gracePeriodMinutes,
      scheduleSnapshot: scheduleSnapshot,
      scheduledCheckIn: scheduleConfigured ? cleanScheduledCheckIn : null,
      scheduledCheckOut: scheduleConfigured ? cleanScheduledCheckOut : null,
      scheduleTimeZone: scheduleConfigured ? cleanScheduleTimeZone : null,
      scheduleConfigured: scheduleConfigured,
      checkInAt: json['checkInAt']?.toString() ?? checkInIso,
      breakStartedAt: breakStarted,
      employeeName: empName,
      department: dept,
      designation: designation,
      status: normStatus,
      rawStatus: rawStatus,
      workMode: workMode,
      location: json['location']?.toString() ?? '—',
      remarks: json['remarks']?.toString() ?? '',
      workingHours: hours,
      totalBreakMinutes: totalBreakMinutes,
      breaks: resolvedBreaks,
      activeBreak: activeBreak,
      hasBreakDataContract: hasBreakDataContract,
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
  final String title;
  final String employeeId;
  final String employeeName;
  final String? createdAt;

  Task({
    required this.id,
    required this.staffId,
    required this.department,
    required this.description,
    required this.status,
    required this.date,
    required this.dueDate,
    this.title = '',
    this.employeeId = '',
    this.employeeName = '',
    this.createdAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    String id = json['_id']?.toString() ?? json['id']?.toString() ?? '';
    String sId = json['staffId']?.toString() ?? '';
    String empId = json['employeeId']?.toString() ?? '';
    String empName = json['employeeName']?.toString() ?? '';

    if (json['employee'] is Map<String, dynamic>) {
      final emp = json['employee'] as Map<String, dynamic>;
      if (sId.isEmpty) {
        sId = emp['_id']?.toString() ?? emp['id']?.toString() ?? '';
      }
      if (empId.isEmpty) {
        empId = emp['employeeId']?.toString() ?? '';
      }
      if (empName.isEmpty) {
        final fName = emp['firstName']?.toString() ?? '';
        final lName = emp['lastName']?.toString() ?? '';
        empName = '$fName $lName'.trim();
      }
    } else if (json['employee'] is String && sId.isEmpty) {
      sId = json['employee'].toString();
    }

    final createdAtStr = json['createdAt']?.toString() ?? '';
    String d = json['date']?.toString() ?? '';
    if (d.isEmpty && createdAtStr.isNotEmpty) {
      d = createdAtStr.split('T')[0];
    }
    if (d.isEmpty) {
      d = DateTime.now().toIso8601String().split('T')[0];
    }

    return Task(
      id: id,
      staffId: sId,
      department: json['department']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status: (json['status']?.toString() ?? 'pending').toLowerCase(),
      date: d,
      dueDate: json['dueDate']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      employeeId: empId,
      employeeName: empName,
      createdAt: createdAtStr.isNotEmpty ? createdAtStr : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'staffId': staffId,
      'department': department,
      'description': description,
      'status': status,
      'date': date,
      'dueDate': dueDate,
      if (title.isNotEmpty) 'title': title,
      if (employeeId.isNotEmpty) 'employeeId': employeeId,
      if (employeeName.isNotEmpty) 'employeeName': employeeName,
      if (createdAt != null) 'createdAt': createdAt,
    };
  }

  Task copyWith({
    String? id,
    String? staffId,
    String? department,
    String? description,
    String? status,
    String? date,
    String? dueDate,
    String? title,
    String? employeeId,
    String? employeeName,
    String? createdAt,
  }) {
    return Task(
      id: id ?? this.id,
      staffId: staffId ?? this.staffId,
      department: department ?? this.department,
      description: description ?? this.description,
      status: status ?? this.status,
      date: date ?? this.date,
      dueDate: dueDate ?? this.dueDate,
      title: title ?? this.title,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Paginated tasks envelope.
class TaskPage {
  final List<Task> tasks;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const TaskPage({
    required this.tasks,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });
}

class LeaveRequest {
  final String id;
  final String staffId;
  final String fromDate;
  final String toDate;
  final String reason;
  String status;
  final String employeeName;
  final String employeeEmail;
  final String department;
  final String leaveType;
  final int daysCount;
  final String durationType;
  final String? halfDaySession;
  final double totalDays;
  final String submissionDate;
  final bool hasMedicalProof;
  final String? medicalProofDocumentId;
  final String? medicalProofUrl;
  final String? medicalProofFileName;
  final String? medicalProofFileType;
  final String? approvedBy;
  final String? approvedAt;
  final String? rejectionReason;

  LeaveRequest({
    required this.id,
    required this.staffId,
    required this.fromDate,
    required this.toDate,
    required this.reason,
    required this.status,
    this.employeeName = '',
    this.employeeEmail = '',
    this.department = '',
    this.leaveType = 'Casual',
    this.daysCount = 1,
    this.durationType = 'FULL_DAY',
    this.halfDaySession,
    double? totalDays,
    this.submissionDate = '',
    this.hasMedicalProof = false,
    this.medicalProofDocumentId,
    this.medicalProofUrl,
    this.medicalProofFileName,
    this.medicalProofFileType,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
  }) : totalDays = totalDays ??
            (daysCount > 0
                ? daysCount.toDouble()
                : (durationType.toUpperCase() == 'HALF_DAY' ? 0.5 : 1.0));

  bool get isHalfDay =>
      durationType.toUpperCase() == 'HALF_DAY' ||
      totalDays == 0.5 ||
      (halfDaySession != null && halfDaySession!.trim().isNotEmpty);

  bool get isFullDay => !isHalfDay;

  String get durationTypeDisplay => isHalfDay ? 'Half Day' : 'Full Day';

  String get halfDaySessionDisplay {
    if (!isHalfDay) return '';
    final session = (halfDaySession ?? '').toUpperCase().trim();
    if (session == 'AFTERNOON') return 'Afternoon';
    return 'Forenoon';
  }

  String get totalDurationDisplay {
    if (isHalfDay) {
      return '0.5 Day';
    }
    final days = totalDays > 0 ? totalDays : calculatedDays.toDouble();
    if (days == 1.0) {
      return '1 Day';
    }
    final formatted = days % 1 == 0 ? days.toInt().toString() : days.toString();
    return '$formatted Days';
  }

  String get durationDisplay {
    if (isHalfDay) {
      final session = halfDaySessionDisplay;
      return 'Half Day – $session – 0.5 Day';
    } else {
      final days = totalDays > 0 ? totalDays : calculatedDays.toDouble();
      final dayWord = days == 1.0
          ? '1 Day'
          : '${days % 1 == 0 ? days.toInt() : days} Days';
      return 'Full Day – $dayWord';
    }
  }

  int get calculatedDays {
    if (isHalfDay) return 1;
    if (daysCount > 0) return daysCount;
    if (totalDays >= 1) return totalDays.round();
    try {
      final sStr = fromDate.contains('T') ? fromDate.split('T')[0] : fromDate;
      final eStr = toDate.contains('T') ? toDate.split('T')[0] : toDate;
      final start = DateTime.parse(sStr);
      final end = DateTime.parse(eStr);
      final diff = end.difference(start).inDays + 1;
      return diff > 0 ? diff : 1;
    } catch (_) {
      return 1;
    }
  }

  String get formattedSubmissionDate =>
      formatLeaveDate(submissionDate.isNotEmpty ? submissionDate : fromDate);

  static String formatLeaveDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '—';
    final trimmed = raw.trim();

    // 1. Direct calendar date parsing (YYYY-MM-DD) to prevent timezone shifts
    final datePart = trimmed.split('T')[0].trim();
    final parts = datePart.split('-');
    if (parts.length == 3) {
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final day = int.tryParse(parts[2]);
      if (year != null &&
          month != null &&
          day != null &&
          month >= 1 &&
          month <= 12 &&
          day >= 1 &&
          day <= 31) {
        const months = [
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
        final dayStr = day.toString().padLeft(2, '0');
        final monthStr = months[month - 1];
        return '$dayStr $monthStr $year';
      }
    }

    // 2. Fallback: parse DateTime in UTC (to avoid local timezone day-shifting)
    try {
      final dt = DateTime.parse(trimmed).toUtc();
      const months = [
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
      final dayStr = dt.day.toString().padLeft(2, '0');
      final monthStr = months[dt.month - 1];
      return '$dayStr $monthStr ${dt.year}';
    } catch (_) {
      return trimmed;
    }
  }

  String get formattedFromDate => formatLeaveDate(fromDate);
  String get formattedToDate => formatLeaveDate(toDate);
  String get formattedDateRange {
    final f = formattedFromDate;
    final t = formattedToDate;
    if (f == t || t.isEmpty || t == '—') {
      return f;
    }
    return '$f  ➔  $t';
  }

  bool get isMedical {
    final t = leaveType
        .trim()
        .toUpperCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
    return t == 'MEDICAL' || t == 'MEDICAL_LEAVE';
  }

  bool get isSick {
    final t = leaveType
        .trim()
        .toUpperCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
    return t == 'SICK' || t == 'SICK_LEAVE';
  }

  static String normalizeLeaveType(dynamic raw) {
    if (raw == null) return 'Casual';
    final str = raw.toString().trim();
    if (str.isEmpty) return 'Casual';
    final upper = str.toUpperCase().replaceAll('-', '_').replaceAll(' ', '_');

    if (upper == 'SICK' || upper == 'SICK_LEAVE') {
      return 'Sick Leave';
    } else if (upper == 'MEDICAL' || upper == 'MEDICAL_LEAVE') {
      return 'Medical Leave';
    } else if (upper == 'CASUAL' || upper == 'CASUAL_LEAVE') {
      return 'Casual';
    } else if (upper == 'ANNUAL' ||
        upper == 'ANNUAL_LEAVE' ||
        upper == 'EARNED' ||
        upper == 'EARNED_LEAVE') {
      return 'Earned';
    } else if (upper == 'UNPAID' || upper == 'UNPAID_LEAVE') {
      return 'Unpaid';
    } else if (upper == 'OTHER' || upper == 'OTHER_LEAVE') {
      return 'Other';
    }
    // Do not silently convert unknown leave types into Medical Leave
    return str;
  }

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    String empName = '';
    String empEmail = '';
    String dept = '';
    String sId = json['staffId'] ?? '';

    if (json['employee'] is Map) {
      final emp = json['employee'] as Map<String, dynamic>;
      empName = '${emp['firstName'] ?? ''} ${emp['lastName'] ?? ''}'.trim();
      empEmail = emp['email'] ?? '';
      dept = emp['department'] ?? '';
      sId = emp['employeeId'] ?? emp['_id'] ?? sId;
    } else {
      empName = json['employeeName'] ?? '';
      empEmail = json['employeeEmail'] ?? '';
      dept = json['department'] ?? '';
    }

    String start = json['fromDate'] ?? '';
    if (start.isEmpty && json['startDate'] != null) {
      start = json['startDate'].toString().split('T')[0];
    } else if (start.contains('T')) {
      start = start.split('T')[0];
    }
    String end = json['toDate'] ?? '';
    if (end.isEmpty && json['endDate'] != null) {
      end = json['endDate'].toString().split('T')[0];
    } else if (end.contains('T')) {
      end = end.split('T')[0];
    }

    final rawType = json['leaveTypeDisplay'] ?? json['leaveType'] ?? 'Casual';
    final lType = normalizeLeaveType(rawType);

    String stat = json['status'] ?? 'Pending';
    if (stat == 'PENDING') {
      stat = 'Pending';
    } else if (stat == 'APPROVED') {
      stat = 'Approved';
    } else if (stat == 'REJECTED') {
      stat = 'Rejected';
    } else if (stat == 'CANCELLED') {
      stat = 'Cancelled';
    }

    String subDate = json['createdAt'] != null
        ? json['createdAt'].toString().split('T')[0]
        : (json['submissionDate'] != null
            ? json['submissionDate'].toString().split('T')[0]
            : start);

    // Resolve document reference or URL
    final rawDocumentId = json['documentId'];
    String? medicalDocumentId = rawDocumentId is Map
        ? (rawDocumentId['_id'] ?? rawDocumentId['id'])?.toString()
        : rawDocumentId?.toString();
    if (medicalDocumentId?.trim().isEmpty ?? false) medicalDocumentId = null;
    String? medUrl = json['medicalProofUrl'] ?? json['documentUrl'];
    String? medFileName = json['originalName'] ??
        json['originalFilename'] ??
        json['medicalProofOriginalName'] ??
        json['medicalProofOriginalFilename'] ??
        json['medicalProofFileName'] ??
        json['documentName'];
    String? medFileType = json['documentType'] ??
        json['medicalProofFileType'] ??
        json['fileType'];

    // The HR API returns a document ID, not a public storage URL. Build the
    // existing authenticated endpoint locally when no endpoint path is given.
    if (medicalDocumentId != null &&
        (medUrl == null || medUrl.isEmpty || medUrl.startsWith('http'))) {
      medUrl = '/api/hr/documents/${Uri.encodeComponent(medicalDocumentId)}/download';
    }

    final docRef = json['document'];
    if (docRef != null) {
      final docId =
          docRef is Map ? (docRef['_id']?.toString()) : docRef.toString();
      if (docId != null && docId.isNotEmpty) {
        medicalDocumentId ??= docId;
        medUrl ??= '/api/hr/documents/$docId/download';
        if (docRef is Map) {
          medFileName ??= docRef['originalName'] ?? docRef['fileName'];
          medFileType ??= docRef['fileType'];
        }
      }
    }

    if (json['attachment'] is Map) {
      final att = json['attachment'] as Map<String, dynamic>;
      medFileName ??= att['originalName'] ?? att['fileName'];
      medFileType ??= att['fileType'];
      medUrl ??= att['fileUrl'] ?? att['filePath'];
    }

    final medProof = json['hasMedicalProof'] == true ||
        medicalDocumentId != null ||
        (medUrl != null && medUrl.isNotEmpty) ||
        (docRef != null) ||
        (json['attachment'] != null);

    // Duration Type & Session handling
    String rawDurationType =
        (json['durationType'] ?? '').toString().trim().toUpperCase();
    String? rawSession =
        json['halfDaySession']?.toString().trim().toUpperCase();
    if (rawSession != null && rawSession.isEmpty) rawSession = null;

    double parsedTotalDays = 0.0;
    final rawTotal = json['totalDays'] ?? json['duration'] ?? json['daysCount'];
    if (rawTotal is num) {
      parsedTotalDays = rawTotal.toDouble();
    } else if (rawTotal is String) {
      parsedTotalDays = double.tryParse(rawTotal) ?? 0.0;
    }

    if (rawDurationType.isEmpty) {
      if (json['isHalfDay'] == true ||
          parsedTotalDays == 0.5 ||
          rawSession != null) {
        rawDurationType = 'HALF_DAY';
      } else {
        rawDurationType = 'FULL_DAY';
      }
    }

    final bool isHalf = rawDurationType == 'HALF_DAY';
    final String durType = isHalf ? 'HALF_DAY' : 'FULL_DAY';
    final String? session = isHalf
        ? (rawSession == 'AFTERNOON' ? 'AFTERNOON' : 'FORENOON')
        : null;

    if (parsedTotalDays <= 0) {
      if (isHalf) {
        parsedTotalDays = 0.5;
      } else if (start.isNotEmpty && end.isNotEmpty) {
        try {
          final s = DateTime.parse(start);
          final e = DateTime.parse(end);
          final diff = e.difference(s).inDays + 1;
          parsedTotalDays = diff > 0 ? diff.toDouble() : 1.0;
        } catch (_) {
          parsedTotalDays = 1.0;
        }
      } else {
        parsedTotalDays = 1.0;
      }
    } else if (isHalf) {
      parsedTotalDays = 0.5;
    }

    final int legacyDays = isHalf ? 1 : parsedTotalDays.round();

    String? approvedByStr;
    if (json['approvedBy'] is Map) {
      final ab = json['approvedBy'] as Map<String, dynamic>;
      final name = '${ab['firstName'] ?? ''} ${ab['lastName'] ?? ''}'.trim();
      approvedByStr =
          name.isNotEmpty ? name : (ab['email'] ?? ab['_id']?.toString());
    } else if (json['approvedBy'] != null) {
      approvedByStr = json['approvedBy'].toString();
    }

    return LeaveRequest(
      id: json['_id'] ?? json['id'] ?? '',
      staffId: sId,
      fromDate: start,
      toDate: end,
      reason: json['reason'] ?? '',
      status: stat,
      employeeName: empName,
      employeeEmail: empEmail,
      department: dept,
      leaveType: lType,
      daysCount: legacyDays,
      durationType: durType,
      halfDaySession: session,
      totalDays: parsedTotalDays,
      submissionDate: subDate,
      hasMedicalProof: medProof,
      medicalProofDocumentId: medicalDocumentId,
      medicalProofUrl: medUrl,
      medicalProofFileName: medFileName,
      medicalProofFileType: medFileType,
      approvedBy: approvedByStr,
      approvedAt: json['approvedAt']?.toString(),
      rejectionReason: json['rejectionReason'],
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
  final String employeeId;
  final String employeeName;
  final String department;
  final String title;
  final String date;
  final String updateText;
  final String? createdAt;

  DailyUpdate({
    required this.id,
    required this.staffId,
    this.employeeId = '',
    this.employeeName = '',
    this.department = '',
    this.title = '',
    required this.date,
    required this.updateText,
    this.createdAt,
  });

  factory DailyUpdate.fromJson(Map<String, dynamic> json) {
    final employee = json['employee'] is Map
        ? Map<String, dynamic>.from(json['employee'] as Map)
        : const <String, dynamic>{};
    final firstName = employee['firstName']?.toString() ?? '';
    final lastName = employee['lastName']?.toString() ?? '';
    final employeeName =
        json['employeeName']?.toString() ?? '$firstName $lastName'.trim();
    final rawDate = json['date']?.toString() ?? '';
    final createdAt = json['createdAt']?.toString();

    String resolvedStaffId = '';
    if (json['staffId'] != null) {
      resolvedStaffId = json['staffId'].toString();
    } else if (employee['_id'] != null) {
      resolvedStaffId = employee['_id'].toString();
    } else if (employee['id'] != null) {
      resolvedStaffId = employee['id'].toString();
    } else if (json['employee'] != null && json['employee'] is! Map) {
      resolvedStaffId = json['employee'].toString();
    }

    return DailyUpdate(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      staffId: resolvedStaffId,
      employeeId: json['employeeId']?.toString() ??
          employee['employeeId']?.toString() ??
          '',
      employeeName: employeeName,
      department: json['department']?.toString() ??
          employee['department']?.toString() ??
          '',
      title: json['title']?.toString() ?? '',
      date: (rawDate.isNotEmpty ? rawDate : (createdAt ?? '')).split('T').first,
      updateText: json['updateText']?.toString() ??
          json['workUpdate']?.toString() ??
          json['description']?.toString() ??
          '',
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'staffId': staffId,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'department': department,
      'title': title,
      'date': date,
      'updateText': updateText,
      if (createdAt != null) 'createdAt': createdAt,
    };
  }
}

// ── Chat Models ──────────────────────────────────────────────────────────────

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderImageUrl;
  final String senderRole;
  final String departmentKey;
  final String? clientMessageId;
  final String receiverId;
  final String text;
  final DateTime timestamp;
  final bool isRead;

  /// When true the message was deleted for everyone by the sender or HR admin.
  /// All clients must hide or replace this message with a tombstone.
  final bool deletedForEveryone;

  /// Set of userId strings that have chosen "Delete for Me".
  /// Only the local user's own ID is ever stored client-side;
  /// the backend persists the full set per message document.
  final Set<String> deletedByIds;

  ChatMessage({
    required this.id,
    required this.senderId,
    this.senderName = '',
    this.senderImageUrl,
    this.senderRole = 'STAFF',
    this.departmentKey = '',
    this.clientMessageId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    this.isRead = false,
    this.deletedForEveryone = false,
    Set<String>? deletedByIds,
  }) : deletedByIds = deletedByIds ?? const {};

  /// Returns true if [userId] should NOT see this message.
  bool isHiddenFor(String userId) {
    return deletedForEveryone || deletedByIds.contains(userId);
  }

  /// Whether the sender is an authorized HR/Admin role
  bool get isHR =>
      senderRole.toUpperCase() == 'HR' ||
      senderRole.toUpperCase() == 'SUPER_ADMIN' ||
      senderRole.toUpperCase() == 'HR MANAGER' ||
      senderRole.toUpperCase() == 'ADMIN';

  ChatMessage copyWith({
    bool? isRead,
    String? senderName,
    String? senderImageUrl,
    String? senderRole,
    String? departmentKey,
    String? clientMessageId,
    bool? deletedForEveryone,
    Set<String>? deletedByIds,
  }) {
    return ChatMessage(
      id: id,
      senderId: senderId,
      senderName: senderName ?? this.senderName,
      senderImageUrl: senderImageUrl ?? this.senderImageUrl,
      senderRole: senderRole ?? this.senderRole,
      departmentKey: departmentKey ?? this.departmentKey,
      clientMessageId: clientMessageId ?? this.clientMessageId,
      receiverId: receiverId,
      text: text,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      deletedForEveryone: deletedForEveryone ?? this.deletedForEveryone,
      deletedByIds: deletedByIds ?? this.deletedByIds,
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    // deletedByIds comes back as a JSON list of strings from the backend
    Set<String> deletedBy = {};
    final rawDeleted = json['deletedByIds'];
    if (rawDeleted is List) {
      deletedBy = rawDeleted.map((e) => e.toString()).toSet();
    }
    final sender = json['sender'] is Map
        ? Map<String, dynamic>.from(json['sender'] as Map)
        : const <String, dynamic>{};
    return ChatMessage(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      senderName: json['senderName']?.toString() ?? '',
      senderImageUrl: (json['senderImageUrl'] ??
              json['profileImage'] ??
              json['avatarUrl'] ??
              json['photoUrl'] ??
              sender['profileImage'] ??
              sender['avatarUrl'] ??
              sender['photoUrl'])
          ?.toString(),
      senderRole: json['senderRole']?.toString() ?? 'STAFF',
      departmentKey: json['departmentKey']?.toString() ?? '',
      clientMessageId: json['clientMessageId']?.toString(),
      receiverId: json['receiverId']?.toString() ?? '',
      text: json['text'] ?? json['message'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : (json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'].toString()) ??
                  DateTime.now()
              : DateTime.now()),
      isRead: json['isRead'] == true,
      deletedForEveryone: json['deletedForEveryone'] == true,
      deletedByIds: deletedBy,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderId': senderId,
        'senderName': senderName,
        'senderRole': senderRole,
        'departmentKey': departmentKey,
        if (clientMessageId != null) 'clientMessageId': clientMessageId,
        'receiverId': receiverId,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
        'isRead': isRead,
        'deletedForEveryone': deletedForEveryone,
        'deletedByIds': deletedByIds.toList(),
      };
}

/// Paginated result of department chat messages
class DepartmentMessagesResult {
  final List<ChatMessage> messages;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasMore;
  final String departmentKey;

  const DepartmentMessagesResult({
    required this.messages,
    this.page = 1,
    this.limit = 50,
    this.total = 0,
    this.totalPages = 1,
    this.hasMore = false,
    this.departmentKey = '',
  });

  factory DepartmentMessagesResult.fromJson(
      Map<String, dynamic> json, List<ChatMessage> messages) {
    final pagination = json['pagination'] is Map<String, dynamic>
        ? json['pagination'] as Map<String, dynamic>
        : (json['data'] is Map && (json['data'] as Map)['pagination'] is Map
            ? (json['data'] as Map)['pagination'] as Map<String, dynamic>
            : const <String, dynamic>{});

    return DepartmentMessagesResult(
      messages: messages,
      page: pagination['page'] is int ? pagination['page'] : 1,
      limit: pagination['limit'] is int ? pagination['limit'] : 50,
      total: pagination['total'] is int ? pagination['total'] : messages.length,
      totalPages:
          pagination['totalPages'] is int ? pagination['totalPages'] : 1,
      hasMore: pagination['hasMore'] == true,
      departmentKey: pagination['departmentKey']?.toString() ?? '',
    );
  }
}

class ChatThread {
  final String participantId;
  final String participantName;
  final String participantRole;
  final String participantDept;
  final List<ChatMessage> messages;

  ChatThread({
    required this.participantId,
    required this.participantName,
    required this.participantRole,
    required this.participantDept,
    this.messages = const [],
  });

  ChatMessage? get lastMessage => messages.isEmpty ? null : messages.last;

  int unreadCountForUser([String? userId]) {
    final effectiveId = (userId != null && userId.isNotEmpty) ? userId : '';
    return messages.where((m) => !m.isRead && m.senderId != effectiveId).length;
  }

  int get unreadCount => unreadCountForUser();

  String lastMessagePreviewForUser([String? userId]) {
    final msg = lastMessage;
    if (msg == null) return 'No messages yet';
    final effectiveId = (userId != null && userId.isNotEmpty) ? userId : '';
    final prefix = msg.senderId == effectiveId
        ? 'You: '
        : (msg.senderName.isNotEmpty
            ? '${msg.senderName.split(' ').first}: '
            : '');
    final fullText = '$prefix${msg.text}';
    return fullText.length > 50 ? '${fullText.substring(0, 50)}…' : fullText;
  }

  String get lastMessagePreview => lastMessagePreviewForUser();

  String get lastMessageTime {
    final msg = lastMessage;
    if (msg == null) return '';
    final now = DateTime.now();
    final diff = now.difference(msg.timestamp);
    if (diff.inDays == 0) {
      final h = msg.timestamp.hour.toString().padLeft(2, '0');
      final m = msg.timestamp.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${msg.timestamp.day}/${msg.timestamp.month}';
    }
  }
}

class DepartmentChatThread {
  final String departmentKey; // 'tech', 'telecalling'
  final String departmentName;
  final String icon;
  final List<String> memberIds;
  final List<ChatMessage> messages;

  DepartmentChatThread({
    required this.departmentKey,
    required this.departmentName,
    this.icon = '💬',
    this.memberIds = const [],
    this.messages = const [],
  });

  ChatMessage? get lastMessage => messages.isEmpty ? null : messages.last;

  int unreadCountForUser([String? userId]) {
    final effectiveId = (userId != null && userId.isNotEmpty) ? userId : '';
    return messages.where((m) => !m.isRead && m.senderId != effectiveId).length;
  }

  int get unreadCount => unreadCountForUser();

  String lastMessagePreviewForUser([String? userId]) {
    final msg = lastMessage;
    if (msg == null) return 'No messages yet';
    final effectiveId = (userId != null && userId.isNotEmpty) ? userId : '';
    final prefix = msg.senderId == effectiveId
        ? 'You: '
        : (msg.senderName.isNotEmpty
            ? '${msg.senderName.split(' ').first}: '
            : '');
    final fullText = '$prefix${msg.text}';
    return fullText.length > 50 ? '${fullText.substring(0, 50)}…' : fullText;
  }

  String get lastMessagePreview => lastMessagePreviewForUser();

  String get lastMessageTime {
    final msg = lastMessage;
    if (msg == null) return '';
    final now = DateTime.now();
    final diff = now.difference(msg.timestamp);
    if (diff.inDays == 0) {
      final h = msg.timestamp.hour.toString().padLeft(2, '0');
      final m = msg.timestamp.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${msg.timestamp.day}/${msg.timestamp.month}';
    }
  }

  DepartmentChatThread copyWith({
    String? departmentKey,
    String? departmentName,
    String? icon,
    List<String>? memberIds,
    List<ChatMessage>? messages,
  }) {
    return DepartmentChatThread(
      departmentKey: departmentKey ?? this.departmentKey,
      departmentName: departmentName ?? this.departmentName,
      icon: icon ?? this.icon,
      memberIds: memberIds ?? this.memberIds,
      messages: messages ?? this.messages,
    );
  }
}

/// Aggregated payroll summary for a given month, year, and optional department.
class PayrollSummary {
  final int year;
  final int month;
  final String department;
  final int totalEmployees;
  final double totalPayrollExpenditure;
  final double totalDeductions;
  final double totalNetPayout;
  final int unresolvedConflictCount;
  final bool hasUnresolvedConflicts;
  final String? batchId;
  final String? batchStatus;

  const PayrollSummary({
    required this.year,
    required this.month,
    required this.department,
    required this.totalEmployees,
    required this.totalPayrollExpenditure,
    required this.totalDeductions,
    required this.totalNetPayout,
    this.unresolvedConflictCount = 0,
    this.hasUnresolvedConflicts = false,
    this.batchId,
    this.batchStatus,
  });

  factory PayrollSummary.fromJson(Map<String, dynamic> json) {
    final conflictCount = (json['unresolvedConflictCount'] as num?)?.toInt() ??
        (json['unresolvedConflicts'] as num?)?.toInt() ??
        0;
    return PayrollSummary(
      year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
      month: (json['month'] as num?)?.toInt() ?? DateTime.now().month,
      department: json['department']?.toString() ?? 'all',
      totalEmployees: (json['totalEmployees'] as num?)?.toInt() ??
          (json['employeeCount'] as num?)?.toInt() ??
          0,
      totalPayrollExpenditure:
          (json['totalPayrollExpenditure'] as num?)?.toDouble() ??
              (json['totalMonthlyBaseSalary'] as num?)?.toDouble() ??
              (json['grossSalary'] as num?)?.toDouble() ??
              0.0,
      totalDeductions: (json['totalDeductions'] as num?)?.toDouble() ?? 0.0,
      totalNetPayout: (json['totalNetPayout'] as num?)?.toDouble() ??
          (json['netPay'] as num?)?.toDouble() ??
          0.0,
      unresolvedConflictCount: conflictCount,
      hasUnresolvedConflicts:
          json['hasUnresolvedConflicts'] == true || conflictCount > 0,
      batchId: json['batchId']?.toString() ?? json['_id']?.toString(),
      batchStatus:
          json['status']?.toString() ?? json['batchStatus']?.toString(),
    );
  }
}

/// Single employee itemized payroll calculation record.
class EmployeePayrollRecord {
  final String id;
  final String employeeId;
  final String firstName;
  final String lastName;
  final String name;
  final String department;
  final String designation;
  final String status;
  final double salary;
  final String salaryCurrency;

  final int year;
  final int month;
  final int standardWorkingDays;
  final double presentDays;
  final double halfDays;
  final double wfhDays;
  final int weeklyOffs;
  final int holidays;
  final double approvedLeaves;
  final double paidLeaveDays;
  final double unpaidLeaveDays;
  final double lopDays;
  final double payableDays;
  final double grossSalary;
  final double dailyRate;
  final double deductions;
  final double netPay;
  final bool hasUnresolvedConflicts;
  final int unresolvedConflictCount;

  const EmployeePayrollRecord({
    required this.id,
    required this.employeeId,
    required this.firstName,
    required this.lastName,
    required this.name,
    required this.department,
    required this.designation,
    required this.status,
    required this.salary,
    required this.salaryCurrency,
    required this.year,
    required this.month,
    required this.standardWorkingDays,
    required this.presentDays,
    this.halfDays = 0.0,
    this.wfhDays = 0.0,
    this.weeklyOffs = 0,
    this.holidays = 0,
    required this.approvedLeaves,
    required this.paidLeaveDays,
    required this.unpaidLeaveDays,
    this.lopDays = 0.0,
    required this.payableDays,
    required this.grossSalary,
    required this.dailyRate,
    required this.deductions,
    required this.netPay,
    this.hasUnresolvedConflicts = false,
    this.unresolvedConflictCount = 0,
  });

  bool get hasZeroPayableDays => payableDays <= 0;
  bool get hasZeroNetPay => netPay <= 0;

  factory EmployeePayrollRecord.fromJson(Map<String, dynamic> json) {
    final emp = (json['employee'] is Map<String, dynamic>)
        ? json['employee'] as Map<String, dynamic>
        : <String, dynamic>{};

    final id = emp['id']?.toString() ??
        emp['_id']?.toString() ??
        (json['employee'] is String ? json['employee'].toString() : null) ??
        json['id']?.toString() ??
        json['_id']?.toString() ??
        '';
    final employeeId =
        emp['employeeId']?.toString() ?? json['employeeId']?.toString() ?? '';
    final firstName = emp['firstName']?.toString() ?? '';
    final lastName = emp['lastName']?.toString() ?? '';
    final rawName =
        (emp['name'] != null && emp['name'].toString().trim().isNotEmpty)
            ? emp['name'].toString().trim()
            : (json['employeeName'] != null &&
                    json['employeeName'].toString().trim().isNotEmpty)
                ? json['employeeName'].toString().trim()
                : '$firstName $lastName'.trim();
    final name = rawName.isNotEmpty ? rawName : employeeId;
    final department =
        emp['department']?.toString() ?? json['department']?.toString() ?? '';
    final designation = emp['designation']?.toString() ??
        json['designation']?.toString() ??
        '';
    final status =
        emp['status']?.toString() ?? json['status']?.toString() ?? 'ACTIVE';
    final salary = (emp['salary'] as num?)?.toDouble() ??
        (emp['monthlyBaseSalary'] as num?)?.toDouble() ??
        (json['monthlyBaseSalary'] as num?)?.toDouble() ??
        (json['grossSalary'] as num?)?.toDouble() ??
        (json['grossPay'] as num?)?.toDouble() ??
        0.0;
    final salaryCurrency = emp['salaryCurrency']?.toString() ??
        json['salaryCurrency']?.toString() ??
        'INR';

    final conflictCount =
        (json['unresolvedConflictCount'] as num?)?.toInt() ?? 0;
    final hasConflicts =
        json['hasUnresolvedConflicts'] == true || conflictCount > 0;

    return EmployeePayrollRecord(
      id: id,
      employeeId: employeeId,
      firstName: firstName,
      lastName: lastName,
      name: name,
      department: department,
      designation: designation,
      status: status,
      salary: salary,
      salaryCurrency: salaryCurrency,
      year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
      month: (json['month'] as num?)?.toInt() ?? DateTime.now().month,
      standardWorkingDays: (json['scheduledWorkingDays'] ??
              json['standardWorkingDays'] as num?)
          ?.toInt() ??
          0,
      presentDays: (json['presentDays'] as num?)?.toDouble() ?? 0.0,
      halfDays: (json['halfDays'] as num?)?.toDouble() ?? 0.0,
      wfhDays: (json['wfhDays'] as num?)?.toDouble() ?? 0.0,
      weeklyOffs: (json['weeklyOffs'] as num?)?.toInt() ?? 0,
      holidays: (json['holidays'] as num?)?.toInt() ?? 0,
      approvedLeaves: (json['approvedLeaves'] ??
              json['approvedPaidLeaveDays'] as num?)
          ?.toDouble() ??
          0.0,
      paidLeaveDays: (json['paidLeaveDays'] ??
              json['approvedPaidLeaveDays'] as num?)
          ?.toDouble() ??
          0.0,
      unpaidLeaveDays: (json['unpaidLeaveDays'] ??
              json['approvedUnpaidLeaveDays'] as num?)
          ?.toDouble() ??
          0.0,
      lopDays: (json['lopDays'] as num?)?.toDouble() ??
          (json['unpaidLeaveDays'] as num?)?.toDouble() ??
          0.0,
      payableDays: (json['payableDays'] as num?)?.toDouble() ?? 0.0,
      grossSalary: (json['monthlyBaseSalary'] ??
              json['grossSalary'] ??
              json['grossPay'] as num?)
          ?.toDouble() ??
          salary,
      dailyRate: (json['dailySalary'] ?? json['dailyRate'] as num?)
          ?.toDouble() ??
          0.0,
      deductions: (json['deductions'] as num?)?.toDouble() ?? 0.0,
      netPay: (json['netSalary'] ?? json['netPay'] as num?)?.toDouble() ?? 0.0,
      hasUnresolvedConflicts: hasConflicts,
      unresolvedConflictCount: conflictCount,
    );
  }
}

/// Paginated employee payroll response envelope.
class EmployeePayrollPage {
  final List<EmployeePayrollRecord> records;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const EmployeePayrollPage({
    required this.records,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });
}

/// Historical or persisted payroll batch snapshot.
class PayrollBatch {
  final String id;
  final int year;
  final int month;
  final String department;
  final String status; // 'DRAFT', 'FINALIZED', 'PAID'
  final double grossSalary;
  final double totalMonthlyBaseSalary;
  final double totalDeductions;
  final double netPay;
  final double totalNetPayout;
  final int employeeCount;
  final int unresolvedConflictCount;
  final String notes;
  final String createdByName;
  final String finalizedByName;
  final String? finalizedAt;
  final String? paidAt;
  final String paymentMethod;
  final String paymentReference;
  final String paymentRemarks;
  final String paidByName;
  final String? createdAt;
  final String? updatedAt;

  const PayrollBatch({
    required this.id,
    required this.year,
    required this.month,
    required this.department,
    required this.status,
    required this.grossSalary,
    required this.totalMonthlyBaseSalary,
    required this.totalDeductions,
    required this.netPay,
    required this.totalNetPayout,
    required this.employeeCount,
    required this.unresolvedConflictCount,
    this.notes = '',
    this.createdByName = '',
    this.finalizedByName = '',
    this.finalizedAt,
    this.paidAt,
    this.paymentMethod = '',
    this.paymentReference = '',
    this.paymentRemarks = '',
    this.paidByName = '',
    this.createdAt,
    this.updatedAt,
  });

  bool get isDraft => status.toUpperCase() == 'DRAFT';
  bool get isFinalized => status.toUpperCase() == 'FINALIZED';
  bool get isPaid => status.toUpperCase() == 'PAID';
  bool get canFinalize => isDraft && unresolvedConflictCount == 0;
  bool get canPay => isFinalized;

  factory PayrollBatch.fromJson(Map<String, dynamic> json) {
    String cName = '';
    if (json['createdBy'] is Map) {
      final cb = json['createdBy'] as Map;
      cName = '${cb['firstName'] ?? ''} ${cb['lastName'] ?? ''}'.trim();
    } else if (json['createdBy'] != null) {
      cName = json['createdBy'].toString();
    }

    String fName = '';
    if (json['finalizedBy'] is Map) {
      final fb = json['finalizedBy'] as Map;
      fName = '${fb['firstName'] ?? ''} ${fb['lastName'] ?? ''}'.trim();
    } else if (json['finalizedBy'] != null) {
      fName = json['finalizedBy'].toString();
    }

    String pMethod = '';
    String pRef = '';
    String pRemarks = '';
    String pName = '';
    if (json['paymentDetails'] is Map) {
      final pd = json['paymentDetails'] as Map;
      pMethod = pd['paymentMethod']?.toString() ?? '';
      pRef = pd['reference']?.toString() ?? '';
      pRemarks = pd['remarks']?.toString() ?? '';
      if (pd['paidBy'] is Map) {
        final pb = pd['paidBy'] as Map;
        pName = '${pb['firstName'] ?? ''} ${pb['lastName'] ?? ''}'.trim();
      } else if (pd['paidBy'] != null) {
        pName = pd['paidBy'].toString();
      }
    }

    return PayrollBatch(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
      month: (json['month'] as num?)?.toInt() ?? DateTime.now().month,
      department: json['department']?.toString() ?? 'all',
      status: (json['status'] ?? 'DRAFT').toString().toUpperCase(),
      grossSalary: (json['grossSalary'] as num?)?.toDouble() ?? 0.0,
      totalMonthlyBaseSalary:
          (json['totalMonthlyBaseSalary'] as num?)?.toDouble() ?? 0.0,
      totalDeductions: (json['totalDeductions'] as num?)?.toDouble() ?? 0.0,
      netPay: (json['netPay'] as num?)?.toDouble() ?? 0.0,
      totalNetPayout: (json['totalNetPayout'] as num?)?.toDouble() ?? 0.0,
      employeeCount: (json['employeeCount'] as num?)?.toInt() ?? 0,
      unresolvedConflictCount:
          (json['unresolvedConflictCount'] as num?)?.toInt() ?? 0,
      notes: json['notes']?.toString() ?? '',
      createdByName: cName,
      finalizedByName: fName,
      finalizedAt: json['finalizedAt']?.toString(),
      paidAt: json['paidAt']?.toString(),
      paymentMethod: pMethod,
      paymentReference: pRef,
      paymentRemarks: pRemarks,
      paidByName: pName,
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }
}

/// Payroll attendance and leave conflict record.
class PayrollConflict {
  final String id;
  final String employeeId;
  final String employeeName;
  final String employeeRefId;
  final String department;
  final String dateKey;
  final String conflictDate;
  final int year;
  final int month;
  final String conflictType;
  final String attendanceStatus;
  final String attendanceWorkMode;
  final String leaveType;
  final String leaveReason;
  final String status; // 'UNRESOLVED', 'RESOLVED'
  final String? resolutionDecision; // 'PRESENT', 'PAID_LEAVE', 'UNPAID_LEAVE'
  final String? resolvedByName;
  final String? resolvedAt;
  final String resolutionReason;

  const PayrollConflict({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.employeeRefId,
    required this.department,
    required this.dateKey,
    required this.conflictDate,
    required this.year,
    required this.month,
    required this.conflictType,
    required this.attendanceStatus,
    required this.attendanceWorkMode,
    required this.leaveType,
    required this.leaveReason,
    required this.status,
    this.resolutionDecision,
    this.resolvedByName,
    this.resolvedAt,
    this.resolutionReason = '',
  });

  bool get isUnresolved => status.toUpperCase() == 'UNRESOLVED';
  bool get isResolved => status.toUpperCase() == 'RESOLVED';

  factory PayrollConflict.fromJson(Map<String, dynamic> json) {
    String empId = json['employeeId']?.toString() ?? '';
    String empName = '';
    String empRef = '';
    String dept = '';

    if (json['employee'] is Map) {
      final emp = json['employee'] as Map;
      empRef = (emp['_id'] ?? emp['id'] ?? '').toString();
      if (empId.isEmpty) empId = emp['employeeId']?.toString() ?? '';
      empName = '${emp['firstName'] ?? ''} ${emp['lastName'] ?? ''}'.trim();
      dept = emp['department']?.toString() ?? '';
    } else if (json['employee'] != null) {
      empRef = json['employee'].toString();
    }

    String attStatus = json['attendanceStatus']?.toString() ?? '';
    String attMode = json['attendanceWorkMode']?.toString() ?? 'Office';
    if (json['attendance'] is Map) {
      final att = json['attendance'] as Map;
      if (attStatus.isEmpty) attStatus = att['status']?.toString() ?? '';
      if (att['workMode'] != null) attMode = att['workMode'].toString();
    }

    String lType = json['leaveType']?.toString() ?? '';
    String lReason = '';
    if (json['leave'] is Map) {
      final lv = json['leave'] as Map;
      if (lType.isEmpty) lType = lv['leaveType']?.toString() ?? '';
      lReason = lv['reason']?.toString() ?? '';
    }

    String? resDecision;
    String? resByName;
    String? resAt;
    String resReason = '';

    if (json['resolution'] is Map) {
      final res = json['resolution'] as Map;
      resDecision = res['decision']?.toString();
      resAt = res['resolvedAt']?.toString();
      resReason = res['reason']?.toString() ?? '';
      if (res['resolvedBy'] is Map) {
        final rb = res['resolvedBy'] as Map;
        resByName =
            '${rb['firstName'] ?? ''} ${rb['lastName'] ?? ''}'.trim();
      } else if (res['resolvedBy'] != null) {
        resByName = res['resolvedBy'].toString();
      }
    }

    return PayrollConflict(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      employeeId: empId,
      employeeName: empName.isNotEmpty ? empName : empId,
      employeeRefId: empRef,
      department: dept,
      dateKey: json['dateKey']?.toString() ?? '',
      conflictDate: json['conflictDate']?.toString() ??
          json['dateKey']?.toString() ??
          '',
      year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
      month: (json['month'] as num?)?.toInt() ?? DateTime.now().month,
      conflictType: json['conflictType']?.toString() ??
          'ATTENDANCE_AND_APPROVED_LEAVE',
      attendanceStatus: attStatus.isNotEmpty ? attStatus : 'PRESENT',
      attendanceWorkMode: attMode,
      leaveType: lType.isNotEmpty ? lType : 'Casual',
      leaveReason: lReason,
      status: (json['status'] ?? 'UNRESOLVED').toString().toUpperCase(),
      resolutionDecision: resDecision,
      resolvedByName: resByName,
      resolvedAt: resAt,
      resolutionReason: resReason,
    );
  }
}

class PayrollConflictsResult {
  final List<PayrollConflict> conflicts;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final int unresolvedTotal;

  const PayrollConflictsResult({
    required this.conflicts,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.unresolvedTotal,
  });
}

class PayrollBatchesResult {
  final List<PayrollBatch> batches;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const PayrollBatchesResult({
    required this.batches,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });
}

class PayrollBatchDetailResult {
  final PayrollBatch batch;
  final List<EmployeePayrollRecord> records;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const PayrollBatchDetailResult({
    required this.batch,
    required this.records,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });
}

class PayrollPayslipItem {
  final String title;
  final double amount;
  const PayrollPayslipItem({required this.title, required this.amount});

  factory PayrollPayslipItem.fromJson(Map<String, dynamic> json) {
    return PayrollPayslipItem(
      title: json['title']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PayrollPayslipCalendar {
  final int scheduledWorkingDays;
  final int weeklyOffs;
  final int holidays;
  final double presentDays;
  final double halfDays;
  final int wfhDays;
  final double paidLeaveDays;
  final double unpaidLeaveDays;
  final double lopDays;
  final double payableDays;

  const PayrollPayslipCalendar({
    required this.scheduledWorkingDays,
    required this.weeklyOffs,
    required this.holidays,
    required this.presentDays,
    required this.halfDays,
    required this.wfhDays,
    required this.paidLeaveDays,
    required this.unpaidLeaveDays,
    required this.lopDays,
    required this.payableDays,
  });

  factory PayrollPayslipCalendar.fromJson(Map<String, dynamic> json) {
    return PayrollPayslipCalendar(
      scheduledWorkingDays:
          (json['scheduledWorkingDays'] as num?)?.toInt() ?? 0,
      weeklyOffs: (json['weeklyOffs'] as num?)?.toInt() ?? 0,
      holidays: (json['holidays'] as num?)?.toInt() ?? 0,
      presentDays: (json['presentDays'] as num?)?.toDouble() ?? 0.0,
      halfDays: (json['halfDays'] as num?)?.toDouble() ?? 0.0,
      wfhDays: (json['wfhDays'] as num?)?.toInt() ?? 0,
      paidLeaveDays: (json['paidLeaveDays'] as num?)?.toDouble() ?? 0.0,
      unpaidLeaveDays: (json['unpaidLeaveDays'] as num?)?.toDouble() ?? 0.0,
      lopDays: (json['lopDays'] as num?)?.toDouble() ?? 0.0,
      payableDays: (json['payableDays'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PayrollPayslipDetail {
  final String companyName;
  final String currency;
  final String batchId;
  final int year;
  final int month;
  final String period;
  final String batchStatus;
  final String? finalizedAt;
  final String? paidAt;
  final String employeeId;
  final String employeeName;
  final String department;
  final String designation;
  final PayrollPayslipCalendar calendar;
  final List<PayrollPayslipItem> earnings;
  final List<PayrollPayslipItem> deductions;
  final double dailySalary;
  final double grossPay;
  final double totalDeductions;
  final double netPay;
  final bool pdfExportSupported;
  final String pdfExportNote;

  const PayrollPayslipDetail({
    required this.companyName,
    required this.currency,
    required this.batchId,
    required this.year,
    required this.month,
    required this.period,
    required this.batchStatus,
    this.finalizedAt,
    this.paidAt,
    required this.employeeId,
    required this.employeeName,
    required this.department,
    required this.designation,
    required this.calendar,
    required this.earnings,
    required this.deductions,
    required this.dailySalary,
    required this.grossPay,
    required this.totalDeductions,
    required this.netPay,
    this.pdfExportSupported = false,
    this.pdfExportNote = '',
  });

  factory PayrollPayslipDetail.fromJson(Map<String, dynamic> json) {
    final company =
        (json['company'] is Map) ? json['company'] as Map : const {};
    final payslip =
        (json['payslip'] is Map) ? json['payslip'] as Map : json;

    final emp =
        (payslip['employee'] is Map) ? payslip['employee'] as Map : const {};
    final cal =
        (payslip['calendar'] is Map) ? payslip['calendar'] as Map : const {};
    final sum =
        (payslip['summary'] is Map) ? payslip['summary'] as Map : const {};

    final earningsList = <PayrollPayslipItem>[];
    if (payslip['earnings'] is List) {
      for (final e in payslip['earnings']) {
        if (e is Map) {
          earningsList.add(
              PayrollPayslipItem.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }

    final deductionsList = <PayrollPayslipItem>[];
    if (payslip['deductions'] is List) {
      for (final d in payslip['deductions']) {
        if (d is Map) {
          deductionsList.add(
              PayrollPayslipItem.fromJson(Map<String, dynamic>.from(d)));
        }
      }
    }

    return PayrollPayslipDetail(
      companyName: company['name']?.toString() ?? 'LY Software',
      currency: company['currency']?.toString() ?? 'INR',
      batchId: payslip['batchId']?.toString() ?? '',
      year: (payslip['year'] as num?)?.toInt() ?? DateTime.now().year,
      month: (payslip['month'] as num?)?.toInt() ?? DateTime.now().month,
      period: payslip['period']?.toString() ?? '',
      batchStatus: payslip['batchStatus']?.toString() ?? 'DRAFT',
      finalizedAt: payslip['finalizedAt']?.toString(),
      paidAt: payslip['paidAt']?.toString(),
      employeeId: emp['employeeId']?.toString() ?? '',
      employeeName: emp['name']?.toString() ?? '',
      department: emp['department']?.toString() ?? '',
      designation: emp['designation']?.toString() ?? '',
      calendar:
          PayrollPayslipCalendar.fromJson(Map<String, dynamic>.from(cal)),
      earnings: earningsList,
      deductions: deductionsList,
      dailySalary: (sum['dailySalary'] as num?)?.toDouble() ?? 0.0,
      grossPay: (sum['grossPay'] as num?)?.toDouble() ?? 0.0,
      totalDeductions: (sum['totalDeductions'] as num?)?.toDouble() ?? 0.0,
      netPay: (sum['netPay'] as num?)?.toDouble() ?? 0.0,
      pdfExportSupported: payslip['pdfExportSupported'] == true,
      pdfExportNote: payslip['pdfExportNote']?.toString() ?? '',
    );
  }
}

// ── Reports Models (Screen 12 API Integration) ──────────────────────────────

class AttendanceStatusSummaryItem {
  final String status;
  final int count;
  final double? avgWorkingHours;
  final int? workingHoursSampleSize;

  const AttendanceStatusSummaryItem({
    required this.status,
    required this.count,
    this.avgWorkingHours,
    this.workingHoursSampleSize,
  });

  factory AttendanceStatusSummaryItem.fromJson(Map<String, dynamic> json) {
    return AttendanceStatusSummaryItem(
      status: json['_id']?.toString() ?? json['status']?.toString() ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
      avgWorkingHours: (json['avgWorkingHours'] as num?)?.toDouble(),
      workingHoursSampleSize:
          (json['workingHoursSampleSize'] as num?)?.toInt(),
    );
  }
}

class DepartmentAttendanceSummaryItem {
  final String department;
  final String status;
  final int count;
  final double totalHours;

  const DepartmentAttendanceSummaryItem({
    required this.department,
    required this.status,
    required this.count,
    this.totalHours = 0.0,
  });

  factory DepartmentAttendanceSummaryItem.fromJson(Map<String, dynamic> json) {
    return DepartmentAttendanceSummaryItem(
      department: json['department']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
      totalHours: (json['totalHours'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class AttendanceReportData {
  final List<AttendanceStatusSummaryItem> statusSummary;
  final List<DepartmentAttendanceSummaryItem> departmentSummary;
  final int? lateArrivals;
  final int? onTimeArrivals;
  final int? totalAbsent;
  final int? totalAttendanceRecords;
  final int? presentRecords;
  final double? averageWorkingHours;
  final int? workingHoursSampleSize;

  const AttendanceReportData({
    this.statusSummary = const [],
    this.departmentSummary = const [],
    this.lateArrivals,
    this.onTimeArrivals,
    this.totalAbsent,
    this.totalAttendanceRecords,
    this.presentRecords,
    this.averageWorkingHours,
    this.workingHoursSampleSize,
  });

  factory AttendanceReportData.fromJson(Map<String, dynamic> json) {
    final statusList = (json['statusSummary'] as List?)
            ?.map((e) =>
                AttendanceStatusSummaryItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final deptList = (json['departmentSummary'] as List?)
            ?.map((e) => DepartmentAttendanceSummaryItem.fromJson(
                e as Map<String, dynamic>))
            .toList() ??
        [];
    return AttendanceReportData(
      statusSummary: statusList,
      departmentSummary: deptList,
      lateArrivals: (json['lateArrivals'] as num?)?.toInt(),
      onTimeArrivals: (json['onTimeArrivals'] as num?)?.toInt(),
      totalAbsent: (json['totalAbsent'] as num?)?.toInt(),
      totalAttendanceRecords:
          (json['totalAttendanceRecords'] as num?)?.toInt(),
      presentRecords: (json['presentRecords'] as num?)?.toInt(),
      averageWorkingHours:
          (json['averageWorkingHours'] as num?)?.toDouble(),
      workingHoursSampleSize:
          (json['workingHoursSampleSize'] as num?)?.toInt(),
    );
  }

}

class LeaveStatusSummaryItem {
  final String status;
  final int count;

  const LeaveStatusSummaryItem({
    required this.status,
    required this.count,
  });

  factory LeaveStatusSummaryItem.fromJson(Map<String, dynamic> json) {
    return LeaveStatusSummaryItem(
      status: json['_id']?.toString() ?? json['status']?.toString() ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class LeaveTypeSummaryItem {
  final String leaveType;
  final int count;

  const LeaveTypeSummaryItem({
    required this.leaveType,
    required this.count,
  });

  factory LeaveTypeSummaryItem.fromJson(Map<String, dynamic> json) {
    return LeaveTypeSummaryItem(
      leaveType: json['_id']?.toString() ?? json['leaveType']?.toString() ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class LeaveReportData {
  final List<LeaveStatusSummaryItem> statusSummary;
  final List<LeaveTypeSummaryItem> typeSummary;
  final int? totalLeaveApplications;
  final int? approvedRequests;
  final int? pendingRequests;
  final int? rejectedRequests;
  final int? casualLeaves;
  final int? sickMedicalLeaves;
  final int? earnedAnnualLeaves;

  const LeaveReportData({
    this.statusSummary = const [],
    this.typeSummary = const [],
    this.totalLeaveApplications,
    this.approvedRequests,
    this.pendingRequests,
    this.rejectedRequests,
    this.casualLeaves,
    this.sickMedicalLeaves,
    this.earnedAnnualLeaves,
  });

  factory LeaveReportData.fromJson(Map<String, dynamic> json) {
    final statusList = (json['statusSummary'] as List?)
            ?.map((e) =>
                LeaveStatusSummaryItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final typeList = (json['typeSummary'] as List?)
            ?.map(
                (e) => LeaveTypeSummaryItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return LeaveReportData(
      statusSummary: statusList,
      typeSummary: typeList,
      totalLeaveApplications:
          (json['totalLeaveApplications'] as num?)?.toInt(),
      approvedRequests: (json['approvedRequests'] as num?)?.toInt(),
      pendingRequests: (json['pendingRequests'] as num?)?.toInt(),
      rejectedRequests: (json['rejectedRequests'] as num?)?.toInt(),
      casualLeaves: (json['casualLeaves'] as num?)?.toInt(),
      sickMedicalLeaves: (json['sickMedicalLeaves'] as num?)?.toInt(),
      earnedAnnualLeaves: (json['earnedAnnualLeaves'] as num?)?.toInt(),
    );
  }
}

// Employee-wise salary payment models (separate from payroll batches).
double _salaryNumber(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString().trim() ?? '') ?? 0.0;
}

int _salaryInteger(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString().trim() ?? '') ?? 0;
}

DateTime? _salaryDate(dynamic value) {
  if (value == null || value.toString().trim().isEmpty) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

String _salaryReference(dynamic value) {
  if (value is Map) {
    return (value['_id'] ?? value['id'] ?? '').toString();
  }
  return value?.toString() ?? '';
}

class SalaryPaymentUser {
  final String id;
  final String firstName;
  final String lastName;
  final String email;

  const SalaryPaymentUser({
    this.id = '',
    this.firstName = '',
    this.lastName = '',
    this.email = '',
  });

  factory SalaryPaymentUser.fromJson(dynamic json) {
    if (json is! Map) return SalaryPaymentUser(id: _salaryReference(json));
    return SalaryPaymentUser(
      id: _salaryReference(json),
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
    );
  }
}

class SalaryPayment {
  final String id;
  final String employee;
  final String employeeId;
  final String employeeName;
  final String department;
  final String payrollBatch;
  final String payrollRecord;
  final int payrollMonth;
  final int payrollYear;
  final String? legacyBatchStatus;
  final double monthlyBaseSalary;
  final double totalPresentDays;
  final double paidLeaveDays;
  final double lopDays;
  final double payableDays;
  final double netSalary;
  final String status;
  final DateTime? paymentDate;
  final String? paymentMethod;
  final String transactionReference;
  final String remarks;
  final SalaryPaymentUser? confirmedBy;
  final DateTime? confirmedAt;
  final String? paymentStatusEvidence;

  const SalaryPayment({
    required this.id,
    required this.employee,
    required this.employeeId,
    required this.employeeName,
    required this.department,
    required this.payrollBatch,
    required this.payrollRecord,
    required this.payrollMonth,
    required this.payrollYear,
    required this.monthlyBaseSalary,
    required this.totalPresentDays,
    required this.paidLeaveDays,
    required this.lopDays,
    required this.payableDays,
    required this.netSalary,
    required this.status,
    this.legacyBatchStatus,
    this.paymentDate,
    this.paymentMethod,
    this.transactionReference = '',
    this.remarks = '',
    this.confirmedBy,
    this.confirmedAt,
    this.paymentStatusEvidence,
  });

  String get paymentStatus => status;
  bool get isPaid => status == 'PAID';

  factory SalaryPayment.fromJson(Map<String, dynamic> json) {
    return SalaryPayment(
      id: _salaryReference(json['_id'] ?? json['id']),
      employee: _salaryReference(json['employee']),
      employeeId: json['employeeId']?.toString() ?? '',
      employeeName: json['employeeName']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
      payrollBatch: _salaryReference(json['payrollBatch']),
      payrollRecord: _salaryReference(json['payrollRecord']),
      payrollMonth: _salaryInteger(json['payrollMonth']),
      payrollYear: _salaryInteger(json['payrollYear']),
      legacyBatchStatus: json['legacyBatchStatus']?.toString(),
      monthlyBaseSalary: _salaryNumber(json['monthlyBaseSalary']),
      totalPresentDays: _salaryNumber(json['totalPresentDays']),
      paidLeaveDays: _salaryNumber(json['paidLeaveDays']),
      lopDays: _salaryNumber(json['lopDays']),
      payableDays: _salaryNumber(json['payableDays']),
      netSalary: _salaryNumber(json['netSalary']),
      status: (json['status']?.toString() ?? 'PENDING').toUpperCase(),
      paymentDate: _salaryDate(json['paymentDate']),
      paymentMethod: json['paymentMethod']?.toString(),
      transactionReference: json['transactionReference']?.toString() ?? '',
      remarks: json['remarks']?.toString() ?? '',
      confirmedBy: json['confirmedBy'] == null
          ? null
          : SalaryPaymentUser.fromJson(json['confirmedBy']),
      confirmedAt: _salaryDate(json['confirmedAt']),
      paymentStatusEvidence: json['paymentStatusEvidence']?.toString(),
    );
  }
}

class SalaryPaymentSummary {
  final int year;
  final int month;
  final int totalEmployees;
  final double totalSalary;
  final int paidEmployees;
  final int pendingEmployees;
  final double paidAmount;
  final double pendingAmount;

  const SalaryPaymentSummary({
    required this.year,
    required this.month,
    required this.totalEmployees,
    required this.totalSalary,
    required this.paidEmployees,
    required this.pendingEmployees,
    required this.paidAmount,
    required this.pendingAmount,
  });

  factory SalaryPaymentSummary.fromJson(Map<String, dynamic> json) =>
      SalaryPaymentSummary(
        year: _salaryInteger(json['year']),
        month: _salaryInteger(json['month']),
        totalEmployees: _salaryInteger(json['totalEmployees']),
        totalSalary: _salaryNumber(json['totalSalary']),
        paidEmployees: _salaryInteger(json['paidEmployees']),
        pendingEmployees: _salaryInteger(json['pendingEmployees']),
        paidAmount: _salaryNumber(json['paidAmount']),
        pendingAmount: _salaryNumber(json['pendingAmount']),
      );
}

class SalaryPaymentListResult {
  final List<SalaryPayment> payments;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final SalaryPaymentSummary summary;

  const SalaryPaymentListResult({
    required this.payments,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.summary,
  });

  factory SalaryPaymentListResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final outerPagination = json['pagination'];
    final pagination =
        outerPagination is Map ? outerPagination['pagination'] : null;
    final rawSummary =
        outerPagination is Map ? outerPagination['summary'] : null;
    final rows = data is List
        ? data
            .whereType<Map>()
            .map(
                (row) => SalaryPayment.fromJson(Map<String, dynamic>.from(row)))
            .toList()
        : <SalaryPayment>[];
    final pag = pagination is Map ? pagination : const <String, dynamic>{};
    return SalaryPaymentListResult(
      payments: rows,
      page: _salaryInteger(pag['page']),
      limit: _salaryInteger(pag['limit']),
      total: _salaryInteger(pag['total']),
      totalPages: _salaryInteger(pag['totalPages']),
      summary: SalaryPaymentSummary.fromJson(rawSummary is Map
          ? Map<String, dynamic>.from(rawSummary)
          : const <String, dynamic>{}),
    );
  }
}

class SalaryPaymentHistoryResult {
  final List<SalaryPayment> payments;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const SalaryPaymentHistoryResult({
    required this.payments,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory SalaryPaymentHistoryResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final rawPagination = json['pagination'];
    final rows = data is List
        ? data
            .whereType<Map>()
            .map(
                (row) => SalaryPayment.fromJson(Map<String, dynamic>.from(row)))
            .toList()
        : <SalaryPayment>[];
    final pag = rawPagination is Map
        ? Map<String, dynamic>.from(rawPagination)
        : const <String, dynamic>{};
    return SalaryPaymentHistoryResult(
      payments: rows,
      page: _salaryInteger(pag['page']),
      limit: _salaryInteger(pag['limit']),
      total: _salaryInteger(pag['total']),
      totalPages: _salaryInteger(pag['totalPages']),
    );
  }
}

class SalaryPaymentDetailResult {
  final SalaryPayment payment;
  const SalaryPaymentDetailResult({required this.payment});

  factory SalaryPaymentDetailResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! Map) {
      throw const FormatException('Salary payment data is malformed');
    }
    return SalaryPaymentDetailResult(
        payment: SalaryPayment.fromJson(Map<String, dynamic>.from(data)));
  }
}

class ConfirmSalaryPaymentRequest {
  final DateTime paymentDate;
  final String paymentMethod;
  final String transactionReference;
  final String remarks;

  const ConfirmSalaryPaymentRequest({
    required this.paymentDate,
    required this.paymentMethod,
    this.transactionReference = '',
    this.remarks = '',
  });

  Map<String, dynamic> toJson() {
    final method = paymentMethod.trim().toUpperCase();
    if (!{'CASH', 'BANK_TRANSFER', 'UPI'}.contains(method)) {
      throw ArgumentError('paymentMethod must be CASH, BANK_TRANSFER, or UPI');
    }
    final reference = transactionReference.trim();
    if (method != 'CASH' && reference.isEmpty) {
      throw ArgumentError(
          'transactionReference is required for Bank Transfer and UPI payments');
    }
    final date = paymentDate.toIso8601String().split('T').first;
    return {
      'paymentDate': date,
      'paymentMethod': method,
      if (reference.isNotEmpty) 'transactionReference': reference,
      if (remarks.trim().isNotEmpty) 'remarks': remarks.trim(),
    };
  }
}
