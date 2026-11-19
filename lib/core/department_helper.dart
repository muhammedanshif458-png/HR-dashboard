import 'package:flutter/material.dart';
import '../models/department.dart';
import '../models/staff.dart';

/// Helper for department normalization, deduplication, and safe dropdown resolution.
/// Enforces that department selection controls display strictly 'Tech' and 'Telecalling'.
/// Guarantees that any dropdown value matches exactly one item in its items list.
class DepartmentHelper {
  static const String allDepartmentsValue = 'all';
  static const String allDepartmentsLabel = 'All Departments';

  static const String defaultTechTitle = 'Tech';
  static const String defaultTelecallingTitle = 'Telecalling';

  static const String tech = 'Tech';
  static const String telecalling = 'Telecalling';

  /// The only two supported department options across the entire dashboard
  static const List<String> supportedDepartments = [
    tech,
    telecalling,
  ];

  /// Standard organizational departments recognized across the dashboard
  static const List<String> standardDepartmentNames = [
    tech,
    telecalling,
  ];

  /// Normalize department name to a stable comparison key
  static String normalize(String dept) {
    final clean = dept.trim().toLowerCase();
    if (clean == 'all') return 'all';
    if (clean == 'tech' ||
        clean.contains('tech') ||
        clean.contains('engineering')) {
      return 'tech';
    }
    if (clean == 'telecalling' ||
        clean.contains('tele') ||
        clean.contains('client')) {
      return 'telecalling';
    }
    return clean;
  }

  /// Check if two department strings refer to the same department
  static bool areSameDepartment(String? a, String? b) {
    if (a == null || b == null) return a == b;
    final cleanA = a.trim();
    final cleanB = b.trim();
    if (cleanA.toLowerCase() == cleanB.toLowerCase()) return true;
    return normalize(cleanA) == normalize(cleanB);
  }

  /// Returns 'Tech' or 'Telecalling' if matching supported departments,
  /// otherwise preserves the original department string (e.g. legacy department).
  static String toSupportedCanonicalName(String dept) {
    final norm = normalize(dept);
    if (norm == 'tech') return tech;
    if (norm == 'telecalling') return telecalling;
    return dept.trim();
  }

  /// Deduplicate Department model objects by both deptKey and title (case-insensitive).
  /// Preserves the first encountered instance of each unique department.
  static List<Department> deduplicateDepartments(List<Department> list) {
    final seenKeys = <String>{};
    final seenTitles = <String>{};
    final result = <Department>[];

    for (final dept in list) {
      final key = dept.deptKey.trim().toLowerCase();
      final title = dept.title.trim().toLowerCase();
      if (key.isNotEmpty && seenKeys.contains(key)) continue;
      if (title.isNotEmpty && seenTitles.contains(title)) continue;
      if (key.isNotEmpty) seenKeys.add(key);
      if (title.isNotEmpty) seenTitles.add(title);
      result.add(dept);
    }
    return result;
  }

  /// Deduplicate department names case-insensitively while preserving original casing
  static List<String> deduplicateNames(Iterable<String> names) {
    final seen = <String>{};
    final result = <String>[];
    for (final name in names) {
      final trimmed = name.trim();
      if (trimmed.isEmpty) continue;
      if (seen.add(trimmed.toLowerCase())) {
        result.add(trimmed);
      }
    }
    return result;
  }

  /// Get comprehensive list of department options for employee creation/editing.
  /// Strictly offers Tech and Telecalling, plus existing legacy department if present.
  static List<String> getFormDepartmentOptions({
    required List<Department> departments,
    List<Staff>? staffList,
    String? currentDepartment,
  }) {
    final names = <String>[tech, telecalling];
    if (currentDepartment != null && currentDepartment.trim().isNotEmpty) {
      final normalized = normalize(currentDepartment);
      if (normalized != 'tech' && normalized != 'telecalling') {
        names.add(currentDepartment.trim());
      }
    }
    return deduplicateNames(names);
  }

