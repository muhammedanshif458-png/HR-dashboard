import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/hr_provider.dart';
import '../../models/hr_models.dart';
import '../../core/department_helper.dart';
import '../../widgets/header.dart';
import '../../widgets/sidebar.dart';

class TasksView extends StatefulWidget {
  const TasksView({super.key});

  @override
  State<TasksView> createState() => _TasksViewState();
}

class _TasksViewState extends State<TasksView> {
  late final TextEditingController _searchController;
  bool _isSelectionMode = false;
  final Set<String> _selectedUpdateIds = <String>{};

  @override
  void initState() {
    super.initState();
    final hrProvider = context.read<HRProvider>();
    _searchController =
        TextEditingController(text: hrProvider.dailyUpdatesSearchQuery);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!hrProvider.isDailyUpdatesLoading) {
        hrProvider.loadDailyUpdates();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatTime(String rawTime) {
    try {
      final dt = DateTime.parse(rawTime).toLocal();
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    } catch (_) {
      return rawTime;
    }
  }

  Future<void> _confirmClearSelected(
      BuildContext context, HRProvider hrProvider) async {
    final count = _selectedUpdateIds.length;
    if (count == 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.delete_outline, color: Color(0xFFDC2626), size: 24),
              SizedBox(width: 8),
              Text('Clear Selected Updates'),
            ],
          ),
          content: Text(
            'Are you sure you want to permanently delete $count selected daily work update(s)?\n\n'
            'This action cannot be undone. These records will be permanently removed.',
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: Text('Delete $count Update(s)'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      final idsToDelete = _selectedUpdateIds.toList();
      final success = await hrProvider.bulkDeleteDailyUpdates(idsToDelete);
      if (mounted) {
        if (success) {
          setState(() {
            _selectedUpdateIds.clear();
            if (hrProvider.filteredDailyUpdates.isEmpty) {
              _isSelectionMode = false;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully deleted $count daily work update(s).'),
              backgroundColor: const Color(0xFF16A34A),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Failed to delete updates: ${hrProvider.dailyUpdatesDeleteError ?? "Unknown error"}'),
              backgroundColor: const Color(0xFFDC2626),
            ),
          );
        }
      }
    }
  }

  Future<void> _confirmClearAll(
      BuildContext context, HRProvider hrProvider) async {
    final totalCount = hrProvider.dailyUpdatesTotal > 0
        ? hrProvider.dailyUpdatesTotal
        : hrProvider.apiDailyUpdatesList.length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        bool hasConfirmedCheckbox = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: const [
                  Icon(Icons.warning_amber_rounded,
                      color: Color(0xFFDC2626), size: 26),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Clear All Daily Work Updates'),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Text(
                      'WARNING: This will permanently delete ALL $totalCount staff daily work update records across all departments.\n\n'
                      'This operation is permanent and cannot be undone.',
                      style: const TextStyle(
                        color: Color(0xFF991B1B),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    key: const ValueKey('confirm_clear_all_checkbox'),
                    value: hasConfirmedCheckbox,
                    activeColor: const Color(0xFFDC2626),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(
                      'I confirm that I want to permanently delete all $totalCount updates.',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    onChanged: (val) {
                      setDialogState(() {
                        hasConfirmedCheckbox = val ?? false;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  key: const ValueKey('confirm_clear_all_btn'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: hasConfirmedCheckbox
                      ? () => Navigator.of(dialogCtx).pop(true)
                      : null,
                  child: const Text('Permanently Clear All'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true && mounted) {
      final success = await hrProvider.clearAllDailyUpdates();
      if (mounted) {
        if (success) {
          setState(() {
            _selectedUpdateIds.clear();
            _isSelectionMode = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('All daily work updates have been permanently cleared.'),
              backgroundColor: Color(0xFF16A34A),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Failed to clear updates: ${hrProvider.dailyUpdatesDeleteError ?? "Unknown error"}'),
              backgroundColor: const Color(0xFFDC2626),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hrProvider = context.watch<HRProvider>();
    final updates = hrProvider.filteredDailyUpdates;

    final hasActiveFilter = hrProvider.dailyUpdatesDeptFilter != 'all' ||
        hrProvider.dailyUpdatesSearchQuery.trim().isNotEmpty;

    return Scaffold(
      appBar: const Header(),
      drawer: const AppSidebar(isDrawer: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LY SOFTWARE • WORKFORCE OPERATIONS',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Staff Daily Work Updates',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Review daily work updates and progress logs submitted by staff.',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Refresh Updates',
                      onPressed: hrProvider.isDailyUpdatesLoading ||
                              hrProvider.isDailyUpdatesDeleting
                          ? null
                          : () => hrProvider.loadDailyUpdates(),
                      icon: hrProvider.isDailyUpdatesLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh, color: Color(0xFF2563EB)),
                    ),
                    const SizedBox(width: 8),
                    if (!_isSelectionMode) ...[
                      OutlinedButton.icon(
                        key: const ValueKey('select_updates_btn'),
                        icon: const Icon(Icons.checklist, size: 18),
                        label: const Text('Select Updates'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2563EB),
                          side: const BorderSide(color: Color(0xFF2563EB)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                        ),
                        onPressed: updates.isEmpty
                            ? null
                            : () {
                                setState(() {
                                  _isSelectionMode = true;
                                  _selectedUpdateIds.clear();
                                });
                              },
                      ),
                      const SizedBox(width: 8),
                    ],
                    PopupMenuButton<String>(
                      key: const ValueKey('daily_updates_more_menu'),
                      tooltip: 'More actions',
                      icon:
                          const Icon(Icons.more_vert, color: Color(0xFF64748B)),
                      onSelected: (val) {
                        if (val == 'clear_all') {
                          _confirmClearAll(context, hrProvider);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem<String>(
                          value: 'clear_all',
                          enabled: (hrProvider.dailyUpdatesTotal > 0 ||
                                  hrProvider.apiDailyUpdatesList.isNotEmpty) &&
                              !hrProvider.isDailyUpdatesDeleting,
                          child: const Row(
                            children: [
                              Icon(Icons.delete_sweep_outlined,
                                  color: Color(0xFFDC2626), size: 20),
                              SizedBox(width: 10),
                              Text(
                                'Clear All Updates',
                                style: TextStyle(
                                  color: Color(0xFFDC2626),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Selection Mode Action Bar (Requirements 2, 4, 6, 7)
            if (_isSelectionMode) ...[
              Container(
                key: const ValueKey('selection_mode_bar'),
                margin: const EdgeInsets.only(bottom: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_outline,
                            color: Color(0xFF2563EB), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${_selectedUpdateIds.length} of ${updates.length} selected',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Select All / Deselect All
                        OutlinedButton.icon(
                          key: const ValueKey('select_all_btn'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0F172A),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          onPressed: () {
                            setState(() {
                              if (_selectedUpdateIds.length == updates.length &&
                                  updates.isNotEmpty) {
                                _selectedUpdateIds.clear();
                              } else {
                                _selectedUpdateIds
                                    .addAll(updates.map((u) => u.id));
                              }
                            });
                          },
                          icon: Icon(
                            _selectedUpdateIds.length == updates.length &&
                                    updates.isNotEmpty
                                ? Icons.deselect
                                : Icons.select_all,
                            size: 16,
                          ),
                          label: Text(
                            _selectedUpdateIds.length == updates.length &&
                                    updates.isNotEmpty
                                ? 'Deselect All'
                                : 'Select All',
                          ),
                        ),
                        // Clear Selected
                        ElevatedButton.icon(
                          key: const ValueKey('clear_selected_btn'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 9),
                          ),
                          onPressed: _selectedUpdateIds.isEmpty ||
                                  hrProvider.isDailyUpdatesDeleting
                              ? null
                              : () =>
                                  _confirmClearSelected(context, hrProvider),
                          icon: hrProvider.isDailyUpdatesDeleting
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.delete_outline, size: 16),
                          label: Text(
                              'Clear Selected (${_selectedUpdateIds.length})'),
                        ),
                        // Exit Selection Mode
                        TextButton(
                          key: const ValueKey('exit_selection_btn'),
                          onPressed: () {
                            setState(() {
                              _isSelectionMode = false;
                              _selectedUpdateIds.clear();
                            });
                          },
                          child: const Text('Exit Selection Mode'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            // Error Banner
            if (hrProvider.dailyUpdatesError != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Color(0xFFDC2626), size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Failed to load updates from server: ${hrProvider.dailyUpdatesError}',
                        style: const TextStyle(
                          color: Color(0xFF991B1B),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      onPressed: () => hrProvider.loadDailyUpdates(),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ],

            // Filter Bar (Department + Search + Reset)
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Department Dropdown
                    Builder(builder: (context) {
                      final deptData = DepartmentHelper.buildFilterDropdown(
                        currentValue: hrProvider.dailyUpdatesDeptFilter,
                        departments: hrProvider.departments,
                      );
                      return SizedBox(
                        width: 200,
                        child: DropdownButtonFormField<String>(
                          key: ValueKey('daily_updates_dept_${deptData.value}'),
                          isExpanded: true,
                          initialValue: deptData.value,
                          decoration: const InputDecoration(
                            labelText: 'Department',
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(),
                          ),
                          items: deptData.items,
                          onChanged: (val) {
                            if (val != null) {
                              hrProvider.setDailyUpdatesDepartment(val);
                            }
                          },
                        ),
                      );
                    }),

                    // Search input
                    SizedBox(
                      width: 280,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by employee, department, text...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    hrProvider.setDailyUpdatesSearch('');
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (val) =>
                            hrProvider.setDailyUpdatesSearch(val),
                      ),
                    ),

                    // Reset Filters Button
                    if (hasActiveFilter)
                      TextButton.icon(
                        onPressed: () {
                          _searchController.clear();
                          hrProvider.setDailyUpdatesSearch('');
                          hrProvider.setDailyUpdatesDepartment('all');
                        },
                        icon: const Icon(Icons.filter_alt_off, size: 16),
                        label: const Text('Reset Filters'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Progress bar
            if (hrProvider.isDailyUpdatesLoading ||
                hrProvider.isDailyUpdatesDeleting) ...[
              const LinearProgressIndicator(
                color: Color(0xFF2563EB),
                backgroundColor: Color(0xFFEFF6FF),
              ),
              const SizedBox(height: 16),
            ],

            // Work Updates List
            ...updates
                .map((update) => _buildWorkUpdateCard(update, hrProvider)),

            // Empty State
            if (updates.isEmpty &&
                (!hrProvider.isDailyUpdatesLoading ||
                    hrProvider.dailyUpdatesError != null))
              Container(
                padding: const EdgeInsets.all(48),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.history_edu,
                        size: 54, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      hrProvider.dailyUpdatesError != null
                          ? 'No updates available due to server error'
                          : 'No staff daily work updates found.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            // Pagination Controls
            if (hrProvider.hasLoadedApiDailyUpdates &&
                hrProvider.dailyUpdatesTotalPages > 1) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Showing ${(hrProvider.dailyUpdatesPage - 1) * hrProvider.dailyUpdatesLimit + 1} to ${min(hrProvider.dailyUpdatesPage * hrProvider.dailyUpdatesLimit, hrProvider.dailyUpdatesTotal)} of ${hrProvider.dailyUpdatesTotal} updates',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: hrProvider.dailyUpdatesPage > 1 &&
                                !hrProvider.isDailyUpdatesLoading
                            ? () => hrProvider.setDailyUpdatesPage(
                                hrProvider.dailyUpdatesPage - 1)
                            : null,
                      ),
                      Text(
                        'Page ${hrProvider.dailyUpdatesPage} of ${hrProvider.dailyUpdatesTotalPages}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: hrProvider.dailyUpdatesPage <
                                    hrProvider.dailyUpdatesTotalPages &&
                                !hrProvider.isDailyUpdatesLoading
                            ? () => hrProvider.setDailyUpdatesPage(
                                hrProvider.dailyUpdatesPage + 1)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWorkUpdateCard(DailyUpdate task, HRProvider hrProvider) {
    final staff =
        hrProvider.staffList.where((s) => s.id == task.staffId).firstOrNull;

    final displayName = task.employeeName.isNotEmpty
        ? task.employeeName
        : (staff?.name ??
            (task.employeeId.isNotEmpty ? task.employeeId : task.staffId));

    final displayId = task.employeeId.isNotEmpty
        ? task.employeeId
        : (staff?.id.isNotEmpty == true ? staff!.id : '');

    final isSelected = _selectedUpdateIds.contains(task.id);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: _isSelectionMode && isSelected
              ? const Color(0xFF93C5FD)
              : Colors.grey.shade200,
          width: _isSelectionMode && isSelected ? 1.5 : 1.0,
        ),
      ),
      color: _isSelectionMode && isSelected
          ? const Color(0xFFF8FAFC)
          : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: _isSelectionMode
            ? () {
                setState(() {
                  if (isSelected) {
                    _selectedUpdateIds.remove(task.id);
                  } else {
                    _selectedUpdateIds.add(task.id);
                  }
                });
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (_isSelectionMode) ...[
                        Checkbox(
                          key: ValueKey('checkbox_update_${task.id}'),
                          value: isSelected,
                          activeColor: const Color(0xFF2563EB),
                          onChanged: (bool? checked) {
                            setState(() {
                              if (checked == true) {
                                _selectedUpdateIds.add(task.id);
                              } else {
                                _selectedUpdateIds.remove(task.id);
                              }
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                      ],
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFFEFF6FF),
                        child: Text(
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : 'S',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          if (displayId.isNotEmpty)
                            Text(
                              displayId,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      task.department.isNotEmpty
                          ? task.department
                          : (staff?.department ?? '—'),
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (task.title.isNotEmpty) ...[
                Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                task.updateText,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF334155),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 13, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Text(
                    'Submitted: ${task.date}',
                    style:
                        const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  if (task.createdAt != null) ...[
                    const SizedBox(width: 12),
                    const Icon(Icons.access_time,
                        size: 13, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(task.createdAt!),
                      style:
                          const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
