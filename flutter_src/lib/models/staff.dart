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
    return Staff(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      department: json['department'] ?? 'Unassigned',
      role: json['role'] ?? 'Staff',
      joinDate: json['joinDate'] ?? '',
      status: json['status'] ?? 'active',
      onLeaveToday: json['onLeaveToday'] ?? false,
    );
  }
}
