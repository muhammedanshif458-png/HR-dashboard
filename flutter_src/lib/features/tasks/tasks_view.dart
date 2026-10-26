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
                IconButton(
                  tooltip: 'Refresh Updates',
                  onPressed: hrProvider.isDailyUpdatesLoading
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
              ],
            ),
            const SizedBox(height: 20),

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
            if (hrProvider.isDailyUpdatesLoading) ...[
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

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
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
    );
  }
}
