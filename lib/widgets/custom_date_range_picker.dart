import 'package:flutter/material.dart';

/// Shows a custom modern date range picker dialog matching the HR Management Portal design reference.
///
/// Returns the selected [DateTimeRange] or `null` if cancelled or dismissed.
Future<DateTimeRange?> showCustomDateRangePicker({
  required BuildContext context,
  DateTime? firstDate,
  DateTime? lastDate,
  DateTimeRange? initialDateRange,
}) async {
  return showDialog<DateTimeRange?>(
    context: context,
    barrierColor: const Color(0x40000000),
    barrierDismissible: true,
    builder: (ctx) => CustomDateRangePickerDialog(
      firstDate: firstDate ?? DateTime(2020),
      lastDate: lastDate ?? DateTime(2030),
      initialDateRange: initialDateRange,
    ),
  );
}

class CustomDateRangePickerDialog extends StatefulWidget {
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTimeRange? initialDateRange;

  const CustomDateRangePickerDialog({
    super.key,
    required this.firstDate,
    required this.lastDate,
    this.initialDateRange,
  });

  @override
  State<CustomDateRangePickerDialog> createState() =>
      _CustomDateRangePickerDialogState();
}

class _PresetOption {
  final String label;
  final DateTime start;
  final DateTime end;

  const _PresetOption({
    required this.label,
    required this.start,
    required this.end,
  });
}

