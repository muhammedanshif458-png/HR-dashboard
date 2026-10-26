import '../utils/date_time_utils.dart';

class Attendance {
  final String id;
  final String staffId;
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
  final String? checkInAt;
  final String? breakStartedAt;
  final String employeeName;
  final String department;
  final String status;
  final String workMode;
  final String location;
  final String remarks;
  final double workingHours;

  Attendance({
    required this.id,
    required this.staffId,
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
    this.checkInAt,
    this.breakStartedAt,
    this.employeeName = '',
    this.department = '',
    this.status = 'Present',
    this.workMode = '—',
    this.location = '—',
    this.remarks = '',
    this.workingHours = 0.0,
  });

  bool get isOnBreak =>
      breakStartedAt != null &&
      breakStartedAt!.trim().isNotEmpty &&
      breakStartedAt != '—';

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

    final bool resolvedIsLate = json['isLate'] == true ||
        json['late'] == true ||
        json['status'] == 'LATE';

    String resolvedWorkedDuration = '';
    if (json['workedDuration'] != null && json['workedDuration'].toString().isNotEmpty) {
      resolvedWorkedDuration = json['workedDuration'].toString();
    } else if (json['workingHours'] != null) {
      resolvedWorkedDuration = '${json['workingHours']}h';
    }

    String empName = '';
    String dept = '';
    String sId = json['staffId']?.toString() ?? '';

    if (json['employee'] is Map) {
      final emp = json['employee'] as Map<String, dynamic>;
      empName = '${emp['firstName'] ?? ''} ${emp['lastName'] ?? ''}'.trim();
      dept = emp['department'] ?? '';
      if (sId.isEmpty) {
        sId = (emp['employeeId'] != null &&
                emp['employeeId'].toString().isNotEmpty)
            ? emp['employeeId'].toString()
            : (emp['_id']?.toString() ?? '');
      }
    } else {
      empName = json['employeeName'] ?? '';
      dept = json['department'] ?? '';
      if (sId.isEmpty && json['employee'] is String) {
        sId = json['employee'];
      }
    }

    String? checkInIso;
    if (json['checkIn'] != null) {
      checkInIso = json['checkIn'].toString();
    } else if (json['checkInAt'] != null) {
      checkInIso = json['checkInAt'].toString();
    }

    final rawCheckIn =
        (json['checkInTime'] ?? json['checkIn'] ?? json['checkInAt'])?.toString();
    final resolvedCheckInTime = formatAttendanceTimeNullable(rawCheckIn);

    final rawCheckOut =
        (json['checkOutTime'] ?? json['checkOut'])?.toString();
    final resolvedCheckOutTime = (rawCheckOut?.trim() == 'Active')
        ? 'Active'
        : formatAttendanceTimeNullable(rawCheckOut);

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
    final isLate = json['isLate'] == true || json['late'] == true;
    final rawMinutesLate = json['minutesLate'];
    final minutesLate = rawMinutesLate is num
        ? rawMinutesLate.toInt()
        : int.tryParse(rawMinutesLate?.toString() ?? '');
    final rawGracePeriod = json['gracePeriodMinutes'];
    final gracePeriodMinutes = rawGracePeriod is num
        ? rawGracePeriod.toInt()
        : int.tryParse(rawGracePeriod?.toString() ?? '');
    final rawScheduleSnapshot = json['scheduleSnapshot'];
    final scheduleSnapshot = rawScheduleSnapshot is Map
        ? Map<String, dynamic>.from(rawScheduleSnapshot)
        : null;
    final scheduledCheckIn = json['scheduledCheckIn']?.toString() ??
        scheduleSnapshot?['scheduledCheckIn']?.toString() ??
        scheduleSnapshot?['checkInTime']?.toString();
    final scheduledCheckOut = json['scheduledCheckOut']?.toString() ??
        scheduleSnapshot?['scheduledCheckOut']?.toString() ??
        scheduleSnapshot?['checkOutTime']?.toString();
    final scheduleTimeZone = json['scheduleTimeZone']?.toString() ??
        scheduleSnapshot?['timeZone']?.toString() ??
        scheduleSnapshot?['timezone']?.toString();
    if (isLate) normStatus = 'Late';

