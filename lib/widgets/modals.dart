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

        Widget fieldLabel(String label, {bool isRequired = false}) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: RichText(
              text: TextSpan(
                text: label,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
                children: isRequired
                    ? const [
                        TextSpan(
                          text: ' *',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            color: Color(0xFFEF4444),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ]
                    : null,
              ),
            ),
          );
        }

        InputDecoration inputDecor({
          required String labelForFinder,
          required String hintText,
          IconData? prefixIcon,
          Widget? suffixIcon,
          String? helperText,
          bool isRequired = false,
        }) {
          return InputDecoration(
            filled: true,
            fillColor: const Color(0xFFFBFDFF),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            hintText: hintText,
            hintStyle: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 13,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w400,
            ),
            helperText: helperText,
            helperStyle: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 11,
              color: Color(0xFF94A3B8),
            ),
            errorStyle: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 11,
              color: Color(0xFFEF4444),
            ),
            prefix: Offstage(
              offstage: false,
              child: Text(
                labelForFinder,
                style: const TextStyle(
                  fontSize: 0,
                  height: 0,
                  color: Colors.transparent,
                ),
              ),
            ),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: 18, color: const Color(0xFF94A3B8))
                : null,
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFF0F172A), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFFEF4444), width: 1.5),
            ),
          );
        }

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              titlePadding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
              contentPadding: const EdgeInsets.fromLTRB(28, 0, 28, 0),
              actionsPadding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
              actionsAlignment: MainAxisAlignment.end,
              title: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add New Staff Member',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Create employee credentials and directory profile',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.pop(dialogContext),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 16, bottom: 16),
                    child: Divider(
                        color: Color(0xFFF1F5F9), height: 1, thickness: 1),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 640,
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (modalError != null && modalError!.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
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
                                      fontFamily: 'Plus Jakarta Sans',
                                      color: Color(0xFFB91C1C),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Full Name
                        fieldLabel('Full Name', isRequired: true),
                        TextFormField(
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF0F172A),
                          ),
                          decoration: inputDecor(
                            labelForFinder: 'Full Name *',
                            hintText: 'e.g. Eleanor Vance',
                            prefixIcon: Icons.person_outline_rounded,
                            isRequired: true,
                          ),
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
                        const SizedBox(height: 14),

                        // Date of Birth & Phone Number
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  fieldLabel('Date of Birth'),
                                  TextFormField(
                                    key: ValueKey('staff_dob_$dateOfBirth'),
                                    initialValue: dateOfBirth,
                                    readOnly: true,
                                    style: const TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF0F172A),
                                    ),
                                    decoration: inputDecor(
                                      labelForFinder: 'Date of Birth',
                                      hintText: 'mm/dd/yyyy',
                                      prefixIcon:
                                          Icons.calendar_today_outlined,
                                      helperText:
                                          'Optional - only month & day shown to staff',
                                    ),
                                    onTap: () async {
                                      final today = DateTime.now();
                                      final currentDob =
                                          DateTime.tryParse(dateOfBirth);
                                      final initialDate = currentDob != null &&
                                              !currentDob.isAfter(today)
                                          ? currentDob
                                          : DateTime(1995, 1, 1);
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: initialDate,
                                        firstDate: DateTime(1900),
                                        lastDate: today,
                                      );
                                      if (picked != null) {
                                        setState(() => dateOfBirth = picked
                                            .toIso8601String()
                                            .substring(0, 10));
                                      }
                                    },
                                    onSaved: (val) =>
                                        dateOfBirth = val?.trim() ?? '',
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty)
                                        return null;
                                      final parts = val.trim().split('-');
                                      if (parts.length != 3) {
                                        return 'Use YYYY-MM-DD format';
                                      }
                                      final parsed =
                                          DateTime.tryParse(val.trim());
                                      if (parsed == null ||
                                          parsed
                                                  .toIso8601String()
                                                  .substring(0, 10) !=
                                              val.trim()) {
                                        return 'Invalid date';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  fieldLabel('Phone Number', isRequired: true),
                                  TextFormField(
                                    keyboardType: TextInputType.phone,
                                    style: const TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF0F172A),
                                    ),
                                    decoration: inputDecor(
                                      labelForFinder: 'Phone Number *',
                                      hintText: '+1(555) 000-0000',
                                      prefixIcon: Icons.phone_outlined,
                                      isRequired: true,
                                    ),
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Phone number required';
                                      }
                                      final digits = val
                                          .replaceAll(RegExp(r'\D'), '')
                                          .trim();
                                      if (digits.length < 7 ||
                                          digits.length > 15) {
                                        return 'Enter a valid phone number (7-15 digits)';
                                      }
                                      final hrProvider =
                                          Provider.of<HRProvider>(context,
                                              listen: false);
                                      final exists = hrProvider.staffList.any(
                                              (s) =>
                                                  s.phoneNumber.isNotEmpty &&
                                                  s.phoneNumber.replaceAll(
                                                          RegExp(r'\D'), '') ==
                                                      digits) ||
                                          hrProvider.employeeDirectory.any(
                                              (s) =>
                                                  s.phoneNumber.isNotEmpty &&
                                                  s.phoneNumber.replaceAll(
                                                          RegExp(r'\D'), '') ==
                                                      digits);
                                      if (exists) {
                                        return 'An employee with this phone number already exists';
                                      }
                                      return null;
                                    },
                                    onSaved: (val) =>
                                        phone = val?.trim() ?? '',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Email Address
                        fieldLabel('Email Address', isRequired: true),
                        TextFormField(
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF0F172A),
                          ),
                          decoration: inputDecor(
                            labelForFinder: 'Email Address *',
                            hintText: 'staff.member@example.com',
                            prefixIcon: Icons.mail_outline_rounded,
                            isRequired: true,
                          ),
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
                        const SizedBox(height: 14),

                        // Set Password & Confirm Password
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  fieldLabel('Set Password'),
                                  TextFormField(
                                    key: const Key('add_staff_password_field'),
                                    obscureText: obscurePassword,
                                    style: const TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF0F172A),
                                    ),
                                    decoration: inputDecor(
                                      labelForFinder: 'Set Password',
                                      hintText: '••••••••',
                                      helperText:
                                          'Optional · Min 6 characters if set',
                                      prefixIcon: Icons.lock_outline_rounded,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          obscurePassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          size: 18,
                                          color: const Color(0xFF94A3B8),
                                        ),
                                        onPressed: () => setState(() =>
                                            obscurePassword = !obscurePassword),
                                      ),
                                    ),
                                    validator: (val) {
                                      if (val != null &&
                                          val.isNotEmpty &&
                                          val.length < 6) {
                                        return 'Password must be at least 6 characters';
                                      }
                                      return null;
                                    },
                                    onChanged: (val) => password = val,
                                    onSaved: (val) =>
                                        password = val?.trim() ?? '',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  fieldLabel('Confirm Password'),
                                  TextFormField(
                                    key: const Key(
                                        'add_staff_confirm_password_field'),
                                    obscureText: obscureConfirmPassword,
                                    style: const TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF0F172A),
                                    ),
                                    decoration: inputDecor(
                                      labelForFinder: 'Confirm Password',
                                      hintText: '••••••••',
                                      prefixIcon: Icons.lock_outline_rounded,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          obscureConfirmPassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          size: 18,
                                          color: const Color(0xFF94A3B8),
                                        ),
                                        onPressed: () => setState(() =>
                                            obscureConfirmPassword =
                                                !obscureConfirmPassword),
                                      ),
                                    ),
                                    validator: (val) {
                                      if (password.isNotEmpty &&
                                          val != password) {
                                        return 'Passwords do not match';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _staffFormSection(
                            'Employment Details', Icons.badge_outlined),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  fieldLabel('Designation', isRequired: true),
                                  TextFormField(
                                    initialValue: designation,
                                    style: const TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF0F172A),
                                    ),
                                    decoration: inputDecor(
                                      labelForFinder: 'Designation *',
                                      hintText:
                                          'e.g. Senior Frontend Engineer',
                                      prefixIcon: Icons.badge_outlined,
                                      isRequired: true,
                                    ),
                                    validator: (val) =>
                                        val == null || val.trim().isEmpty
                                            ? 'Designation required'
                                            : null,
                                    onSaved: (val) =>
                                        designation = val?.trim() ?? '',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  fieldLabel('Department'),
                                  Builder(builder: (context) {
                                    final hrProvider = Provider.of<HRProvider>(
                                        context,
                                        listen: false);
                                    final deptData = DepartmentHelper
                                        .buildFormDepartmentDropdown(
                                      currentValue: department,
                                      departments: hrProvider.departments,
                                      staffList: hrProvider
                                              .employeeDirectory.isNotEmpty
                                          ? hrProvider.employeeDirectory
                                          : hrProvider.staffList,
                                      defaultFallback: 'Tech',
                                    );
                                    return DropdownButtonFormField<String>(
                                      key: ValueKey(
                                          'add_staff_dept_${deptData.value}'),
                                      isExpanded: true,
                                      value: deptData.value,
                                      items: deptData.items,
                                      style: const TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF0F172A),
                                      ),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() => department = val);
                                        }
                                      },
                                      decoration: inputDecor(
                                        labelForFinder: 'Department',
                                        hintText: 'Select Department',
                                        prefixIcon:
                                            Icons.corporate_fare_outlined,
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  fieldLabel('Work Mode'),
                                  DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    value: ['Office', 'WFH'].contains(workMode)
                                        ? workMode
                                        : 'Office',
                                    style: const TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF0F172A),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                          value: 'Office',
                                          child: Text('Office',
                                              style: TextStyle(
                                                  fontFamily:
                                                      'Plus Jakarta Sans'))),
                                      DropdownMenuItem(
                                          value: 'WFH',
                                          child: Text('WFH',
                                              style: TextStyle(
                                                  fontFamily:
                                                      'Plus Jakarta Sans'))),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => workMode = val);
                                      }
                                    },
                                    decoration: inputDecor(
                                      labelForFinder: 'Work Mode',
                                      hintText: 'Select Work Mode',
                                      prefixIcon: Icons.apartment_outlined,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  fieldLabel('Paid Leave / Month'),
                                  TextFormField(
                                    initialValue: '1',
                                    style: const TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF0F172A),
                                    ),
                                    decoration: inputDecor(
                                      labelForFinder: 'Paid Leave / Month',
                                      hintText: '1',
                                      helperText: 'Company policy: 1 day/mo',
                                      suffixIcon: const Padding(
                                        padding:
                                            EdgeInsets.only(right: 14, top: 12),
                                        child: Text('Day',
                                            style: TextStyle(
                                                fontFamily: 'Plus Jakarta Sans',
                                                color: Color(0xFF64748B),
                                                fontSize: 13)),
                                      ),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (val) {
                                      final n = int.tryParse(val?.trim() ?? '');
                                      if (n == null || n < 0)
                                        return 'Invalid days';
                                      return null;
                                    },
                                    onSaved: (val) => paidLeaveAllowance =
                                        int.tryParse(val?.trim() ?? '1') ?? 1,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _staffFormSection(
                            'Salary Details', Icons.currency_rupee),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  fieldLabel('Monthly Salary',
                                      isRequired: true),
                                  TextFormField(
                                    style: const TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF0F172A),
                                    ),
                                    decoration: inputDecor(
                                      labelForFinder: 'Monthly Salary *',
                                      hintText: 'e.g. 50000',
                                      prefixIcon: Icons.currency_rupee,
                                      isRequired: true,
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Monthly salary is required';
                                      }
                                      final numVal =
                                          double.tryParse(val.trim());
                                      if (numVal == null || numVal < 0) {
                                        return 'Enter a valid non-negative salary';
                                      }
                                      return null;
                                    },
                                    onSaved: (val) => salary =
                                        double.tryParse(val?.trim() ?? '0') ??
                                            0.0,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  fieldLabel('Currency'),
                                  DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    value: ['INR', 'USD', 'EUR', 'GBP']
                                            .contains(currency)
                                        ? currency
                                        : 'INR',
                                    style: const TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF0F172A),
                                    ),
                                    items: ['INR', 'USD', 'EUR', 'GBP']
                                        .map((c) => DropdownMenuItem(
                                            value: c,
                                            child: Text(c,
                                                style: const TextStyle(
                                                    fontFamily:
                                                        'Plus Jakarta Sans'))))
                                        .toList(),
                                    onChanged: (val) {
                                      if (val != null)
                                        setState(() => currency = val);
                                    },
                                    decoration: inputDecor(
                                      labelForFinder: 'Currency',
                                      hintText: 'Currency',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            fieldLabel('Salary Effective Date',
                                isRequired: true),
                            TextFormField(
                              key: ValueKey(
                                  'salary_effective_date_$effectiveDate'),
                              initialValue: effectiveDate,
                              readOnly: true,
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF0F172A),
                              ),
                              decoration: inputDecor(
                                labelForFinder: 'Salary Effective Date *',
                                hintText: 'YYYY-MM-DD',
                                prefixIcon: Icons.calendar_month_outlined,
                                isRequired: true,
                              ),
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate:
                                      DateTime.tryParse(effectiveDate) ??
                                          DateTime.now(),
                                  firstDate: DateTime(1950),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setState(() => effectiveDate = picked
                                      .toIso8601String()
                                      .substring(0, 10));
                                }
                              },
                              validator: (val) =>
                                  val == null || val.trim().isEmpty
                                      ? 'Effective date required'
                                      : null,
                              onSaved: (val) =>
                                  effectiveDate = val?.trim() ?? '',
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.only(top: 24, bottom: 8),
                          child: Divider(
                              color: Color(0xFFF1F5F9),
                              height: 1,
                              thickness: 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                OutlinedButton(
                  onPressed:
                      isSubmitting ? null : () => Navigator.pop(dialogContext),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    backgroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
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
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, size: 16, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              'Add Staff Member',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static Widget _staffFormSection(String title, IconData icon) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(children: [
          Icon(icon, size: 18, color: const Color(0xFF2563EB)),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  color: Color(0xFF0F172A),
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          const SizedBox(width: 12),
          const Expanded(
              child: Divider(
                  height: 1, color: Color(0xFFF1F5F9), thickness: 1)),
        ]),
      );

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
                    backgroundColor: const Color(0xFF0F172A),
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
    final staffSource = provider.employeeDirectory;
    String targetStaffId = defaultStaffId ??
        (staffSource.isNotEmpty ? staffSource.first.id : '');
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
                      for (final s in staffSource) {
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

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }

  InputDecoration _underlineInputDecor({
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? helperText,
  }) {
    return InputDecoration(
      isDense: true,
      hintText: hintText,
      hintStyle: const TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        fontSize: 15,
        color: Color(0xFF94A3B8),
        fontWeight: FontWeight.w400,
      ),
      helperText: helperText,
      helperMaxLines: 2,
      helperStyle: const TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        fontSize: 11.5,
        color: Color(0xFF94A3B8),
        height: 1.35,
      ),
      prefixIcon: prefixIcon,
      prefixIconConstraints:
          const BoxConstraints(minWidth: 28, minHeight: 28),
      suffixIcon: suffixIcon,
      suffixIconConstraints:
          const BoxConstraints(minWidth: 28, minHeight: 28),
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      border: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFCBD5E1), width: 1.0),
      ),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFCBD5E1), width: 1.0),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
      errorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFEF4444), width: 1.0),
      ),
      focusedErrorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
      errorStyle: const TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        fontSize: 11,
        color: Color(0xFFEF4444),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.9;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: BoxConstraints(maxWidth: 480, maxHeight: maxHeight),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A0F172A),
              blurRadius: 32,
              offset: Offset(0, 16),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(28, 26, 28, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Header (Pencil Icon + Title + Close Button)
            Row(
              children: [
                const Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: Color(0xFF0F172A),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Edit Staff Details',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: Color(0xFF94A3B8),
                  ),
                  tooltip: 'Close',
                  splashRadius: 18,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 2. Scrollable Form Content
            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Error Banner
                      if (_modalError != null && _modalError!.isNotEmpty) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 18),
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
                                    fontFamily: 'Plus Jakarta Sans',
                                    color: Color(0xFFB91C1C),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Full Name
                      _buildFieldLabel('Full Name *'),
                      TextFormField(
                        initialValue: _name,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF0F172A),
                        ),
                        decoration: _underlineInputDecor(),
                        validator: (val) =>
                            val == null || val.trim().isEmpty ? 'Required' : null,
                        onSaved: (val) => _name = val?.trim() ?? '',
                      ),
                      const SizedBox(height: 20),

                      // Email Address
                      _buildFieldLabel('Email Address *'),
                      TextFormField(
                        initialValue: _email,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF0F172A),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        decoration: _underlineInputDecor(),
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
                      const SizedBox(height: 24),

                      // Staff Login Password Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lock_outline,
                                    size: 16, color: Color(0xFF0F172A)),
                                SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Staff Login Password',
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: const Text(
                              'Replace Password',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: const Key('edit_staff_password_field'),
                        controller: _passwordController,
                        obscureText: _obscureNewPassword,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF0F172A),
                        ),
                        decoration: _underlineInputDecor(
                          hintText: 'New Password',
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Icon(Icons.lock_outline,
                                size: 18, color: Color(0xFF64748B)),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureNewPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 18,
                              color: const Color(0xFF64748B),
                            ),
                            onPressed: () => setState(() =>
                                _obscureNewPassword = !_obscureNewPassword),
                            splashRadius: 18,
                            padding: EdgeInsets.zero,
                            constraints:
                                const BoxConstraints(minWidth: 28, minHeight: 28),
                          ),
                          helperText:
                              'Enter a new password to replace the current password. Leave blank to keep the existing password.',
                        ),
                        validator: (val) {
                          final trimmed = val?.trim() ?? '';
                          if (trimmed.isNotEmpty && trimmed.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 22),

                      // Phone Number
                      _buildFieldLabel('Phone Number *'),
                      TextFormField(
                        initialValue: _phone,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF0F172A),
                        ),
                        decoration: _underlineInputDecor(),
                        validator: (val) =>
                            val == null || val.trim().isEmpty ? 'Required' : null,
                        onSaved: (val) => _phone = val?.trim() ?? '',
                      ),
                      const SizedBox(height: 20),

                      // Designation
                      _buildFieldLabel('Designation'),
                      TextFormField(
                        initialValue: _designation,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF0F172A),
                        ),
                        decoration: _underlineInputDecor(),
                        onSaved: (val) => _designation = val?.trim() ?? '',
                      ),
                      const SizedBox(height: 20),

                      // Department & Work Mode
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Department'),
                                Builder(builder: (context) {
                                  final hrProvider = Provider.of<HRProvider>(
                                      context,
                                      listen: false);
                                  final deptData = DepartmentHelper
                                      .buildFormDepartmentDropdown(
                                    currentValue: _department,
                                    departments: hrProvider.departments,
                                    staffList: hrProvider
                                            .employeeDirectory.isNotEmpty
                                        ? hrProvider.employeeDirectory
                                        : hrProvider.staffList,
                                    defaultFallback: 'Tech',
                                  );
                                  return DropdownButtonFormField<String>(
                                    key: ValueKey(
                                        'edit_staff_dept_${deptData.value}'),
                                    isExpanded: true,
                                    value: deptData.value,
                                    items: deptData.items,
                                    style: const TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF0F172A),
                                    ),
                                    icon: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.keyboard_arrow_down,
                                            size: 15, color: Color(0xFF64748B)),
                                        SizedBox(width: 1),
                                        Icon(Icons.keyboard_arrow_down,
                                            size: 15, color: Color(0xFF64748B)),
                                      ],
                                    ),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _department = val);
                                      }
                                    },
                                    decoration: _underlineInputDecor(),
                                  );
                                }),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Work Mode'),
                                DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  value: ['Office', 'WFH'].contains(_workMode)
                                      ? _workMode
                                      : 'Office',
                                  style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF0F172A),
                                  ),
                                  icon: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.keyboard_arrow_down,
                                          size: 15, color: Color(0xFF64748B)),
                                      SizedBox(width: 1),
                                      Icon(Icons.keyboard_arrow_down,
                                          size: 15, color: Color(0xFF64748B)),
                                    ],
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'Office',
                                        child: Text('Office',
                                            style: TextStyle(
                                                fontFamily: 'Plus Jakarta Sans',
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF0F172A)))),
                                    DropdownMenuItem(
                                        value: 'WFH',
                                        child: Text('WFH',
                                            style: TextStyle(
                                                fontFamily: 'Plus Jakarta Sans',
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF0F172A)))),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _workMode = val);
                                    }
                                  },
                                  decoration: _underlineInputDecor(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Preserved: Date of Birth
                      _buildFieldLabel('Date of Birth'),
                      TextFormField(
                        initialValue: _dateOfBirth,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF0F172A),
                        ),
                        decoration: _underlineInputDecor(
                          hintText: 'YYYY-MM-DD',
                          suffixIcon: const Icon(Icons.cake_outlined,
                              size: 18, color: Color(0xFF64748B)),
                          helperText:
                              'Optional - only month & day shown to staff',
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
                      const SizedBox(height: 20),

                      // Preserved: Salary Information
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Monthly Salary'),
                                TextFormField(
                                  initialValue: _salary > 0
                                      ? _salary.toStringAsFixed(0)
                                      : '',
                                  style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF0F172A),
                                  ),
                                  decoration: _underlineInputDecor(
                                    prefixIcon: const Padding(
                                      padding: EdgeInsets.only(right: 6),
                                      child: Icon(Icons.currency_rupee,
                                          size: 16, color: Color(0xFF64748B)),
                                    ),
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return null;
                                    }
                                    final numVal = double.tryParse(val.trim());
                                    if (numVal == null || numVal < 0) {
                                      return 'Invalid salary';
                                    }
                                    return null;
                                  },
                                  onSaved: (val) {
                                    if (val != null && val.trim().isNotEmpty) {
                                      _salary = double.tryParse(val.trim()) ??
                                          _salary;
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Currency'),
                                DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  value: ['INR', 'USD', 'EUR', 'GBP']
                                          .contains(_currency)
                                      ? _currency
                                      : 'INR',
                                  style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF0F172A),
                                  ),
                                  icon: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.keyboard_arrow_down,
                                          size: 15, color: Color(0xFF64748B)),
                                      SizedBox(width: 1),
                                      Icon(Icons.keyboard_arrow_down,
                                          size: 15, color: Color(0xFF64748B)),
                                    ],
                                  ),
                                  items: ['INR', 'USD', 'EUR', 'GBP']
                                      .map((c) => DropdownMenuItem(
                                          value: c,
                                          child: Text(c,
                                              style: const TextStyle(
                                                  fontFamily:
                                                      'Plus Jakarta Sans',
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFF0F172A)))))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _currency = val);
                                    }
                                  },
                                  decoration: _underlineInputDecor(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Preserved: Reason for changes
                      _buildFieldLabel('Reason for changes'),
                      TextFormField(
                        initialValue: _changeReason,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF0F172A),
                        ),
                        decoration: _underlineInputDecor(
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

            const SizedBox(height: 24),

            // 3. Action Buttons (Cancel and Save Changes)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed:
                      _isSubmitting ? null : () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    foregroundColor: const Color(0xFF0F172A),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isSubmitting
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            _formKey.currentState!.save();
                            final newPassword =
                                _passwordController.text.trim();
                            setState(() {
                              _isSubmitting = true;
                              _modalError = null;
                            });
                            final provider = Provider.of<HRProvider>(
                                context,
                                listen: false);
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
                              if (newPassword.isNotEmpty)
                                'password': newPassword,
                            };
                            final messenger = ScaffoldMessenger.of(context);
                            final navigator = Navigator.of(context);
                            final success = await provider.updateStaff(
                                widget.staff.id, updatePayload);
                            if (!mounted) return;
                            if (success) {
                              navigator.pop();
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Staff details updated successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              setState(() {
                                _isSubmitting = false;
                                _modalError =
                                    provider.apiStaffError.isNotEmpty
                                        ? provider.apiStaffError
                                        : 'Failed to update details';
                              });
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                      provider.apiStaffError.isNotEmpty
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
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
