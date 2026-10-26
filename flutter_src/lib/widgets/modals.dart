import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/hr_provider.dart';
import '../models/staff.dart';
import '../core/department_helper.dart';

class Modals {
  static void showAddStaffModal(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String email = '';
    String phone = '';
    String department = 'Tech';
    String designation = 'Software Engineer';
    String workMode = 'Office';
    double salary = 0.0;
    String currency = 'INR';
    String effectiveDate = DateTime.now().toString().substring(0, 10);
    int paidLeaveAllowance = 1;
    String dateOfBirth = '';
    String password = '';
    bool obscurePassword = true;
    bool obscureConfirmPassword = true;

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isSubmitting = false;
        String? modalError;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.person_add, size: 20, color: Color(0xFF2563EB)),
                  SizedBox(width: 8),
                  Text('Add New Staff Member',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 480,
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (modalError != null && modalError!.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: const Color(0xFFFECACA)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.error_outline,
                                    size: 18, color: Color(0xFFDC2626)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    modalError!,
                                    style: const TextStyle(
                                      color: Color(0xFFB91C1C),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        TextFormField(
                          decoration: const InputDecoration(
                              labelText: 'Full Name *',
                              hintText: 'e.g. John Doe'),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Full name is required';
                            }
                            if (val.trim().length < 2) {
                              return 'Enter a valid name (at least 2 characters)';
                            }
                            return null;
                          },
                          onSaved: (val) => name = val?.trim() ?? '',
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          decoration: const InputDecoration(
                              labelText: 'Email Address *',
                              hintText: 'john@lysoftware.com'),
                          keyboardType: TextInputType.emailAddress,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Email is required';
                            }
                            final trimmed = val.trim();
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(trimmed)) {
                              return 'Enter a valid email address';
                            }
                            final hrProvider =
                                Provider.of<HRProvider>(context, listen: false);
                            final exists = hrProvider.staffList.any((s) =>
                                    s.email.toLowerCase() ==
                                    trimmed.toLowerCase()) ||
                                hrProvider.employeeDirectory.any((s) =>
                                    s.email.toLowerCase() ==
                                    trimmed.toLowerCase());
                            if (exists) {
                              return 'An employee with this email already exists';
                            }
                            return null;
                          },
                          onSaved: (val) => email = val?.trim() ?? '',
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          key: const Key('add_staff_password_field'),
                          obscureText: obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Set Password',
                            hintText: 'Leave blank for default (Password@123)',
                            helperText: 'Optional • Min 6 characters if set',
                            prefixIcon: const Icon(Icons.lock_outline, size: 18),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                size: 18,
                              ),
                              onPressed: () => setState(
                                  () => obscurePassword = !obscurePassword),
                            ),
                          ),
                          validator: (val) {
                            if (val != null && val.isNotEmpty && val.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                          onChanged: (val) => password = val,
                          onSaved: (val) => password = val?.trim() ?? '',
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          key: const Key('add_staff_confirm_password_field'),
                          obscureText: obscureConfirmPassword,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            hintText: 'Re-enter password if set above',
                            prefixIcon: const Icon(Icons.lock_outline, size: 18),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscureConfirmPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                size: 18,
                              ),
                              onPressed: () => setState(() =>
                                  obscureConfirmPassword =
                                      !obscureConfirmPassword),
                            ),
                          ),
                          validator: (val) {
                            if (password.isNotEmpty && val != password) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          decoration: const InputDecoration(
                              labelText: 'Phone Number *',
                              hintText: '9876543210'),
                          keyboardType: TextInputType.phone,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Phone number required';
                            }
                            final digits =
                                val.replaceAll(RegExp(r'\D'), '').trim();
                            if (digits.length < 7 || digits.length > 15) {
                              return 'Enter a valid phone number (7-15 digits)';
                            }
                            final hrProvider =
                                Provider.of<HRProvider>(context, listen: false);
                            final exists = hrProvider.staffList.any((s) =>
                                    s.phoneNumber.isNotEmpty &&
                                    s.phoneNumber
                                            .replaceAll(RegExp(r'\D'), '') ==
                                        digits) ||
                                hrProvider.employeeDirectory.any((s) =>
                                    s.phoneNumber.isNotEmpty &&
                                    s.phoneNumber
                                            .replaceAll(RegExp(r'\D'), '') ==
                                        digits);
                            if (exists) {
                              return 'An employee with this phone number already exists';
                            }
                            return null;
                          },
                          onSaved: (val) => phone = val?.trim() ?? '',
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          initialValue: designation,
                          decoration: const InputDecoration(
                              labelText: 'Designation *',
                              hintText: 'e.g. Senior Frontend Engineer'),
                          validator: (val) => val == null || val.trim().isEmpty
                              ? 'Designation required'
                              : null,
                          onSaved: (val) => designation = val?.trim() ?? '',
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Builder(builder: (context) {
                                final hrProvider = Provider.of<HRProvider>(
                                    context,
                                    listen: false);
                                final deptData = DepartmentHelper
                                    .buildFormDepartmentDropdown(
                                  currentValue: department,
                                  departments: hrProvider.departments,
                                  staffList: hrProvider.staffList,
                                  defaultFallback: 'Tech',
                                );
                                return DropdownButtonFormField<String>(
                                  key: ValueKey(
                                      'add_staff_dept_${deptData.value}'),
                                  isExpanded: true,
                                  value: deptData.value,
                                  items: deptData.items,
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => department = val);
                                    }
                                  },
                                  decoration: const InputDecoration(
                                      labelText: 'Department'),
                                );
                              }),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                isExpanded: true,
                                value: ['Office', 'WFH'].contains(workMode)
                                    ? workMode
                                    : 'Office',
                                items: const [
                                  DropdownMenuItem(
                                      value: 'Office', child: Text('Office')),
                                  DropdownMenuItem(
                                      value: 'WFH', child: Text('WFH')),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => workMode = val);
                                  }
                                },
                                decoration: const InputDecoration(
                                    labelText: 'Work Mode'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.currency_rupee,
                                size: 16, color: Color(0xFF2563EB)),
                            const SizedBox(width: 4),
                            Text(
                              'SALARY & LEAVE POLICY (Required)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Monthly Salary *',
                                  prefixIcon:
                                      Icon(Icons.currency_rupee, size: 16),
                                  hintText: 'e.g. 50000',
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Monthly salary is required';
                                  }
                                  final numVal = double.tryParse(val.trim());
                                  if (numVal == null || numVal < 0) {
                                    return 'Enter a valid non-negative salary';
                                  }
                                  return null;
                                },
                                onSaved: (val) => salary =
                                    double.tryParse(val?.trim() ?? '0') ?? 0.0,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                isExpanded: true,
                                value: ['INR', 'USD', 'EUR', 'GBP']
                                        .contains(currency)
                                    ? currency
                                    : 'INR',
                                items: ['INR', 'USD', 'EUR', 'GBP']
                                    .map((c) => DropdownMenuItem(
                                        value: c, child: Text(c)))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null)
                                    setState(() => currency = val);
                                },
                                decoration: const InputDecoration(
                                    labelText: 'Currency'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: effectiveDate,
                                decoration: const InputDecoration(
                                  labelText: 'Salary Effective Date *',
                                  suffixIcon:
                                      Icon(Icons.calendar_month, size: 18),
                                  hintText: 'YYYY-MM-DD',
                                ),
                                validator: (val) =>
                                    val == null || val.trim().isEmpty
                                        ? 'Effective date required'
                                        : null,
                                onSaved: (val) =>
                                    effectiveDate = val?.trim() ?? '',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                initialValue: '1',
                                decoration: const InputDecoration(
                                  labelText: 'Paid Leave / Month',
                                  suffixText: 'Day',
                                  helperText: 'Company policy: 1 day/mo',
                                ),
                                keyboardType: TextInputType.number,
                                validator: (val) {
                                  final n = int.tryParse(val?.trim() ?? '');
                                  if (n == null || n < 0) return 'Invalid days';
                                  return null;
                                },
                                onSaved: (val) => paidLeaveAllowance =
                                    int.tryParse(val?.trim() ?? '1') ?? 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.cake_outlined,
                                size: 16, color: Color(0xFFDB2777)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'DATE OF BIRTH (For Birthday Celebrations)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.pink.shade900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          initialValue: dateOfBirth,
                          decoration: const InputDecoration(
                            labelText: 'Date of Birth',
                            hintText: 'YYYY-MM-DD (e.g. 1995-06-15)',
                            suffixIcon: Icon(Icons.cake_outlined,
                                size: 18, color: Color(0xFFDB2777)),
                            helperText:
                                'Optional - only month & day shown to staff',
                            border: OutlineInputBorder(),
                          ),
                          onSaved: (val) => dateOfBirth = val?.trim() ?? '',
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return null;
                            final parts = val.trim().split('-');
                            if (parts.length != 3)
                              return 'Use YYYY-MM-DD format';
                            final m = int.tryParse(parts[1]);
                            final d = int.tryParse(parts[2]);
                            if (m == null ||
                                d == null ||
                                m < 1 ||
                                m > 12 ||
                                d < 1 ||
                                d > 31) return 'Invalid date';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isSubmitting ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            formKey.currentState!.save();
                            setState(() {
                              isSubmitting = true;
                              modalError = null;
                            });
                            final provider =
                                Provider.of<HRProvider>(context, listen: false);
                            final success = await provider.addStaff({
                              'name': name,
                              'email': email,
                              'phoneNumber': phone,
                              'department': department,
                              'designation': designation,
                              'workMode': workMode,
                              'salary': salary,
                              'salaryCurrency': currency,
                              'salaryEffectiveDate': effectiveDate,
                              'paidLeaveAllowance': paidLeaveAllowance,
                              if (password.isNotEmpty)
                                'password': password,
                              if (dateOfBirth.isNotEmpty)
                                'dateOfBirth': dateOfBirth,
                            });
                            if (!dialogContext.mounted) return;
                            if (success) {
                              Navigator.pop(dialogContext);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Employee "$name" added with salary $currency ${salary.toStringAsFixed(0)}!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } else {
                              setState(() {
                                isSubmitting = false;
                                modalError = provider.apiStaffError.isNotEmpty
                                    ? provider.apiStaffError
                                    : 'Failed to add staff';
                              });
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(modalError!),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Add Staff Member'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  static void showEditStaffModal(BuildContext context, Staff staff) {
    showDialog(
      context: context,
      builder: (dialogContext) => _EditStaffDialog(staff: staff),
    );
  }

  static void showEditSalaryModal(BuildContext context, Staff staff) {
    final formKey = GlobalKey<FormState>();
    double newSalary = staff.salary;
    String currency =
        staff.salaryCurrency.isNotEmpty ? staff.salaryCurrency : 'INR';
    String effectiveDate = DateTime.now().toString().substring(0, 10);
    String reason = 'Appraisal / Market adjustment';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.price_change_outlined,
                      size: 22, color: Color(0xFF10B981)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Edit Salary: ${staff.name}',
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 440,
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  size: 18, color: Color(0xFF16A34A)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Current Salary: ${staff.salaryCurrency} ${staff.salary.toStringAsFixed(0)} (Effective: ${staff.salaryEffectiveDate.isNotEmpty ? staff.salaryEffectiveDate : 'N/A'})',
                                  style: const TextStyle(
                                      fontSize: 13, color: Color(0xFF15803D)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                initialValue: staff.salary > 0
                                    ? staff.salary.toStringAsFixed(0)
                                    : '',
                                decoration: const InputDecoration(
                                  labelText: 'New Monthly Salary *',
                                  prefixIcon:
                                      Icon(Icons.currency_rupee, size: 16),
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty)
                                    return 'Salary required';
                                  final n = double.tryParse(val.trim());
                                  if (n == null || n < 0)
                                    return 'Invalid salary';
                                  return null;
                                },
                                onSaved: (val) => newSalary =
                                    double.tryParse(val?.trim() ?? '0') ?? 0.0,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                value: ['INR', 'USD', 'EUR', 'GBP']
                                        .contains(currency)
                                    ? currency
                                    : 'INR',
                                items: ['INR', 'USD', 'EUR', 'GBP']
                                    .map((c) => DropdownMenuItem(
                                        value: c, child: Text(c)))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null)
                                    setState(() => currency = val);
                                },
                                decoration: const InputDecoration(
                                    labelText: 'Currency'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          initialValue: effectiveDate,
                          decoration: const InputDecoration(
                            labelText: 'Effective Date *',
                            suffixIcon: Icon(Icons.calendar_month, size: 18),
                            hintText: 'YYYY-MM-DD',
                          ),
                          validator: (val) => val == null || val.trim().isEmpty
                              ? 'Effective date required'
                              : null,
                          onSaved: (val) => effectiveDate = val?.trim() ?? '',
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          initialValue: reason,
                          decoration: const InputDecoration(
                            labelText: 'Reason for Adjustment',
                            hintText:
                                'e.g. Annual Appraisal, Promotion, Incentive',
                          ),
                          validator: (val) => val == null || val.trim().isEmpty
                              ? 'Reason required for audit trail'
                              : null,
                          onSaved: (val) => reason = val?.trim() ?? '',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();
                      final provider =
                          Provider.of<HRProvider>(context, listen: false);
                      final success = await provider.editSalary(
                        staffId: staff.id,
                        newSalary: newSalary,
                        effectiveDate: effectiveDate,
                        currency: currency,
                        reason: reason,
                      );
                      if (!dialogContext.mounted) return;
                      if (success) {
                        Navigator.pop(dialogContext);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Salary updated to $currency ${newSalary.toStringAsFixed(0)}.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('Update Salary'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static void showSalaryHistoryModal(BuildContext context, Staff staff) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.history, size: 22, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Salary History: ${staff.name}',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: staff.salaryHistory.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(
                      child: Text(
                        'No salary adjustment records available for this employee.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    ),
                  )
                : ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 380),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: staff.salaryHistory.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = staff.salaryHistory[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.currency_rupee,
                                size: 18, color: Color(0xFF2563EB)),
                          ),
                          title: Text(
                            '${item.currency} ${item.amount.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (item.reason.isNotEmpty)
                                Text('Reason: ${item.reason}',
                                    style: const TextStyle(fontSize: 12)),
                              Text(
                                'Effective: ${item.effectiveDate} • By: ${item.changedBy}',
                                style: const TextStyle(
                                    fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                          trailing: item.timestamp.isNotEmpty
                              ? Text(
                                  item.timestamp.split(' ').first,
                                  style: const TextStyle(
                                      fontSize: 11, color: Color(0xFF94A3B8)),
                                )
                              : null,
                        );
                      },
                    ),
                  ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  static void showAssignTaskModal(BuildContext context,
      {String? defaultStaffId}) {
    final formKey = GlobalKey<FormState>();
    final provider = Provider.of<HRProvider>(context, listen: false);
    String targetStaffId = defaultStaffId ??
        (provider.staffList.isNotEmpty ? provider.staffList.first.id : '');
    String desc = '';
    String department = 'Tech';
    final dueDateController = TextEditingController(
      text: DateTime.now()
          .add(const Duration(days: 3))
          .toIso8601String()
          .split('T')[0],
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_box_outlined,
                  size: 20, color: Color(0xFF2563EB)),
              SizedBox(width: 8),
              Text('Assign New Task',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 440,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Builder(builder: (context) {
                      final uniqueStaff = <String, Staff>{};
                      for (final s in provider.staffList) {
                        if (s.id.isNotEmpty && !uniqueStaff.containsKey(s.id)) {
                          uniqueStaff[s.id] = s;
                        }
                      }
                      String? safeStaffId;
                      if (targetStaffId.isNotEmpty &&
                          uniqueStaff.containsKey(targetStaffId)) {
                        safeStaffId = targetStaffId;
                      } else if (uniqueStaff.isNotEmpty) {
                        safeStaffId = uniqueStaff.keys.first;
                      } else {
                        safeStaffId = null;
                      }

                      final staffItems = uniqueStaff.values.map((s) {
                        return DropdownMenuItem<String>(
                          value: s.id,
                          child: Text('${s.name} (${s.department})'),
                        );
                      }).toList();

                      return DropdownButtonFormField<String>(
                        key: ValueKey('assign_task_staff_$safeStaffId'),
                        value: safeStaffId,
                        items: staffItems,
                        onChanged: staffItems.isEmpty
                            ? null
                            : (val) {
                                if (val != null) {
                                  targetStaffId = val;
                                  final match = uniqueStaff[val];
                                  if (match != null) {
                                    department = match.department;
                                  }
                                }
                              },
                        decoration: InputDecoration(
                          labelText: 'Assign To Employee *',
                          helperText: staffItems.isEmpty
                              ? 'No staff members available'
                              : null,
                        ),
                        validator: (val) => val == null || val.isEmpty
                            ? 'Please select an employee'
                            : null,
                      );
                    }),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Task Description *',
                        hintText:
                            'Describe the deliverables and key objectives...',
                      ),
                      maxLines: 3,
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Task description is required'
                          : null,
                      onSaved: (val) => desc = val?.trim() ?? '',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: dueDateController,
                      decoration: const InputDecoration(
                        labelText: 'Due Date (YYYY-MM-DD) *',
                        prefixIcon: Icon(Icons.calendar_today, size: 16),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Due date required'
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  provider.assignTask(
                      targetStaffId, department, desc, dueDateController.text);
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Task assigned successfully!'),
                        backgroundColor: Colors.green),
                  );
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

class _EditStaffDialog extends StatefulWidget {
  final Staff staff;
  const _EditStaffDialog({required this.staff});

  @override
  State<_EditStaffDialog> createState() => _EditStaffDialogState();
}

class _EditStaffDialogState extends State<_EditStaffDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _passwordController;
  late String _name;
  late String _email;
  late String _phone;
  late String _department;
  late String _designation;
  late String _workMode;
  late double _salary;
  late String _currency;
  late String _effectiveDate;
  late String _changeReason;
  late String _dateOfBirth;
  bool _obscureNewPassword = true;
  bool _isSubmitting = false;
  String? _modalError;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
    _name = widget.staff.name;
    _email = widget.staff.email;
    _phone = widget.staff.phoneNumber;
    _department =
        DepartmentHelper.toSupportedCanonicalName(widget.staff.department);
    _designation = widget.staff.designation.isNotEmpty
        ? widget.staff.designation
        : widget.staff.role;
    _workMode = widget.staff.workMode;
    _salary = widget.staff.salary;
    _currency = widget.staff.salaryCurrency.isNotEmpty
        ? widget.staff.salaryCurrency
        : 'INR';
    _effectiveDate = widget.staff.salaryEffectiveDate.isNotEmpty
        ? widget.staff.salaryEffectiveDate
        : DateTime.now().toString().substring(0, 10);
    _changeReason = 'Details revision';
    _dateOfBirth = widget.staff.dateOfBirth;
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.edit, size: 20, color: Color(0xFF2563EB)),
          SizedBox(width: 8),
          Text('Edit Staff Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 480,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_modalError != null && _modalError!.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 18, color: Color(0xFFDC2626)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _modalError!,
                            style: const TextStyle(
                              color: Color(0xFFB91C1C),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                TextFormField(
                  initialValue: _name,
                  decoration: const InputDecoration(labelText: 'Full Name *'),
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Required' : null,
                  onSaved: (val) => _name = val?.trim() ?? '',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _email,
                  decoration:
                      const InputDecoration(labelText: 'Email Address *'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Email is required';
                    }
                    final trimmed = val.trim();
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(trimmed)) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                  onSaved: (val) => _email = val?.trim() ?? '',
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lock_outline,
                            size: 16, color: Color(0xFF2563EB)),
                        SizedBox(width: 6),
                        Text(
                          'Staff Login Password',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A8A),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: const Text(
                        'Replace Password',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  key: const Key('edit_staff_password_field'),
                  controller: _passwordController,
                  obscureText: _obscureNewPassword,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: const Icon(Icons.lock_outline, size: 18),
                    helperText:
                        'Enter a new password to replace the current password. Leave blank to keep the existing password.',
                    helperMaxLines: 2,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNewPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        size: 18,
                      ),
                      onPressed: () => setState(() =>
                          _obscureNewPassword = !_obscureNewPassword),
                    ),
                  ),
                  validator: (val) {
                    final trimmed = val?.trim() ?? '';
                    if (trimmed.isNotEmpty && trimmed.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _phone,
                  decoration:
                      const InputDecoration(labelText: 'Phone Number *'),
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Required' : null,
                  onSaved: (val) => _phone = val?.trim() ?? '',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _designation,
                  decoration: const InputDecoration(labelText: 'Designation'),
                  onSaved: (val) => _designation = val?.trim() ?? '',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Builder(builder: (context) {
                        final hrProvider =
                            Provider.of<HRProvider>(context, listen: false);
                        final deptData =
                            DepartmentHelper.buildFormDepartmentDropdown(
                          currentValue: _department,
                          departments: hrProvider.departments,
                          staffList: hrProvider.staffList,
                          defaultFallback: 'Tech',
                        );
                        return DropdownButtonFormField<String>(
                          key: ValueKey('edit_staff_dept_${deptData.value}'),
                          isExpanded: true,
                          value: deptData.value,
                          items: deptData.items,
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _department = val);
                            }
                          },
                          decoration:
                              const InputDecoration(labelText: 'Department'),
                        );
                      }),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: ['Office', 'WFH'].contains(_workMode)
                            ? _workMode
                            : 'Office',
                        items: const [
                          DropdownMenuItem(
                              value: 'Office', child: Text('Office')),
                          DropdownMenuItem(value: 'WFH', child: Text('WFH')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _workMode = val);
                          }
                        },
                        decoration:
                            const InputDecoration(labelText: 'Work Mode'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.cake_outlined,
                        size: 16, color: Color(0xFFDB2777)),
                    const SizedBox(width: 4),
                    Text(
                      'DATE OF BIRTH',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.pink.shade900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _dateOfBirth,
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth',
                    hintText: 'YYYY-MM-DD',
                    suffixIcon: Icon(Icons.cake_outlined,
                        size: 18, color: Color(0xFFDB2777)),
                    helperText: 'Optional - only month & day shown to staff',
                    border: OutlineInputBorder(),
                  ),
                  onSaved: (val) => _dateOfBirth = val?.trim() ?? '',
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return null;
                    }
                    final parts = val.trim().split('-');
                    if (parts.length != 3) {
                      return 'Use YYYY-MM-DD format';
                    }
                    final m = int.tryParse(parts[1]);
                    final d = int.tryParse(parts[2]);
                    if (m == null ||
                        d == null ||
                        m < 1 ||
                        m > 12 ||
                        d < 1 ||
                        d > 31) {
                      return 'Invalid date';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.currency_rupee,
                        size: 16, color: Color(0xFF2563EB)),
                    const SizedBox(width: 4),
                    Text(
                      'SALARY INFORMATION',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        initialValue: _salary > 0
                            ? _salary.toStringAsFixed(0)
                            : '',
                        decoration: const InputDecoration(
                          labelText: 'Monthly Salary',
                          prefixIcon: Icon(Icons.currency_rupee, size: 16),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return null;
                          final numVal = double.tryParse(val.trim());
                          if (numVal == null || numVal < 0) {
                            return 'Invalid salary';
                          }
                          return null;
                        },
                        onSaved: (val) {
                          if (val != null && val.trim().isNotEmpty) {
                            _salary =
                                double.tryParse(val.trim()) ?? _salary;
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: ['INR', 'USD', 'EUR', 'GBP'].contains(_currency)
                            ? _currency
                            : 'INR',
                        items: ['INR', 'USD', 'EUR', 'GBP']
                            .map((c) =>
                                DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _currency = val);
                          }
                        },
                        decoration:
                            const InputDecoration(labelText: 'Currency'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _changeReason,
                  decoration: const InputDecoration(
                    labelText: 'Reason for changes',
                    hintText: 'e.g. Annual Appraisal, Title Promotion',
                  ),
                  onSaved: (val) =>
                      _changeReason = val?.trim() ?? 'Details revision',
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _isSubmitting
              ? null
              : () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    final newPassword = _passwordController.text.trim();
                    setState(() {
                      _isSubmitting = true;
                      _modalError = null;
                    });
                    final provider =
                        Provider.of<HRProvider>(context, listen: false);
                    final updatePayload = <String, dynamic>{
                      'name': _name,
                      'email': _email,
                      'phoneNumber': _phone,
                      'department': _department,
                      'designation': _designation,
                      'workMode': _workMode,
                      'salary': _salary,
                      'salaryCurrency': _currency,
                      'salaryEffectiveDate': _effectiveDate,
                      'salaryChangeReason': _changeReason,
                      'dateOfBirth': _dateOfBirth,
                      if (newPassword.isNotEmpty) 'password': newPassword,
                    };
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);
                    final success =
                        await provider.updateStaff(widget.staff.id, updatePayload);
                    if (!mounted) return;
                    if (success) {
                      navigator.pop();
                      messenger.showSnackBar(
                        const SnackBar(
                          content:
                              Text('Staff details updated successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      setState(() {
                        _isSubmitting = false;
                        _modalError = provider.apiStaffError.isNotEmpty
                            ? provider.apiStaffError
                            : 'Failed to update details';
                      });
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(provider.apiStaffError.isNotEmpty
                              ? provider.apiStaffError
                              : 'Failed to update details'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Save Changes'),
        ),
      ],
    );
  }
}