    double hours = 0.0;
    if (json['workingHours'] != null) {
      hours = (json['workingHours'] as num).toDouble();
    }

    String worked = json['workedDuration'] ?? '';
    if (worked.isEmpty && hours > 0) {
      final h = hours.floor();
      final m = ((hours - h) * 60).round();
      worked = '${h}h ${m}m';
    }

    String attDate =
        formatAttendanceDate((json['date'] ?? checkInIso)?.toString());
    if (attDate == '—') {
      attDate = '';
    }

    return Attendance(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      staffId: sId.isNotEmpty ? sId : resolvedStaffId,
      date: attDate,
      checkInTime: resolvedCheckInTime,
      checkOutTime: resolvedCheckOutTime,
      workedDuration: worked.isNotEmpty ? worked : (resolvedWorkedDuration.isNotEmpty ? resolvedWorkedDuration : '—'),
      breakDuration: json['breakDuration']?.toString() ?? '—',
      isLate: resolvedIsLate || isLate,
      minutesLate: minutesLate,
      gracePeriodMinutes: gracePeriodMinutes,
      scheduleSnapshot: scheduleSnapshot,
      scheduledCheckIn: scheduledCheckIn,
      scheduledCheckOut: scheduledCheckOut,
      scheduleTimeZone: scheduleTimeZone,
      checkInAt: json['checkInAt']?.toString() ?? checkInIso,
      breakStartedAt: json['breakStartedAt']?.toString(),
      employeeName: empName,
      department: dept,
      status: normStatus,
      workMode: json['workMode']?.toString() ??
          (json['employee'] is Map
              ? (json['employee'] as Map)['workMode']?.toString()
              : null) ??
          '—',
      location: json['location']?.toString() ?? '—',
      remarks: json['remarks'] ?? '',
      workingHours: hours,
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
  final String submissionDate;
  final bool hasMedicalProof;
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
    this.submissionDate = '',
    this.hasMedicalProof = false,
    this.medicalProofUrl,
    this.medicalProofFileName,
    this.medicalProofFileType,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
  });

  int get calculatedDays {
    if (daysCount > 0) return daysCount;
    try {
      final start = DateTime.parse(fromDate);
      final end = DateTime.parse(toDate);
      final diff = end.difference(start).inDays + 1;
      return diff > 0 ? diff : 1;
    } catch (_) {
      return 1;
    }
  }

  bool get isMedical =>
      leaveType.toLowerCase() == 'medical' || leaveType.toUpperCase() == 'SICK';

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
    }
    String end = json['toDate'] ?? '';
    if (end.isEmpty && json['endDate'] != null) {
      end = json['endDate'].toString().split('T')[0];
    }

    String lType = json['leaveType'] ?? 'Casual';
    if (lType == 'CASUAL') {
      lType = 'Casual';
    } else if (lType == 'SICK') {
      lType = 'Medical';
    } else if (lType == 'ANNUAL') {
      lType = 'Earned';
    } else if (lType == 'UNPAID') {
      lType = 'Unpaid';
    } else if (lType == 'OTHER') {
      lType = 'Other';
    }

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

    final subDate = json['createdAt'] != null
        ? json['createdAt'].toString().split('T')[0]
        : (json['submissionDate'] ?? start);

    // Resolve document reference or URL
    String? medUrl = json['medicalProofUrl'] ?? json['documentUrl'];
    String? medFileName = json['medicalProofFileName'] ?? json['documentName'];
    String? medFileType = json['medicalProofFileType'] ?? json['documentType'];

    final docRef = json['document'];
    if (docRef != null) {
      final docId =
          docRef is Map ? (docRef['_id']?.toString()) : docRef.toString();
      if (docId != null && docId.isNotEmpty) {
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
        (medUrl != null && medUrl.isNotEmpty) ||
        (docRef != null) ||
        (json['attachment'] != null);

    int days =
        json['daysCount'] is num ? (json['daysCount'] as num).toInt() : 0;
    if (days <= 0 && start.isNotEmpty && end.isNotEmpty) {
      try {
        final s = DateTime.parse(start);
        final e = DateTime.parse(end);
        final diff = e.difference(s).inDays + 1;
        days = diff > 0 ? diff : 1;
      } catch (_) {
        days = 1;
      }
    } else if (days <= 0) {
      days = 1;
    }

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
      daysCount: days,
      submissionDate: subDate,
      hasMedicalProof: medProof,
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

  ChatMessage copyWith({
    bool? isRead,
    String? senderName,
    bool? deletedForEveryone,
    Set<String>? deletedByIds,
  }) {
    return ChatMessage(
      id: id,
      senderId: senderId,
      senderName: senderName ?? this.senderName,
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
    return ChatMessage(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      senderName: json['senderName']?.toString() ?? '',
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
        'receiverId': receiverId,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
        'isRead': isRead,
        'deletedForEveryone': deletedForEveryone,
        'deletedByIds': deletedByIds.toList(),
      };
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

  int get unreadCount =>
      messages.where((m) => !m.isRead && m.senderId != 'admin_1').length;

  String get lastMessagePreview {
    final msg = lastMessage;
    if (msg == null) return 'No messages yet';
    return msg.text.length > 50 ? '${msg.text.substring(0, 50)}…' : msg.text;
  }

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

  int get unreadCount =>
      messages.where((m) => !m.isRead && m.senderId != 'admin_1').length;

  String get lastMessagePreview {
    final msg = lastMessage;
    if (msg == null) return 'No messages yet';
    final prefix = msg.senderId == 'admin_1'
        ? 'You: '
        : (msg.senderName.isNotEmpty
            ? '${msg.senderName.split(' ').first}: '
            : '');
    final fullText = '$prefix${msg.text}';
    return fullText.length > 50 ? '${fullText.substring(0, 50)}…' : fullText;
  }

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

  const PayrollSummary({
    required this.year,
    required this.month,
    required this.department,
    required this.totalEmployees,
    required this.totalPayrollExpenditure,
    required this.totalDeductions,
    required this.totalNetPayout,
  });

  factory PayrollSummary.fromJson(Map<String, dynamic> json) {
    return PayrollSummary(
      year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
      month: (json['month'] as num?)?.toInt() ?? DateTime.now().month,
      department: json['department']?.toString() ?? 'all',
      totalEmployees: (json['totalEmployees'] as num?)?.toInt() ?? 0,
      totalPayrollExpenditure:
          (json['totalPayrollExpenditure'] as num?)?.toDouble() ?? 0.0,
      totalDeductions: (json['totalDeductions'] as num?)?.toDouble() ?? 0.0,
      totalNetPayout: (json['totalNetPayout'] as num?)?.toDouble() ?? 0.0,
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
  final int presentDays;
  final int approvedLeaves;
  final int paidLeaveDays;
  final int unpaidLeaveDays;
  final int payableDays;
  final double grossSalary;
  final double dailyRate;
  final double deductions;
  final double netPay;

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
    required this.approvedLeaves,
    required this.paidLeaveDays,
    required this.unpaidLeaveDays,
    required this.payableDays,
    required this.grossSalary,
    required this.dailyRate,
    required this.deductions,
    required this.netPay,
  });

  factory EmployeePayrollRecord.fromJson(Map<String, dynamic> json) {
    final emp = (json['employee'] is Map<String, dynamic>)
        ? json['employee'] as Map<String, dynamic>
        : <String, dynamic>{};

    final id = emp['id']?.toString() ?? emp['_id']?.toString() ?? '';
    final employeeId = emp['employeeId']?.toString() ?? '';
    final firstName = emp['firstName']?.toString() ?? '';
    final lastName = emp['lastName']?.toString() ?? '';
    final name =
        (emp['name'] != null && emp['name'].toString().trim().isNotEmpty)
            ? emp['name'].toString().trim()
            : '$firstName $lastName'.trim();
    final department = emp['department']?.toString() ?? '';
    final designation = emp['designation']?.toString() ?? '';
    final status = emp['status']?.toString() ?? 'ACTIVE';
    final salary = (emp['salary'] as num?)?.toDouble() ??
        (json['grossSalary'] as num?)?.toDouble() ??
        0.0;
    final salaryCurrency = emp['salaryCurrency']?.toString() ?? 'INR';

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
      standardWorkingDays: (json['standardWorkingDays'] as num?)?.toInt() ?? 0,
      presentDays: (json['presentDays'] as num?)?.toInt() ?? 0,
      approvedLeaves: (json['approvedLeaves'] as num?)?.toInt() ?? 0,
      paidLeaveDays: (json['paidLeaveDays'] as num?)?.toInt() ?? 0,
      unpaidLeaveDays: (json['unpaidLeaveDays'] as num?)?.toInt() ?? 0,
      payableDays: (json['payableDays'] as num?)?.toInt() ?? 0,
      grossSalary: (json['grossSalary'] as num?)?.toDouble() ?? salary,
      dailyRate: (json['dailyRate'] as num?)?.toDouble() ?? 0.0,
      deductions: (json['deductions'] as num?)?.toDouble() ?? 0.0,
      netPay: (json['netPay'] as num?)?.toDouble() ?? 0.0,
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

// ── Reports Models (Screen 12 API Integration) ──────────────────────────────

class AttendanceStatusSummaryItem {
  final String status;
  final int count;
  final double avgWorkingHours;

  const AttendanceStatusSummaryItem({
    required this.status,
    required this.count,
    this.avgWorkingHours = 0.0,
  });

  factory AttendanceStatusSummaryItem.fromJson(Map<String, dynamic> json) {
    return AttendanceStatusSummaryItem(
      status: json['_id']?.toString() ?? json['status']?.toString() ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
      avgWorkingHours: (json['avgWorkingHours'] as num?)?.toDouble() ?? 0.0,
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

  const AttendanceReportData({
    this.statusSummary = const [],
    this.departmentSummary = const [],
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
    );
  }

  int get totalPunches =>
      statusSummary.fold<int>(0, (sum, item) => sum + item.count);

  int get presentCount => statusSummary
      .where((s) => s.status.toUpperCase() == 'PRESENT')
      .fold<int>(0, (sum, item) => sum + item.count);

  int get lateCount => statusSummary
      .where((s) =>
          s.status.toUpperCase() == 'LATE' ||
          s.status.toUpperCase() == 'HALF_DAY')
      .fold<int>(0, (sum, item) => sum + item.count);

  int get onTimeCount =>
      presentCount - lateCount > 0 ? presentCount - lateCount : presentCount;

  double get overallAvgWorkingHours {
    if (statusSummary.isEmpty) return 0.0;
    final presentOrLate =
        statusSummary.where((s) => s.avgWorkingHours > 0).toList();
    if (presentOrLate.isEmpty) return 0.0;
    final totalWeighted = presentOrLate.fold<double>(
        0.0, (sum, item) => sum + (item.avgWorkingHours * item.count));
    final totalCount =
        presentOrLate.fold<int>(0, (sum, item) => sum + item.count);
    return totalCount > 0 ? totalWeighted / totalCount : 0.0;
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

  const LeaveReportData({
    this.statusSummary = const [],
    this.typeSummary = const [],
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
    );
  }

  int get totalApplications =>
      statusSummary.fold<int>(0, (sum, item) => sum + item.count);

  int get approvedCount => statusSummary
      .where((s) => s.status.toUpperCase() == 'APPROVED')
      .fold<int>(0, (sum, item) => sum + item.count);

  int get pendingCount => statusSummary
      .where((s) => s.status.toUpperCase() == 'PENDING')
      .fold<int>(0, (sum, item) => sum + item.count);

  int get rejectedCount => statusSummary
      .where((s) => s.status.toUpperCase() == 'REJECTED')
      .fold<int>(0, (sum, item) => sum + item.count);

  int get medicalCount => typeSummary
      .where((t) =>
          t.leaveType.toUpperCase() == 'SICK' ||
          t.leaveType.toUpperCase() == 'MEDICAL')
      .fold<int>(0, (sum, item) => sum + item.count);

  int get casualCount => typeSummary
      .where((t) => t.leaveType.toUpperCase() == 'CASUAL')
      .fold<int>(0, (sum, item) => sum + item.count);

  int get earnedCount => typeSummary
      .where((t) =>
          t.leaveType.toUpperCase() == 'ANNUAL' ||
          t.leaveType.toUpperCase() == 'EARNED')
      .fold<int>(0, (sum, item) => sum + item.count);
}
