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
  });

  factory Staff.fromJson(Map<String, dynamic> json) {
    String resolvedName = (json['name'] ?? '').toString();
    if (resolvedName.isEmpty && (json['firstName'] != null || json['lastName'] != null)) {
      resolvedName = '${json['firstName'] ?? ''} ${json['lastName'] ?? ''}'.trim();
    }

    return Staff(
      id: (json['id'] ?? json['_id'] ?? json['employeeId'] ?? '').toString(),
      name: resolvedName,
      email: (json['email'] ?? '').toString(),
      phoneNumber: (json['phoneNumber'] ?? json['phone'] ?? '').toString(),
      department: (json['department'] ?? 'Unassigned').toString(),
      role: (json['role'] ?? json['designation'] ?? 'Staff').toString(),
      joinDate: (json['joinDate'] ?? json['joiningDate'] ?? '').toString(),
      status: (json['status'] ?? 'active').toString().toLowerCase(),
      onLeaveToday: json['onLeaveToday'] ?? false,
    );
  }
}
