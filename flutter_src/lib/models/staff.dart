class Staff {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String department;
  final String role;
  final String joinDate;
  final String status;
  final bool onLeaveToday;
  final String designation;
  final String workMode;
  final double salary;
  final String salaryCurrency;
  final String salaryEffectiveDate;
  final int paidLeaveAllowance;
  final List<SalaryHistoryItem> salaryHistory;
  final String dateOfBirth;

  Staff({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.department,
    required this.role,
    required this.joinDate,
    required this.status,
    required this.onLeaveToday,
    this.designation = '',
    this.workMode = 'Office',
    this.salary = 0.0,
    this.salaryCurrency = 'INR',
    this.salaryEffectiveDate = '',
    this.paidLeaveAllowance = 1,
    this.salaryHistory = const [],
    this.dateOfBirth = '',
  });

  factory Staff.fromJson(Map<String, dynamic> json) {
    final role = (json['role'] ??
            (json['user'] is Map ? json['user']['role'] : null) ??
            'Staff')
        .toString();
    final rawSalary = json['salary'];
    double parsedSalary = 0.0;
    if (rawSalary is num) {
      parsedSalary = rawSalary.toDouble();
    } else if (rawSalary != null) {
      parsedSalary = double.tryParse(rawSalary.toString()) ?? 0.0;
    }

    List<SalaryHistoryItem> history = [];
    if (json['salaryHistory'] is List) {
      history = (json['salaryHistory'] as List)
          .whereType<Map<String, dynamic>>()
          .map(SalaryHistoryItem.fromJson)
          .toList();
    }

    final rawName = json['name']?.toString().trim();
    final combinedName =
        '${json['firstName'] ?? ''} ${json['lastName'] ?? ''}'.trim();
    final name = (rawName != null && rawName.isNotEmpty)
        ? rawName
        : (combinedName.isNotEmpty
            ? combinedName
            : (json['email']?.toString() ?? 'Employee'));

    return Staff(
      id: (json['_id'] ?? json['id'] ?? json['employeeId'] ?? '').toString(),
      name: name,
      email: (json['email'] ?? '').toString(),
      phoneNumber: (json['phoneNumber'] ?? json['phone'] ?? '').toString(),
      department: (json['department'] ?? 'Unassigned').toString(),
      role: role.toString(),
      joinDate: (json['joinDate'] ?? json['joiningDate'] ?? '').toString(),
      status: (json['status'] ?? 'active').toString().toLowerCase(),
      onLeaveToday:
          json['onLeaveToday'] == true || json['status'] == 'ON_LEAVE',
      designation: (json['designation'] ?? role).toString(),
      workMode: (json['workMode'] ?? 'Office').toString(),
      salary: parsedSalary,
      salaryCurrency: (json['salaryCurrency'] ?? 'INR').toString(),
      salaryEffectiveDate: (json['salaryEffectiveDate'] ??
              json['joinDate'] ??
              json['joiningDate'] ??
              '')
          .toString(),
      paidLeaveAllowance:
          int.tryParse(json['paidLeaveAllowance']?.toString() ?? '') ?? 1,
      salaryHistory: history,
      dateOfBirth: json['dateOfBirth'] != null
          ? json['dateOfBirth'].toString().split('T')[0]
          : (json['dob']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'department': department,
      'role': role,
      'joinDate': joinDate,
      'status': status,
      'onLeaveToday': onLeaveToday,
      'designation': designation,
      'workMode': workMode,
      'salary': salary,
      'salaryCurrency': salaryCurrency,
      'salaryEffectiveDate': salaryEffectiveDate,
      'paidLeaveAllowance': paidLeaveAllowance,
      'salaryHistory': salaryHistory.map((h) => h.toJson()).toList(),
      'dateOfBirth': dateOfBirth,
    };
  }

  /// Returns friendly Birthday string (Month & Day only, hiding birth year from general public)
  String get birthdayFormatted {
    if (dateOfBirth.isEmpty) return '';
    try {
      final parts = dateOfBirth.split('-');
      if (parts.length >= 3) {
        final month = int.tryParse(parts[1]) ?? 1;
        final day = int.tryParse(parts[2]) ?? 1;
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
        return '${months[month - 1]} $day';
      }
    } catch (_) {}
    return dateOfBirth;
  }

  Staff copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? department,
    String? role,
    String? joinDate,
    String? status,
    bool? onLeaveToday,
    String? designation,
    String? workMode,
    double? salary,
    String? salaryCurrency,
    String? salaryEffectiveDate,
    int? paidLeaveAllowance,
    List<SalaryHistoryItem>? salaryHistory,
    String? dateOfBirth,
  }) {
    return Staff(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      department: department ?? this.department,
      role: role ?? this.role,
      joinDate: joinDate ?? this.joinDate,
      status: status ?? this.status,
      onLeaveToday: onLeaveToday ?? this.onLeaveToday,
      designation: designation ?? this.designation,
      workMode: workMode ?? this.workMode,
      salary: salary ?? this.salary,
      salaryCurrency: salaryCurrency ?? this.salaryCurrency,
      salaryEffectiveDate: salaryEffectiveDate ?? this.salaryEffectiveDate,
      paidLeaveAllowance: paidLeaveAllowance ?? this.paidLeaveAllowance,
      salaryHistory: salaryHistory ?? this.salaryHistory,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    );
  }
}

class SalaryHistoryItem {
  final double amount;
  final String currency;
  final String effectiveDate;
  final String changedBy;
  final String reason;
  final String timestamp;

  SalaryHistoryItem({
    required this.amount,
    this.currency = 'INR',
    required this.effectiveDate,
    required this.changedBy,
    this.reason = '',
    required this.timestamp,
  });

  factory SalaryHistoryItem.fromJson(Map<String, dynamic> json) {
    return SalaryHistoryItem(
      amount: (json['amount'] is num)
          ? (json['amount'] as num).toDouble()
          : (double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0),
      currency: json['currency'] ?? 'INR',
      effectiveDate: json['effectiveDate'] ?? '',
      changedBy: json['changedBy'] ?? 'HR Admin',
      reason: json['reason'] ?? '',
      timestamp: json['timestamp'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'currency': currency,
      'effectiveDate': effectiveDate,
      'changedBy': changedBy,
      'reason': reason,
      'timestamp': timestamp,
    };
  }
}