  /// Safely builds dropdown items and resolves selected value for filter dropdowns.
  /// Only contains 'All Departments', 'Tech', and 'Telecalling'.
  /// Guarantees that selected value exists in items exactly ONCE.
  static SafeDropdownData<String> buildFilterDropdown({
    required String? currentValue,
    required List<Department> departments,
    bool isLoading = false,
    String? error,
    String allValue = allDepartmentsValue,
    String allLabel = allDepartmentsLabel,
    List<String>? additionalDepartments,
  }) {
    final items = <DropdownMenuItem<String>>[];
    final seenValues = <String>{};

    void addItem(String val, String label) {
      if (seenValues.add(val)) {
        items.add(DropdownMenuItem<String>(
          value: val,
          child: Text(label),
        ));
      }
    }

    // 1. Always add "All Departments" option
    addItem(allValue, allLabel);

    // 2. Add ONLY the supported departments: Tech and Telecalling
    addItem(tech, tech);
    addItem(telecalling, telecalling);

    // 3. Resolve the safe selected value
    String safeValue = allValue;
    final reqVal = (currentValue ?? '').trim();

    if (reqVal.isNotEmpty && reqVal.toLowerCase() != 'all') {
      final normalized = normalize(reqVal);
      if (normalized == 'tech') {
        safeValue = tech;
      } else if (normalized == 'telecalling') {
        safeValue = telecalling;
      } else {
        // Fallback safely to allValue for unsupported legacy filters to avoid assertion and show all records
        safeValue = allValue;
      }
    }

    // Final sanity check: ensure safeValue matches exactly one item in items
    final matches = items.where((i) => i.value == safeValue).length;
    if (matches != 1) {
      safeValue = allValue;
    }

    return SafeDropdownData<String>(value: safeValue, items: items);
  }

  /// Safely builds dropdown items and resolves selected value for form dropdowns (Add/Edit staff).
  /// Strictly offers Tech and Telecalling.
  /// If the current employee has a legacy department, it is preserved with a clear '(Legacy)' label
  /// so that their department is never silently modified unless explicitly changed by the user.
  /// Guarantees that selected value exists in items exactly ONCE.
  static SafeDropdownData<String> buildFormDepartmentDropdown({
    required String? currentValue,
    required List<Department> departments,
    List<Staff>? staffList,
    String defaultFallback = tech,
  }) {
    final items = <DropdownMenuItem<String>>[];
    final seenValues = <String>{};

    void addItem(String val, String label) {
      if (seenValues.add(val)) {
        items.add(DropdownMenuItem<String>(
          value: val,
          child: Text(label),
        ));
      }
    }

    // 1. Add the two supported options: Tech and Telecalling
    addItem(tech, tech);
    addItem(telecalling, telecalling);

    // 2. Resolve safeValue and handle legacy values safely
    final reqVal = (currentValue ?? '').trim();
    String safeValue = defaultFallback;

    if (reqVal.isNotEmpty) {
      final normalized = normalize(reqVal);
      if (normalized == 'tech') {
        safeValue = tech;
      } else if (normalized == 'telecalling') {
        safeValue = telecalling;
      } else {
        // Legacy department (e.g. "Operations", "Finance", "Design", "HR")
        // Requirement 6: Do not silently change an employee's existing department
        // just because it is not one of the two options. For edit forms, handle
        // legacy department values safely and clearly.
        addItem(reqVal, '$reqVal (Legacy)');
        safeValue = reqVal;
      }
    } else {
      safeValue = defaultFallback;
    }

    // Final sanity check: ensure safeValue matches exactly one item
    final matches = items.where((i) => i.value == safeValue).length;
    if (matches != 1) {
      if (items.isNotEmpty) {
        safeValue = items.first.value!;
      } else {
        addItem(defaultFallback, defaultFallback);
        safeValue = defaultFallback;
      }
    }

    return SafeDropdownData<String>(value: safeValue, items: items);
  }
}

/// Return type holding a validated value and unique items list for DropdownButton
class SafeDropdownData<T> {
  final T value;
  final List<DropdownMenuItem<T>> items;

  const SafeDropdownData({required this.value, required this.items});
}
