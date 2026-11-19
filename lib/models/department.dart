import 'package:flutter/material.dart';

/// Model for a department entry returned by `GET /api/hr/departments`.
class Department {
  final String deptKey;
  final String title;
  final String subtitle;
  final int staffCount;
  final int activeCount;
  final String leadName;
  final String iconName;
  final String colorHex;

  const Department({
    required this.deptKey,
    required this.title,
    this.subtitle = '',
    this.staffCount = 0,
    this.activeCount = 0,
    this.leadName = '',
    this.iconName = 'business',
    this.colorHex = '#64748B',
  });

  /// Alias for staffCount matching backend totalMembers field
  int get totalMembers => staffCount;

  /// Alias for activeCount matching backend activeStaff field
  int get activeStaff => activeCount;

  /// Safely parse a department from the API JSON, with fallbacks for every field.
  factory Department.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    String parseString(dynamic v) {
      if (v == null) return '';
      final str = v.toString().trim();
      return (str == 'null' || str == 'undefined') ? '' : str;
    }

    return Department(
      deptKey: parseString(json['deptKey'] ?? json['id']),
      title: parseString(json['title'] ?? json['name']),
      subtitle: parseString(json['subtitle'] ?? json['description']),
      staffCount: parseInt(
          json['totalMembers'] ?? json['staffCount'] ?? json['totalStaff'] ?? json['memberCount']),
      activeCount: parseInt(json['activeStaff'] ?? json['activeCount']),
      leadName: parseString(json['leadName'] ?? json['leader'] ?? json['lead']),
      iconName: parseString(json['icon'] ?? 'business'),
      colorHex: parseString(json['color'] ?? '#64748B'),
    );
  }

  /// Convert the `icon` string from the API into a Flutter [IconData].
  /// Falls back to [Icons.business] for unknown values.
  IconData get icon => _iconMap[iconName.toLowerCase()] ?? Icons.business;

  /// Convert the `color` hex string from the API into a Flutter [Color].
  /// Falls back to slate-500 for invalid hex strings.
  Color get color {
    try {
      String hex = colorHex.replaceFirst('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      if (hex.length == 8) return Color(int.parse(hex, radix: 16));
    } catch (_) {}
    return const Color(0xFF64748B); // fallback: slate-500
  }

  /// Known icon string → IconData mapping (matches backend's `icon` field).
  static const Map<String, IconData> _iconMap = {
    'computer': Icons.computer,
    'headset_mic': Icons.headset_mic,
    'headset': Icons.headset_mic,
    'business': Icons.business,
    'engineering': Icons.engineering,
    'code': Icons.code,
    'support_agent': Icons.support_agent,
    'people': Icons.people,
    'settings': Icons.settings,
    'analytics': Icons.analytics,
    'design_services': Icons.design_services,
    'account_balance': Icons.account_balance,
    'work': Icons.work,
    'school': Icons.school,
    'security': Icons.security,
    'local_shipping': Icons.local_shipping,
    'phone': Icons.phone,
    'marketing': Icons.campaign,
    'campaign': Icons.campaign,
    'attach_money': Icons.attach_money,
    'shopping_cart': Icons.shopping_cart,
  };
}
