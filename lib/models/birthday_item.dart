class BirthdayItem {
  final String id;
  final String employeeId;
  final String name;
  final String department;
  final String designation;
  final String? profileImage;
  final String birthdayFormatted;
  final int birthdayMonth;
  final int birthdayDay;
  final int daysUntil;
  final bool isToday;

  BirthdayItem({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.department,
    this.designation = '',
    this.profileImage,
    required this.birthdayFormatted,
    required this.birthdayMonth,
    required this.birthdayDay,
    this.daysUntil = 0,
    this.isToday = false,
  });

  factory BirthdayItem.fromJson(Map<String, dynamic> json) {
    return BirthdayItem(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      employeeId: json['employeeId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      department: json['department']?.toString() ?? 'Unassigned',
      designation: json['designation']?.toString() ?? '',
      profileImage: json['profileImage']?.toString(),
      birthdayFormatted: json['birthdayFormatted']?.toString() ?? '',
      birthdayMonth: (json['birthdayMonth'] is num)
          ? (json['birthdayMonth'] as num).toInt()
          : (int.tryParse(json['birthdayMonth']?.toString() ?? '1') ?? 1),
      birthdayDay: (json['birthdayDay'] is num)
          ? (json['birthdayDay'] as num).toInt()
          : (int.tryParse(json['birthdayDay']?.toString() ?? '1') ?? 1),
      daysUntil: (json['daysUntil'] is num)
          ? (json['daysUntil'] as num).toInt()
          : (int.tryParse(json['daysUntil']?.toString() ?? '0') ?? 0),
      isToday: json['isToday'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'name': name,
      'department': department,
      'designation': designation,
      'profileImage': profileImage,
      'birthdayFormatted': birthdayFormatted,
      'birthdayMonth': birthdayMonth,
      'birthdayDay': birthdayDay,
      'daysUntil': daysUntil,
      'isToday': isToday,
    };
  }
}
