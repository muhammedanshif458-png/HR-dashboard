import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/hr_provider.dart';
import '../../widgets/modals.dart';

class StaffProfileView extends StatelessWidget {
  const StaffProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final hrProvider = context.watch<HRProvider>();
    final staffId = hrProvider.selectedStaffId;
    final staff = hrProvider.staffList.where((s) => s.id == staffId).firstOrNull;

    if (staff == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Staff member not found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => hrProvider.setScreen('hr-dashboard'),
                child: const Text('Back to Dashboard'),
              ),
            ],
          ),
        ),
      );
    }

    final staffAttendance = hrProvider.attendanceList.where((a) => a.staffId == staff.id).toList();
    final staffTasks = hrProvider.tasksList.where((t) => t.staffId == staff.id).toList();
    final staffUpdates = hrProvider.dailyUpdatesList.where((u) => u.staffId == staff.id).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => hrProvider.setScreen('hr-dashboard'),
        ),
        title: const Text('Staff Profile', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          TextButton.icon(
            onPressed: () => Modals.showEditStaffModal(context, staff),
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Edit Staff'),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () => Modals.showAssignTaskModal(context),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Assign Task'),
          ),
          if (staff.status == 'active') ...[
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Mark Resigned?'),
                    content: const Text('Are you sure you want to deactivate this employee?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Deactivate'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  final success = await hrProvider.deactivateStaff(staff.id);
                  if (!success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(hrProvider.apiStaffError)));
                  } else if (context.mounted) {
                    hrProvider.setScreen('hr-dashboard');
                  }
                }
              },
              icon: const Icon(Icons.person_off, size: 16, color: Colors.red),
              label: const Text('Mark Resigned', style: TextStyle(color: Colors.red)),
            ),
          ],
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Hero Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: staff.department == 'Tech' ? Colors.blue.shade100 : Colors.purple.shade100,
                      child: Text(
                        staff.name.isNotEmpty ? staff.name[0] : 'U',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: staff.department == 'Tech' ? Colors.blue.shade700 : Colors.purple.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(staff.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                                child: Text(staff.department, style: TextStyle(color: Colors.blue.shade700, fontSize: 12)),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: staff.status == 'resigned' ? Colors.red.shade50 : (staff.onLeaveToday ? Colors.grey.shade100 : Colors.green.shade50),
                                  borderRadius: BorderRadius.circular(12)
                                ),
                                child: Text(
                                  staff.status == 'resigned' ? 'Resigned' : (staff.onLeaveToday ? 'On Leave' : 'Active'),
                                  style: TextStyle(
                                    color: staff.status == 'resigned' ? Colors.red.shade700 : (staff.onLeaveToday ? Colors.grey.shade700 : Colors.green.shade700),
                                    fontSize: 12,
                                  )
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 16,
                            runSpacing: 8,
                            children: [
                              Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.email, size: 16, color: Colors.grey), const SizedBox(width: 4), Text(staff.email)]),
                              Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.phone, size: 16, color: Colors.grey), const SizedBox(width: 4), Text(staff.phoneNumber)]),
                              Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.work, size: 16, color: Colors.grey), const SizedBox(width: 4), Text(staff.role)]),
                              Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.calendar_today, size: 16, color: Colors.grey), const SizedBox(width: 4), Text('Joined ${staff.joinDate}')]),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // 3 Column Details Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 800;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    // Attendance Log
                    SizedBox(
                      width: isWide ? (constraints.maxWidth - 32) / 3 : constraints.maxWidth,
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 18),
                                  const SizedBox(width: 8),
                                  Text('Attendance Log (${staffAttendance.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ...staffAttendance.map((att) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(att.date, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text(att.isLate ? 'Late Check-in' : 'On Time', style: TextStyle(color: att.isLate ? Colors.orange : Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text('In: ${att.checkInTime} | Out: ${att.checkOutTime ?? "Present"}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                    Text('Worked: ${att.workedDuration} · Break: ${att.breakDuration}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                  ],
                                ),
                              )),
                              if (staffAttendance.isEmpty) const Text('No attendance record found.', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Tasks Log
                    SizedBox(
                      width: isWide ? (constraints.maxWidth - 32) / 3 : constraints.maxWidth,
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.check_box, size: 18),
                                  const SizedBox(width: 8),
                                  Text('Tasks (${staffTasks.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ...staffTasks.map((task) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(task.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Due: ${task.dueDate}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                        Text(task.status, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      ],
                                    ),
                                  ],
                                ),
                              )),
                              if (staffTasks.isEmpty) const Text('No assigned tasks.', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Daily Updates Log
                    SizedBox(
                      width: isWide ? (constraints.maxWidth - 32) / 3 : constraints.maxWidth,
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.description, size: 18),
                                  const SizedBox(width: 8),
                                  Text('Daily Updates (${staffUpdates.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ...staffUpdates.map((update) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(update.date, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 11)),
                                    const SizedBox(height: 4),
                                    Text(update.updateText, style: const TextStyle(fontSize: 13)),
                                  ],
                                ),
                              )),
                              if (staffUpdates.isEmpty) const Text('No daily updates submitted.', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
