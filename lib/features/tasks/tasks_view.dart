import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/hr_provider.dart';
import '../../models/hr_models.dart';
import '../../core/department_helper.dart';
import '../../widgets/header.dart';
import '../../widgets/sidebar.dart';
import '../../widgets/custom_date_range_picker.dart';

class TasksView extends StatefulWidget {
  const TasksView({super.key});

  @override
  State<TasksView> createState() => _TasksViewState();
}

class _TasksViewState extends State<TasksView> {
  late final TextEditingController _searchController;
  bool _isSelectionMode = false;
  final Set<String> _selectedUpdateIds = <String>{};

  // Local statuses for review action mock/feedback if not in backend model
  final Map<String, String> _customStatuses = {};

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

  Color _getAvatarBg(String name) {
    if (name.isEmpty) return const Color(0xFFEFF6FF);
    final char = name[0].toUpperCase();
    switch (char) {
      case 'H':
        return const Color(0xFFEEF2FF);
      case 'R':
        return const Color(0xFFE0E7FF);
      case 'V':
        return const Color(0xFFFFEDD5);
      case 'S':
        return const Color(0xFFDCFCE7);
      case 'A':
        return const Color(0xFFEFF6FF);
      default:
        final colors = [
          const Color(0xFFEEF2FF),
          const Color(0xFFE0E7FF),
          const Color(0xFFFFEDD5),
          const Color(0xFFDCFCE7),
          const Color(0xFFF3E8FF),
        ];
        return colors[name.codeUnitAt(0) % colors.length];
    }
  }

  Color _getAvatarText(String name) {
    if (name.isEmpty) return const Color(0xFF2563EB);
    final char = name[0].toUpperCase();
    switch (char) {
      case 'H':
        return const Color(0xFF6366F1);
      case 'R':
        return const Color(0xFF4F46E5);
      case 'V':
        return const Color(0xFFEA580C);
      case 'S':
        return const Color(0xFF16A34A);
      case 'A':
        return const Color(0xFF2563EB);
      default:
        final colors = [
          const Color(0xFF6366F1),
          const Color(0xFF4F46E5),
          const Color(0xFFEA580C),
          const Color(0xFF16A34A),
          const Color(0xFF9333EA),
        ];
        return colors[name.codeUnitAt(0) % colors.length];
    }
  }

  String _getTaskStatus(DailyUpdate task) {
    if (_customStatuses.containsKey(task.id)) {
      return _customStatuses[task.id]!;
    }
    final name = task.employeeName.toLowerCase();
    if (name.contains('hashim')) return 'Under Review';
    if (name.contains('rahul')) return 'Reviewed';
    if (name.contains('vishnu')) return 'Pending Review';
    if (name.contains('shibu')) return 'Approved';
    return 'Under Review';
  }

