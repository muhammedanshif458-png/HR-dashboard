/// Date and time formatting utilities for Asia/Kolkata timezone.
///
/// Converts UTC ISO timestamps and schedule strings into readable 12-hour
/// `hh:mm AM/PM` format and clean `YYYY-MM-DD` date strings.
library date_time_utils;

const Duration _kolkataOffset = Duration(hours: 5, minutes: 30);

/// Formats an employee joining date as `d MMM yyyy` without converting its
/// calendar date through a timezone. Invalid or absent dates use `—`.
String formatEmployeeJoiningDate(String? raw, {String fallback = '—'}) {
  if (raw == null) return fallback;
  final trimmed = raw.trim();
  if (trimmed.isEmpty || trimmed == '—' || trimmed.toLowerCase() == 'null') {
    return fallback;
  }

  final datePart = trimmed.split('T').first;
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(datePart);
  if (match == null) return fallback;
  if (trimmed.contains('T') && DateTime.tryParse(trimmed) == null) {
    return fallback;
  }

  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final date = DateTime(year, month, day);
  if (date.year != year || date.month != month || date.day != day) {
    return fallback;
  }

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
    'Dec',
  ];
  return '$day ${months[month - 1]} $year';
}

/// Converts a given DateTime [dt] to Asia/Kolkata (UTC+05:30) representation.
DateTime toKolkataTime(DateTime dt) {
  if (dt.isUtc) {
    return dt.add(_kolkataOffset);
  }
  // If the DateTime is local or parsed with an explicit offset, converting to
  // UTC first guarantees we correctly apply the +05:30 Kolkata offset without
  // double-converting or relying on the client machine's local timezone.
  return dt.toUtc().add(_kolkataOffset);
}

