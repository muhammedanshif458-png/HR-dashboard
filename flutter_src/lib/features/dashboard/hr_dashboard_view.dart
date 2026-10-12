import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/hr_provider.dart';
import '../../widgets/header.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/modals.dart';

class HRDashboardView extends StatelessWidget {
  const HRDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final hrProvider = context.watch<HRProvider>();
    final metrics = hrProvider.dashboardMetrics;
    final pendingLeaves = hrProvider.leaveRequests.where((r) => r.status == 'Pending').toList();
    final pendingResignations = hrProvider.resignationRequests.where((r) => r.status == 'Pending').toList();
    final filteredStaffList = hrProvider.filteredStaffList;

    return Scaffold(
      appBar: const Header(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dashboard Intro
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Workforce overview', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    SizedBox(height: 8),
                    Text('Team dashboard', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('Monitor attendance, tasks, and team updates from one place.', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  ],
                ),
                Text('Today\'s operations', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue)),
              ],
            ),
            const SizedBox(height: 24),

            // Metrics Grid
            LayoutBuilder(
              builder: (context, constraints) {
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: constraints.maxWidth > 800 ? (constraints.maxWidth - 64) / 5 : (constraints.maxWidth - 16) / 2,
                      child: MetricCard(
                        label: 'Present today',
                        value: metrics.presentToday,
                        icon: Icons.people,
                        tone: 'green',
                        isActive: hrProvider.dashboardFilter == 'present',
                        onClick: () => hrProvider.setDashboardFilter('present'),
                      ),
                    ),
                    SizedBox(
                      width: constraints.maxWidth > 800 ? (constraints.maxWidth - 64) / 5 : (constraints.maxWidth - 16) / 2,
                      child: MetricCard(
                        label: 'Late check-ins',
                        value: metrics.lateCheckIns,
                        icon: Icons.access_time,
                        tone: 'amber',
                        isActive: hrProvider.dashboardFilter == 'late',
                        onClick: () => hrProvider.setDashboardFilter('late'),
                      ),
                    ),
                    SizedBox(
                      width: constraints.maxWidth > 800 ? (constraints.maxWidth - 64) / 5 : (constraints.maxWidth - 16) / 2,
                      child: MetricCard(
                        label: 'Open tasks',
                        value: metrics.openTasks,
                        icon: Icons.check_box,
                        tone: 'blue',
                        isActive: hrProvider.dashboardFilter == 'tasks',
                        onClick: () => hrProvider.setDashboardFilter('tasks'),
                      ),
                    ),
                    SizedBox(
                      width: constraints.maxWidth > 800 ? (constraints.maxWidth - 64) / 5 : (constraints.maxWidth - 16) / 2,
                      child: MetricCard(
                        label: 'On leave',
                        value: metrics.onLeaveToday,
                        icon: Icons.calendar_today,
                        tone: 'slate',
                        isActive: hrProvider.dashboardFilter == 'leave',
                        onClick: () => hrProvider.setDashboardFilter('leave'),
                      ),
                    ),
                    SizedBox(
                      width: constraints.maxWidth > 800 ? (constraints.maxWidth - 64) / 5 : (constraints.maxWidth - 16) / 2,
                      child: MetricCard(
                        label: 'Resigned (30d)',
                        value: metrics.resignedLast30Days,
                        icon: Icons.person_off,
                        tone: 'red',
                        isActive: hrProvider.dashboardFilter == 'resigned',
                        onClick: () => hrProvider.setDashboardFilter('resigned'),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),

            // Pending Reviews Banner
            if (pendingLeaves.isNotEmpty || pendingResignations.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 32),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.fact_check, size: 18, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Requests Pending HR Review', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...pendingLeaves.map((leave) {
                      final staff = hrProvider.staffList.firstWhere((s) => s.id == leave.staffId, orElse: () => hrProvider.staffList.first);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text.rich(TextSpan(children: [
                                TextSpan(text: staff.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                TextSpan(text: ' requested leave (${leave.fromDate} to ${leave.toDate}) - '),
                                TextSpan(text: '"${leave.reason}"', style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                              ])),
                            ),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => hrProvider.reviewLeave(leave.id, true),
                                  icon: const Icon(Icons.check, size: 14),
                                  label: const Text('Approve'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () => hrProvider.reviewLeave(leave.id, false),
                                  icon: const Icon(Icons.close, size: 14),
                                  label: const Text('Reject'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

            // Directory Search & Action Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('People directory', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    SizedBox(height: 4),
                    Text('Staff members', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 250,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search staff by name, email...',
                          prefixIcon: Icon(Icons.search, size: 16),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                        onChanged: (val) => hrProvider.setSearchQuery(val),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        Modals.showAssignTaskModal(context);
                      },
                      icon: const Icon(Icons.check_box, size: 16),
                      label: const Text('Assign Task'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, foregroundColor: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        Modals.showAddStaffModal(context);
                      },
                      icon: const Icon(Icons.person_add, size: 16),
                      label: const Text('Add Staff Member'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Staff Table Card
            Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Department', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Check-in time', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Check-out', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Worked', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Break', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Today\'s task', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: filteredStaffList.map((staff) {
                    final att = hrProvider.attendanceList.where((a) => a.staffId == staff.id).firstOrNull;
                    final statusLabel = staff.status == 'resigned' ? 'Resigned' : (staff.onLeaveToday ? 'On leave' : (att != null ? 'Present' : 'Not checked in'));
                    final statusColor = statusLabel == 'Present' ? Colors.green : Colors.grey;

                    return DataRow(cells: [
                      DataCell(InkWell(
                        onTap: () => hrProvider.viewStaffProfile(staff.id),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(staff.name, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.blue)),
                            Text(staff.email, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      )),
                      DataCell(Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                        child: Text(staff.department, style: TextStyle(color: Colors.blue.shade700, fontSize: 12)),
                      )),
                      DataCell(Text(att?.checkInTime ?? '—')),
                      DataCell(Text(att?.checkOutTime ?? '—')),
                      DataCell(Text(att?.workedDuration ?? '—')),
                      DataCell(Text(att?.breakDuration ?? '—')),
                      DataCell(Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
                      )),
                      const DataCell(Text('—')),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