class _CustomDateRangePickerDialogState
    extends State<CustomDateRangePickerDialog> {
  DateTime? _startDate;
  DateTime? _endDate;
  late DateTime _firstMonth;

  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const List<String> _shortMonthNames = [
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

  static const List<String> _weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  void initState() {
    super.initState();
    if (widget.initialDateRange != null) {
      _startDate = DateTime(
        widget.initialDateRange!.start.year,
        widget.initialDateRange!.start.month,
        widget.initialDateRange!.start.day,
      );
      _endDate = DateTime(
        widget.initialDateRange!.end.year,
        widget.initialDateRange!.end.month,
        widget.initialDateRange!.end.day,
      );
      _firstMonth = DateTime(_startDate!.year, _startDate!.month, 1);
    } else {
      final now = DateTime.now();
      _firstMonth = DateTime(now.year, now.month, 1);
    }
  }

  DateTime get _secondMonth =>
      DateTime(_firstMonth.year, _firstMonth.month + 1, 1);

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isBetween(DateTime target, DateTime? start, DateTime? end) {
    if (start == null || end == null) return false;
    final t = DateTime(target.year, target.month, target.day);
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    return t.isAfter(s) && t.isBefore(e);
  }

  void _onDateTapped(DateTime date) {
    setState(() {
      final normalized = DateTime(date.year, date.month, date.day);
      if (_startDate == null || (_startDate != null && _endDate != null)) {
        _startDate = normalized;
        _endDate = null;
      } else {
        // _startDate is set, _endDate is null
        if (normalized.isBefore(_startDate!)) {
          _startDate = normalized;
          _endDate = null;
        } else {
          _endDate = normalized;
        }
      }
    });
  }

  List<_PresetOption> _generatePresets() {
    final base = _firstMonth;
    final now = DateTime.now();

    // 1. Today
    final today = DateTime(now.year, now.month, now.day);

    // 2. This Week (Sunday - Saturday)
    final dayOfWeek = today.weekday % 7; // Sunday=0, Monday=1...
    final weekStart = today.subtract(Duration(days: dayOfWeek));
    final weekEnd = weekStart.add(const Duration(days: 6));

    // 3. Month 1
    final m1Start = DateTime(base.year, base.month, 1);
    final m1End = DateTime(base.year, base.month + 1, 0);

    // 4. Month 2
    final m2 = DateTime(base.year, base.month + 1, 1);
    final m2Start = DateTime(m2.year, m2.month, 1);
    final m2End = DateTime(m2.year, m2.month + 1, 0);

    // 5. Quarter
    final quarter = ((base.month - 1) ~/ 3) + 1;
    final qStartMonth = (quarter - 1) * 3 + 1;
    final qStart = DateTime(base.year, qStartMonth, 1);
    final qEnd = DateTime(base.year, qStartMonth + 3, 0);

    return [
      _PresetOption(
        label: 'Today',
        start: today,
        end: today,
      ),
      _PresetOption(
        label: 'This Week',
        start: weekStart,
        end: weekEnd,
      ),
      _PresetOption(
        label: '${_monthNames[m1Start.month - 1]} ${m1Start.year}',
        start: m1Start,
        end: m1End,
      ),
      _PresetOption(
        label: '${_monthNames[m2Start.month - 1]} ${m2Start.year}',
        start: m2Start,
        end: m2End,
      ),
      _PresetOption(
        label: 'Q$quarter ${base.year}',
        start: qStart,
        end: qEnd,
      ),
    ];
  }

  bool _matchesPreset(_PresetOption preset) {
    if (_startDate == null || _endDate == null) return false;
    return _isSameDay(_startDate, preset.start) &&
        _isSameDay(_endDate, preset.end);
  }

  void _applyPreset(_PresetOption preset) {
    setState(() {
      _startDate = preset.start;
      _endDate = preset.end;
      _firstMonth = DateTime(preset.start.year, preset.start.month, 1);
    });
  }

  void _shiftMonth(int delta) {
    setState(() {
      _firstMonth = DateTime(_firstMonth.year, _firstMonth.month + delta, 1);
    });
  }

  String _formatDateShort(DateTime d) {
    return '${_shortMonthNames[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _formatDateHeader(DateTime d) {
    return '${_shortMonthNames[d.month - 1]} ${d.day}';
  }

  int? get _daysCount {
    if (_startDate == null) return null;
    final end = _endDate ?? _startDate!;
    return end.difference(_startDate!).inDays + 1;
  }

  @override
  Widget build(BuildContext context) {
    final presets = _generatePresets();
    final count = _daysCount;

    String headerRangeText;
    if (_startDate != null && _endDate != null) {
      headerRangeText =
          '${_formatDateShort(_startDate!)} – ${_formatDateShort(_endDate!)}';
    } else if (_startDate != null) {
      headerRangeText = '${_formatDateShort(_startDate!)} – Select End Date';
    } else {
      headerRangeText = 'Select Date Range';
    }

    String footerRangeText;
    if (_startDate != null && _endDate != null) {
      footerRangeText =
          '${_formatDateHeader(_startDate!)} – ${_formatDateShort(_endDate!)}';
    } else if (_startDate != null) {
      footerRangeText = _formatDateShort(_startDate!);
    } else {
      footerRangeText = 'None';
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      elevation: 0,
      child: Center(
        child: RepaintBoundary(
          key: const ValueKey('custom_date_range_dialog_boundary'),
          child: Container(
            width: 540,
            constraints: const BoxConstraints(maxHeight: 780),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1E000000),
                blurRadius: 36,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Action Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Row(
                  children: [
                    InkWell(
                      key: const ValueKey('custom_date_range_close_button'),
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      key: const ValueKey('custom_date_range_save_button'),
                      onPressed: () {
                        if (_startDate != null) {
                          Navigator.of(context).pop(DateTimeRange(
                            start: _startDate!,
                            end: _endDate ?? _startDate!,
                          ));
                        } else {
                          Navigator.of(context).pop(null);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Title & Range Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SELECT RANGE',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            headerRangeText,
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (count != null) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Text(
                              '$count ${count == 1 ? 'Day' : 'Days'}',
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Preset Filter Pills
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: presets.map((preset) {
                      final isSelected = _matchesPreset(preset);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          key: ValueKey('date_preset_${preset.label}'),
                          onTap: () => _applyPreset(preset),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6.5),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Text(
                              preset.label,
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Calendars Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Month 1
                      _buildMonthCard(
                        month: _firstMonth,
                        showPrev: true,
                        showNext: true,
                        onPrev: () => _shiftMonth(-1),
                        onNext: () => _shiftMonth(1),
                      ),
                      const SizedBox(height: 16),
                      // Month 2
                      _buildMonthCard(
                        month: _secondMonth,
                        showPrev: false,
                        showNext: true,
                        onPrev: null,
                        onNext: () => _shiftMonth(1),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              const Divider(height: 1, color: Color(0xFFF1F5F9)),

              // Bottom Footer
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
                child: Row(
                  children: [
                    const Icon(
                      Icons.date_range_outlined,
                      size: 17,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Selected: ',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 12.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          Flexible(
                            child: Text(
                              footerRangeText,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      key: const ValueKey('custom_date_range_clear_button'),
                      onPressed: () {
                        setState(() {
                          _startDate = null;
                          _endDate = null;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF475569),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Clear',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      key: const ValueKey('custom_date_range_apply_button'),
                      onPressed: () {
                        if (_startDate != null) {
                          Navigator.of(context).pop(DateTimeRange(
                            start: _startDate!,
                            end: _endDate ?? _startDate!,
                          ));
                        } else {
                          Navigator.of(context).pop(null);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Apply Range',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildMonthCard({
    required DateTime month,
    required bool showPrev,
    required bool showNext,
    VoidCallback? onPrev,
    VoidCallback? onNext,
  }) {
    final monthName = _monthNames[month.month - 1];
    final year = month.year;

    final daysInMonth = DateTime(year, month.month + 1, 0).day;
    final leadingBlanks = DateTime(year, month.month, 1).weekday % 7;

    final List<Widget> dayRows = [];
    List<Widget> currentRow = [];

    // Add empty placeholders before 1st of month
    for (int i = 0; i < leadingBlanks; i++) {
      currentRow.add(const Expanded(child: SizedBox(height: 36)));
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final cellDate = DateTime(year, month.month, day);
      currentRow.add(
        Expanded(
          child: _buildDayCell(cellDate),
        ),
      );

      if (currentRow.length == 7) {
        dayRows.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(children: currentRow),
          ),
        );
        currentRow = [];
      }
    }

    if (currentRow.isNotEmpty) {
      while (currentRow.length < 7) {
        currentRow.add(const Expanded(child: SizedBox(height: 36)));
      }
      dayRows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(children: currentRow),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Month Header Row
          Row(
            children: [
              Text(
                '$monthName $year',
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              if (showPrev) ...[
                InkWell(
                  key: ValueKey('month_prev_${month.month}'),
                  onTap: onPrev,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.chevron_left_rounded,
                      size: 16,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              if (showNext)
                InkWell(
                  key: ValueKey('month_next_${month.month}'),
                  onTap: onNext,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Weekdays Row
          Row(
            children: _weekdays.map((w) {
              return Expanded(
                child: Center(
                  child: Text(
                    w,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 6),

          // Day Grid Rows
          ...dayRows,
        ],
      ),
    );
  }

  Widget _buildDayCell(DateTime cellDate) {
    final isStart = _isSameDay(cellDate, _startDate);
    final isEnd = _isSameDay(cellDate, _endDate);
    final isInRange = _isBetween(cellDate, _startDate, _endDate);
    final hasRange = _startDate != null &&
        _endDate != null &&
        !_isSameDay(_startDate, _endDate);

    const bandColor = Color(0xFFE8F1FC);

    return InkWell(
      key: ValueKey('date_cell_${cellDate.year}_${cellDate.month}_${cellDate.day}'),
      onTap: () => _onDateTapped(cellDate),
      child: SizedBox(
        height: 36,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background Range Band
            if (hasRange && isInRange)
              Positioned.fill(
                child: Container(
                  color: bandColor,
                ),
              ),

            if (hasRange && isStart)
              Positioned(
                left: 0.5,
                right: 0,
                top: 0,
                bottom: 0,
                child: Row(
                  children: [
                    const Expanded(child: SizedBox()),
                    Expanded(
                      child: Container(
                        color: bandColor,
                      ),
                    ),
                  ],
                ),
              ),

            if (hasRange && isEnd)
              Positioned(
                left: 0,
                right: 0.5,
                top: 0,
                bottom: 0,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        color: bandColor,
                      ),
                    ),
                    const Expanded(child: SizedBox()),
                  ],
                ),
              ),

            // Indicator Circle / Text
            if (isStart)
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFF0F172A),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${cellDate.day}',
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              )
            else if (isEnd)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF0F172A),
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${cellDate.day}',
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              )
            else
              Text(
                '${cellDate.day}',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 12.5,
                  fontWeight:
                      isInRange ? FontWeight.w600 : FontWeight.w500,
                  color: isInRange
                      ? const Color(0xFF0F172A)
                      : const Color(0xFF334155),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