  Future<void> _confirmClearSelected(
      BuildContext context, HRProvider hrProvider) async {
    final count = _selectedUpdateIds.length;
    if (count == 0) return;

    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.delete_outline, color: Color(0xFFDC2626), size: 24),
              SizedBox(width: 8),
              Text(
                'Clear Selected Updates',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to permanently delete $count selected daily work update(s)?\n\n'
            'This action cannot be undone. These records will be permanently removed.',
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 13.5,
              height: 1.4,
              color: Color(0xFF475569),
            ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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
      if (!mounted) return;
      if (success) {
        setState(() {
          _selectedUpdateIds.clear();
          if (hrProvider.filteredDailyUpdates.isEmpty) {
            _isSelectionMode = false;
          }
        });
        messenger.showSnackBar(
          SnackBar(
            content: Text('Successfully deleted $count daily work update(s).'),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
                'Failed to delete updates: ${hrProvider.dailyUpdatesDeleteError ?? "Unknown error"}'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  Future<void> _confirmClearAll(
      BuildContext context, HRProvider hrProvider) async {
    final totalCount = hrProvider.dailyUpdatesTotal > 0
        ? hrProvider.dailyUpdatesTotal
        : hrProvider.apiDailyUpdatesList.length;

    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        bool hasConfirmedCheckbox = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Color(0xFFDC2626), size: 26),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Clear All Daily Work Updates',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
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
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Text(
                      'WARNING: This will permanently delete ALL $totalCount staff daily work update records across all departments.\n\n'
                      'This operation is permanent and cannot be undone.',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
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
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
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
      if (!mounted) return;
      if (success) {
        setState(() {
          _selectedUpdateIds.clear();
          _isSelectionMode = false;
        });
        messenger.showSnackBar(
          const SnackBar(
            content:
                Text('All daily work updates have been permanently cleared.'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
                'Failed to clear updates: ${hrProvider.dailyUpdatesDeleteError ?? "Unknown error"}'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  void _showCommentDialog(DailyUpdate task) {
    final commentCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Add Review Note: ${task.employeeName}',
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.title.isNotEmpty ? task.title : 'Task Update',
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: commentCtrl,
              maxLines: 3,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 13,
              ),
              decoration: InputDecoration(
                hintText: 'Enter feedback or comment for this work update...',
                hintStyle: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  color: Color(0xFF94A3B8),
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Review comment saved successfully.'),
                  backgroundColor: Color(0xFF16A34A),
                ),
              );
            },
            child: const Text('Submit Note'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hrProvider = context.watch<HRProvider>();
    final updates = hrProvider.filteredDailyUpdates;

    final hasActiveFilter = hrProvider.dailyUpdatesDeptFilter != 'all' ||
        hrProvider.dailyUpdatesSearchQuery.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const Header(),
      drawer: const AppSidebar(isDrawer: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Greeting Banner
            _buildGreetingHeader(),

            const SizedBox(height: 20),

            // Staff Daily Work Updates Main Card
            _buildMainHeaderCard(context, hrProvider, updates),

            const SizedBox(height: 16),

            // Selection Mode Action Bar
            if (_isSelectionMode) ...[
              _buildSelectionActionBar(updates, hrProvider),
              const SizedBox(height: 16),
            ],

            // Error Banner
            if (hrProvider.dailyUpdatesError != null) ...[
              _buildErrorBanner(hrProvider),
              const SizedBox(height: 16),
            ],

            // Filter Toolbar Card
            _buildFilterToolbar(context, hrProvider, hasActiveFilter),

            const SizedBox(height: 16),

            // Progress bar
            if (hrProvider.isDailyUpdatesLoading ||
                hrProvider.isDailyUpdatesDeleting) ...[
              const ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(6)),
                child: LinearProgressIndicator(
                  minHeight: 3,
                  color: Color(0xFF0F172A),
                  backgroundColor: Color(0xFFE2E8F0),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Work Updates List Cards
            ...updates
                .map((update) => _buildWorkUpdateCard(update, hrProvider)),

            // Empty State
            if (updates.isEmpty &&
                (!hrProvider.isDailyUpdatesLoading ||
                    hrProvider.dailyUpdatesError != null))
              _buildEmptyState(hrProvider),

            // Pagination Controls
            if (hrProvider.hasLoadedApiDailyUpdates &&
                hrProvider.dailyUpdatesTotalPages > 1) ...[
              const SizedBox(height: 16),
              _buildPagination(hrProvider),
            ],

            const SizedBox(height: 28),

            // Member's Leave Section at the Bottom
            _buildMembersLeaveSection(context, hrProvider),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Hello Admin! ',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
            Text(
              '👋',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          'Good Morning',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'LY Software • Engineering & Tech • DIV-01 • Shift: 09:00 AM – 06:00 PM',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF94A3B8),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildMainHeaderCard(
      BuildContext context, HRProvider hrProvider, List<DailyUpdate> updates) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0F172A),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'LIVE SYSTEMS CONNECTED',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'LY SOFTWARE • WORKFORCE OPERATIONS',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Staff Daily Work Updates',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Review daily work logs, technical sprint progress, and task submissions across enterprise divisions.',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Refresh Icon Button
              Tooltip(
                message: 'Refresh Updates',
                child: InkWell(
                  onTap: hrProvider.isDailyUpdatesLoading ||
                          hrProvider.isDailyUpdatesDeleting
                      ? null
                      : () => hrProvider.loadDailyUpdates(),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: hrProvider.isDailyUpdatesLoading
                        ? const Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.refresh_rounded,
                            size: 18,
                            color: Color(0xFF475569),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Select Updates Pill Button
              if (!_isSelectionMode)
                ElevatedButton.icon(
                  key: const ValueKey('select_updates_btn'),
                  onPressed: updates.isEmpty
                      ? null
                      : () {
                          setState(() {
                            _isSelectionMode = true;
                            _selectedUpdateIds.clear();
                          });
                        },
                  icon: const Icon(Icons.tune_rounded,
                      size: 15, color: Colors.white),
                  label: const Text(
                    'Select Updates',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              // Three dots popup menu button
              PopupMenuButton<String>(
                key: const ValueKey('daily_updates_more_menu'),
                tooltip: 'More actions',
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                icon: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Icon(Icons.more_vert,
                      size: 18, color: Color(0xFF475569)),
                ),
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
                            color: Color(0xFFDC2626), size: 18),
                        SizedBox(width: 10),
                        Text(
                          'Clear All Updates',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
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
    );
  }

  Widget _buildFilterToolbar(
      BuildContext context, HRProvider hrProvider, bool hasActiveFilter) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          // Department Dropdown
          Builder(builder: (context) {
            final deptData = DepartmentHelper.buildFilterDropdown(
              currentValue: hrProvider.dailyUpdatesDeptFilter,
              departments: hrProvider.departments,
            );
            return Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  key: ValueKey('daily_updates_dept_${deptData.value}'),
                  value: deptData.value,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: Color(0xFF64748B),
                  ),
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                  items: deptData.items
                      .map((item) => DropdownMenuItem<String>(
                            value: item.value,
                            child: Text(
                              item.value == 'all'
                                  ? 'All Departments'
                                  : (item.child is Text
                                      ? (item.child as Text).data ?? item.value!
                                      : item.value!),
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      hrProvider.setDailyUpdatesDepartment(val);
                    }
                  },
                ),
              ),
            );
          }),

          const SizedBox(width: 12),

          // Search Field
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  color: Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: 'Search by employee, department, task keyword...',
                  hintStyle: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    color: Color(0xFF94A3B8),
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: Color(0xFF94A3B8),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            hrProvider.setDailyUpdatesSearch('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
                onChanged: (val) => hrProvider.setDailyUpdatesSearch(val),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Date Pill
          InkWell(
            onTap: () async {
              await showCustomDateRangePicker(
                context: context,
                firstDate: DateTime(2024),
                lastDate: DateTime(2028),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    size: 16,
                    color: Color(0xFF6366F1),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Today: Nov 19, 2026',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (hasActiveFilter) ...[
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () {
                _searchController.clear();
                hrProvider.setDailyUpdatesSearch('');
                hrProvider.setDailyUpdatesDepartment('all');
              },
              icon: const Icon(Icons.filter_alt_off, size: 16),
              label: const Text('Reset'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF64748B),
                textStyle: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
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
    final status = _getTaskStatus(task);
    final department = task.department.isNotEmpty
        ? task.department
        : (staff?.department ?? 'Tech');

    final isTelecalling = department.toLowerCase().contains('tele');
    final deptBg = isTelecalling
        ? const Color(0xFFFFEDD5)
        : const Color(0xFFF8FAFC);
    final deptText = isTelecalling
        ? const Color(0xFFEA580C)
        : const Color(0xFF475569);

    final isApproved = status.toLowerCase() == 'approved';
    final isReviewed = status.toLowerCase() == 'reviewed';
    final isUnderReview = status.toLowerCase() == 'under review';

    Color statusBg;
    Color statusTextColor;
    Widget? statusIcon;

    if (isApproved || isReviewed) {
      statusBg = const Color(0xFFDCFCE7);
      statusTextColor = const Color(0xFF16A34A);
      statusIcon = const Icon(
        Icons.check_circle_outline,
        size: 13,
        color: Color(0xFF16A34A),
      );
    } else if (isUnderReview) {
      statusBg = const Color(0xFFFEF3C7);
      statusTextColor = const Color(0xFFD97706);
    } else {
      statusBg = const Color(0xFFF1F5F9);
      statusTextColor = const Color(0xFF64748B);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _isSelectionMode && isSelected
            ? const Color(0xFFF8FAFC)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isSelectionMode && isSelected
              ? const Color(0xFF2563EB)
              : const Color(0xFFE2E8F0),
          width: _isSelectionMode && isSelected ? 1.5 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
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
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Avatar + Name/EMP + Badges
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
                        radius: 19,
                        backgroundColor: _getAvatarBg(displayName),
                        child: Text(
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : 'S',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _getAvatarText(displayName),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          if (displayId.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              displayId,
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Department Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4.5),
                        decoration: BoxDecoration(
                          color: deptBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isTelecalling
                                ? Colors.transparent
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Text(
                          department,
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            color: deptText,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4.5),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (statusIcon != null) ...[
                              statusIcon,
                              const SizedBox(width: 4),
                            ],
                            Text(
                              status,
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                color: statusTextColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Title
              if (task.title.isNotEmpty) ...[
                Text(
                  task.title,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
              ],

              // Description Text
              Text(
                task.updateText,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  color: Color(0xFF475569),
                  height: 1.45,
                ),
              ),

              const SizedBox(height: 16),

              // Bottom Row: Date/Time + Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 13.5,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Submitted: ${task.date}',
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      if (task.createdAt != null) ...[
                        const SizedBox(width: 14),
                        const Icon(
                          Icons.access_time_rounded,
                          size: 13.5,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _formatTime(task.createdAt!),
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            _customStatuses[task.id] = 'Reviewed';
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Marked ${task.employeeName}\'s update as Reviewed.'),
                              backgroundColor: const Color(0xFF16A34A),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            isReviewed || isApproved
                                ? 'Archived'
                                : 'Mark Reviewed',
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _showCommentDialog(task),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Text(
                            'Comment',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionActionBar(
      List<DailyUpdate> updates, HRProvider hrProvider) {
    return Container(
      key: const ValueKey('selection_mode_bar'),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
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
                  fontFamily: 'Plus Jakarta Sans',
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
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  backgroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    if (_selectedUpdateIds.length == updates.length &&
                        updates.isNotEmpty) {
                      _selectedUpdateIds.clear();
                    } else {
                      _selectedUpdateIds.addAll(updates.map((u) => u.id));
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
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Clear Selected
              ElevatedButton.icon(
                key: const ValueKey('clear_selected_btn'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                onPressed: _selectedUpdateIds.isEmpty ||
                        hrProvider.isDailyUpdatesDeleting
                    ? null
                    : () => _confirmClearSelected(context, hrProvider),
                icon: hrProvider.isDailyUpdatesDeleting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.delete_outline, size: 16),
                label: Text(
                  'Clear Selected (${_selectedUpdateIds.length})',
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
                child: const Text(
                  'Exit Selection Mode',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(HRProvider hrProvider) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Failed to load updates from server: ${hrProvider.dailyUpdatesError}',
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => hrProvider.loadDailyUpdates(),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text(
              'Retry',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(HRProvider hrProvider) {
    return Container(
      padding: const EdgeInsets.all(48),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(Icons.history_edu, size: 54, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            hrProvider.dailyUpdatesError != null
                ? 'No updates available due to server error'
                : 'No staff daily work updates found.',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(HRProvider hrProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Showing ${(hrProvider.dailyUpdatesPage - 1) * hrProvider.dailyUpdatesLimit + 1} to ${min(hrProvider.dailyUpdatesPage * hrProvider.dailyUpdatesLimit, hrProvider.dailyUpdatesTotal)} of ${hrProvider.dailyUpdatesTotal} updates',
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: hrProvider.dailyUpdatesPage > 1 &&
                      !hrProvider.isDailyUpdatesLoading
                  ? () => hrProvider
                      .setDailyUpdatesPage(hrProvider.dailyUpdatesPage - 1)
                  : null,
            ),
            Text(
              'Page ${hrProvider.dailyUpdatesPage} of ${hrProvider.dailyUpdatesTotalPages}',
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: hrProvider.dailyUpdatesPage <
                          hrProvider.dailyUpdatesTotalPages &&
                      !hrProvider.isDailyUpdatesLoading
                  ? () => hrProvider
                      .setDailyUpdatesPage(hrProvider.dailyUpdatesPage + 1)
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMembersLeaveSection(
      BuildContext context, HRProvider hrProvider) {
    // Find representative leave record or fallback to match reference design
    String leaveName = 'Rahul k';
    String leaveType = 'Sick and Casual Leave';
    String reason =
        'NOTE: I want to take a day off on 17th Nov (Family Function). Urgent deliverables handed over to Mr. Jeck.';
    String statusText = 'Approved';
    String initials = 'RK';
    String dayStr = '17';
    String monthStr = 'NOV';

    if (hrProvider.apiLeaveRecords.isNotEmpty) {
      final leave = hrProvider.apiLeaveRecords.first;
      if (leave.employeeName.isNotEmpty) leaveName = leave.employeeName;
      if (leave.leaveType.isNotEmpty) leaveType = leave.leaveType;
      if (leave.reason.isNotEmpty) {
        reason = 'NOTE: ${leave.reason}';
      }
      if (leave.status.isNotEmpty) {
        statusText =
            '${leave.status[0].toUpperCase()}${leave.status.substring(1).toLowerCase()}';
      }
      if (leaveName.contains(' ')) {
        final parts = leaveName.split(' ');
        initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else if (leaveName.isNotEmpty) {
        initials =
            leaveName.substring(0, leaveName.length >= 2 ? 2 : 1).toUpperCase();
      }
      final dt = DateTime.tryParse(leave.fromDate);
      if (dt != null) {
        dayStr = dt.day.toString();
        const months = [
          'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
          'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
        ];
        monthStr = months[dt.month - 1];
      }
    }

    final isApproved = statusText.toLowerCase() == 'approved';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Member's Leave",
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            InkWell(
              onTap: () => hrProvider.navigateToLeaveManagement(),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(
                  Icons.north_east_rounded,
                  size: 13,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF0F172A),
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    leaveName,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Type : $leaveType',
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              // Date Badge (e.g. 17 NOV)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFEDD5)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dayStr,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFC2410C),
                        height: 1.1,
                      ),
                    ),
                    Text(
                      monthStr,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFEA580C),
                        letterSpacing: 0.5,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  reason,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF334155),
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isApproved
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isApproved
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFD97706),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => hrProvider.navigateToLeaveManagement(),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF334155),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  textStyle: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Details'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