/// Parses a date or timestamp string and returns the date in `YYYY-MM-DD` format.
///
/// Prevents raw timestamps from leaking into date columns.
String formatAttendanceDate(String? raw, {String fallback = '—'}) {
  if (raw == null) return fallback;
  final trimmed = raw.trim();
  if (trimmed.isEmpty || trimmed == '—' || trimmed.toLowerCase() == 'null') {
    return fallback;
  }

  // Validate date part ranges if structured as YYYY-MM-DD
  final isoDateMatch =
      RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(trimmed);
  if (isoDateMatch != null) {
    final m = int.tryParse(isoDateMatch.group(2)!);
    final d = int.tryParse(isoDateMatch.group(3)!);
    if (m == null || d == null || m < 1 || m > 12 || d < 1 || d > 31) {
      return fallback;
    }
  }

  // If it's already a clean YYYY-MM-DD date, return it directly.
  final dateOnlyRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  if (dateOnlyRegex.hasMatch(trimmed)) {
    return trimmed;
  }

  // If it's an ISO timestamp, parse it and extract the Kolkata date.
  final parsed = DateTime.tryParse(trimmed);
  if (parsed != null) {
    final hasTz = trimmed.endsWith('Z') ||
        trimmed.endsWith('z') ||
        RegExp(r'[+-]\d{2}(?::?\d{2})?$').hasMatch(trimmed);

    final DateTime target = hasTz ? toKolkataTime(parsed) : parsed;
    final year = target.year.toString().padLeft(4, '0');
    final month = target.month.toString().padLeft(2, '0');
    final day = target.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  // Fallback to splitting by 'T' if it looks like an ISO-like string.
  if (trimmed.contains('T')) {
    final datePart = trimmed.split('T')[0];
    if (dateOnlyRegex.hasMatch(datePart)) {
      return datePart;
    }
  }

  return fallback;
}

/// Formats a check-in, check-out, or schedule time into `hh:mm AM/PM` format.
///
/// Handles:
/// - UTC ISO timestamps (e.g., `2026-10-26T05:33:16.627Z` → `11:03 AM`)
/// - Offsets timestamps (e.g., `2026-10-26T11:03:16.627+05:30` → `11:03 AM`)
/// - Schedule-only 24h strings (e.g., `10:00` → `10:00 AM`, `17:30` → `05:30 PM`)
/// - Already formatted 12h strings (e.g., `9:10 AM` → `09:10 AM`)
/// - Returns [fallback] for null, empty, or unparseable inputs.
String formatAttendanceTime(String? raw, {String fallback = '—'}) {
  final formatted = formatAttendanceTimeNullable(raw);
  return formatted ?? fallback;
}

/// Nullable version of [formatAttendanceTime].
/// Returns `null` if the input is null, empty, or unparseable.
String? formatAttendanceTimeNullable(String? raw) {
  if (raw == null) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty || trimmed == '—' || trimmed.toLowerCase() == 'null') {
    return null;
  }

  // 1. Check if it's already an AM/PM formatted time: e.g. "11:03 AM", "9:10 am"
  final amPmMatch =
      RegExp(r'^\s*(\d{1,2}):(\d{2})(?::\d{2})?\s*(AM|PM|am|pm)\s*$')
          .firstMatch(trimmed);
  if (amPmMatch != null) {
    final hour = int.tryParse(amPmMatch.group(1)!);
    final minute = int.tryParse(amPmMatch.group(2)!);
    final period = amPmMatch.group(3)!.toUpperCase();
    if (hour != null &&
        minute != null &&
        hour >= 1 &&
        hour <= 12 &&
        minute >= 0 &&
        minute <= 59) {
      final hh = hour.toString().padLeft(2, '0');
      final mm = minute.toString().padLeft(2, '0');
      return '$hh:$mm $period';
    }
  }

  // 2. Check for schedule-only time of day: e.g. "10:00", "09:00", "17:30", "09:00:00"
  // Do NOT treat these as UTC timestamps (which would shift them by +5:30).
  final timeOfDayMatch =
      RegExp(r'^\s*(\d{1,2}):(\d{2})(?::(\d{2}))?\s*$').firstMatch(trimmed);
  if (timeOfDayMatch != null) {
    final hour = int.tryParse(timeOfDayMatch.group(1)!);
    final minute = int.tryParse(timeOfDayMatch.group(2)!);
    if (hour != null &&
        minute != null &&
        hour >= 0 &&
        hour <= 23 &&
        minute >= 0 &&
        minute <= 59) {
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour % 12 == 0 ? 12 : hour % 12;
      final hh = displayHour.toString().padLeft(2, '0');
      final mm = minute.toString().padLeft(2, '0');
      return '$hh:$mm $period';
    }
  }

  // 3. Check for full ISO timestamp (e.g. 2026-10-26T05:33:16.627Z)
  // Validate that hour, minute, second parts are within reasonable boundaries
  // because Dart's DateTime.tryParse leniently rolls over out-of-range values.
  final isoPartsMatch =
      RegExp(r'[T ](\d{1,2}):(\d{2})(?::(\d{2}))?').firstMatch(trimmed);
  if (isoPartsMatch != null) {
    final rawH = int.tryParse(isoPartsMatch.group(1)!);
    final rawM = int.tryParse(isoPartsMatch.group(2)!);
    final rawS = isoPartsMatch.group(3) != null
        ? int.tryParse(isoPartsMatch.group(3)!)
        : 0;
    if (rawH == null ||
        rawM == null ||
        rawH > 23 ||
        rawM > 59 ||
        (rawS != null && rawS > 59)) {
      return null;
    }
  }

  final parsed = DateTime.tryParse(trimmed);
  if (parsed != null) {
    final hasExplicitTz = trimmed.endsWith('Z') ||
        trimmed.endsWith('z') ||
        RegExp(r'[+-]\d{2}(?::?\d{2})?$').hasMatch(trimmed);

    // If it has a timezone indicator (like 'Z' or '+05:30'), convert to Kolkata time.
    // If it does not have a timezone indicator, it's already in local time; use as-is.
    final target = hasExplicitTz ? toKolkataTime(parsed) : parsed;
    final hour = target.hour;
    final minute = target.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    final hh = displayHour.toString().padLeft(2, '0');
    final mm = minute.toString().padLeft(2, '0');
    return '$hh:$mm $period';
  }

  return null;
}
