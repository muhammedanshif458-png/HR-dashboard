import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/hr_provider.dart';
import '../models/staff.dart';

class Modals {
  static void showAddStaffModal(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String email = '';
    String phone = '';
    String department = 'Tech';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.person_add, size: 18),
              SizedBox(width: 8),
              Text('Add New Staff Member', style: TextStyle(fontSize: 18)),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Full Name'),
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    onSaved: (val) => name = val ?? '',
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Email Address'),
                    validator: (val) => val == null || !val.contains('@') ? 'Invalid email' : null,
                    onSaved: (val) => email = val ?? '',
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Phone Number'),
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    onSaved: (val) => phone = val ?? '',
                  ),
                  DropdownButtonFormField<String>(
                    value: department,
                    items: ['Tech', 'Telecalling'].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                    onChanged: (val) {
                      if (val != null) department = val;
                    },
                    decoration: const InputDecoration(labelText: 'Department'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  final provider = Provider.of<HRProvider>(context, listen: false);
                  final success = await provider.addStaff({
                    'name': name,
                    'email': email,
                    'phoneNumber': phone,
                    'department': department,
                  });
                  if (success) {
                    Navigator.pop(dialogContext);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.apiStaffError)));
                  }
                }
              },
              child: const Text('Add Staff Member'),
            ),
          ],
        );
      },
    );
  }

  static void showEditStaffModal(BuildContext context, Staff staff) {
    final formKey = GlobalKey<FormState>();
    String name = staff.name;
    String email = staff.email;
    String phone = staff.phoneNumber;
    String department = staff.department == 'Tech' || staff.department == 'Telecalling' ? staff.department : 'Tech';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.edit, size: 18),
              SizedBox(width: 8),
              Text('Edit Staff Details', style: TextStyle(fontSize: 18)),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: name,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    onSaved: (val) => name = val ?? '',
                  ),
                  TextFormField(
                    initialValue: email,
                    decoration: const InputDecoration(labelText: 'Email Address'),
                    validator: (val) => val == null || !val.contains('@') ? 'Invalid email' : null,
                    onSaved: (val) => email = val ?? '',
                  ),
                  TextFormField(
                    initialValue: phone,
                    decoration: const InputDecoration(labelText: 'Phone Number'),
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    onSaved: (val) => phone = val ?? '',
                  ),
                  DropdownButtonFormField<String>(
                    value: department,
                    items: ['Tech', 'Telecalling'].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                    onChanged: (val) {
                      if (val != null) department = val;
                    },
                    decoration: const InputDecoration(labelText: 'Department'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  final provider = Provider.of<HRProvider>(context, listen: false);
                  final success = await provider.updateStaff(staff.id, {
                    'name': name,
                    'email': email,
                    'phoneNumber': phone,
                    'department': department,
                  });
                  if (success) {
                    Navigator.pop(dialogContext);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.apiStaffError)));
                  }
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }

  static void showAssignTaskModal(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String desc = '';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_box, size: 18),
              SizedBox(width: 8),
              Text('Assign New Task', style: TextStyle(fontSize: 18)),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Task Description'),
                    maxLines: 3,
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    onSaved: (val) => desc = val ?? '',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  // Wire to provider API
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Assign Task'),
            ),
          ],
        );
      },
    );
  }
}
