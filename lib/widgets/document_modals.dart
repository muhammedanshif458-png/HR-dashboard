import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../providers/hr_provider.dart';
import '../models/hr_document.dart';
import '../models/staff.dart';

class PickedDocFile {
  final String name;
  final int size;
  final Uint8List bytes;

  PickedDocFile({
    required this.name,
    required this.size,
    required this.bytes,
  });
}

class DocumentModals {
  static const List<String> categories = [
    'Resume',
    'Identity Proof',
    'Educational Certificates',
    'Offer Letter',
    'Appointment Letter',
    'Employment Agreement',
    'Experience Certificate',
    'Medical Certificate',
    'Other'
  ];

  static void showAddDocumentModal(BuildContext context, Staff staff) {
    final formKey = GlobalKey<FormState>();
    String title = '';
    String category = 'Resume';
    String description = '';
    String issueDate = '';
    String expiryDate = '';
    PickedDocFile? selectedFile;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final hrProvider = Provider.of<HRProvider>(context, listen: false);

            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.upload_file,
                        color: Color(0xFF2563EB), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Upload HR Document',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Employee: ${staff.name} (${staff.department})',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 520,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Dropdown
                        DropdownButtonFormField<String>(
                          value: categories.contains(category)
                              ? category
                              : categories.first,
                          decoration: const InputDecoration(
                            labelText: 'Document Category *',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                          items: categories
                              .map((c) =>
                                  DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => category = val);
                          },
                          onSaved: (val) => category = val ?? 'Other',
                        ),
                        const SizedBox(height: 14),

                        // Title Field
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Document Title *',
                            hintText: 'e.g. Master Employment Agreement 2024',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Document title is required';
                            }
                            return null;
                          },
                          onSaved: (val) => title = val?.trim() ?? '',
                        ),
                        const SizedBox(height: 14),

                        // Description Field
                        TextFormField(
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Optional Description',
                            hintText:
                                'Add notes, issuing authority, or background notes...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                          onSaved: (val) => description = val?.trim() ?? '',
                        ),
                        const SizedBox(height: 14),

                        // Issue & Expiry Dates Row
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Issue Date',
                                  hintText: 'YYYY-MM-DD',
                                  prefixIcon:
                                      Icon(Icons.calendar_today, size: 16),
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 12),
                                ),
                                onSaved: (val) => issueDate = val?.trim() ?? '',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Expiry Date',
                                  hintText: 'YYYY-MM-DD',
                                  prefixIcon: Icon(Icons.event_busy, size: 16),
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 12),
                                ),
                                onSaved: (val) =>
                                    expiryDate = val?.trim() ?? '',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // File Picker Section
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: selectedFile != null
                                  ? const Color(0xFF10B981)
                                  : Colors.grey.shade300,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            color: selectedFile != null
                                ? const Color(0xFFECFDF5)
                                : Colors.grey.shade50,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                selectedFile != null
                                    ? Icons.check_circle_rounded
                                    : Icons.cloud_upload_outlined,
                                size: 36,
                                color: selectedFile != null
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF64748B),
                              ),
                              const SizedBox(height: 8),
                              if (selectedFile != null) ...[
                                Text(
                                  selectedFile!.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Size: ${(selectedFile!.size / 1024).toStringAsFixed(1)} KB',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    final files = await FilePicker.pickFiles(
                                      type: FileType.custom,
                                      allowedExtensions: [
                                        'pdf',
                                        'jpg',
                                        'jpeg',
                                        'png'
                                      ],
                                    );
                                    if (files.isNotEmpty) {
                                      final f = files.first;
                                      final bytes = await f.readAsBytes();
                                      setState(() {
                                        selectedFile = PickedDocFile(
                                          name: f.name,
                                          size: bytes.length,
                                          bytes: bytes,
                                        );
                                      });
                                    }
                                  },
                                  icon:
                                      const Icon(Icons.change_circle, size: 14),
                                  label: const Text('Change File'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                  ),
                                ),
                              ] else ...[
                                const Text(
                                  'Allowed file types: PDF, JPG, JPEG, PNG (Max 15MB)',
                                  style: TextStyle(
                                      fontSize: 11, color: Color(0xFF64748B)),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 10),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final files = await FilePicker.pickFiles(
                                      type: FileType.custom,
                                      allowedExtensions: [
                                        'pdf',
                                        'jpg',
                                        'jpeg',
                                        'png'
                                      ],
                                    );
                                    if (files.isNotEmpty) {
                                      final f = files.first;
                                      final bytes = await f.readAsBytes();
                                      setState(() {
                                        selectedFile = PickedDocFile(
                                          name: f.name,
                                          size: bytes.length,
                                          bytes: bytes,
                                        );
                                      });
                                    }
                                  },
                                  icon: const Icon(Icons.attach_file, size: 16),
                                  label: const Text('Select File'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10),
                                  ),
                                ),
                              ],
                            ],
                          ),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    if (selectedFile == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Please select a file to upload (PDF, JPG, PNG)'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();
                      Navigator.pop(dialogContext);

                      final bytes = selectedFile!.bytes;
                      final success = await hrProvider.uploadDocument(
                        employeeId: staff.id,
                        title: title,
                        category: category,
                        description: description,
                        issueDate: issueDate,
                        expiryDate: expiryDate,
                        fileName: selectedFile!.name,
                        fileBytes: bytes,
                      );

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success
                                ? 'Document "$title" uploaded successfully!'
                                : (hrProvider.employeeDocumentsError ??
                                    'Failed to upload document.')),
                            backgroundColor:
                                success ? Colors.green : Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Upload Document'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static void showReplaceDocumentModal(
      BuildContext context, HRDocumentItem doc, String employeeId) {
    final formKey = GlobalKey<FormState>();
    String title = doc.title;
    String description = doc.description;
    String issueDate = doc.issueDate;
    String expiryDate = doc.expiryDate;
    PickedDocFile? selectedFile;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final hrProvider = Provider.of<HRProvider>(context, listen: false);

            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        const Icon(Icons.sync, color: Colors.amber, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Replace Document File',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Current: ${doc.originalName} (v${doc.version})',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 500,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          initialValue: title,
                          decoration: const InputDecoration(
                            labelText: 'Document Title *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty
                              ? 'Title required'
                              : null,
                          onSaved: (val) => title = val?.trim() ?? '',
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          initialValue: description,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                          ),
                          onSaved: (val) => description = val?.trim() ?? '',
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey.shade50,
                          ),
                          child: Column(
                            children: [
                              Text(
                                selectedFile != null
                                    ? 'New: ${selectedFile!.name}'
                                    : 'Choose replacement file (PDF, JPG, PNG)',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final files = await FilePicker.pickFiles(
                                    type: FileType.custom,
                                    allowedExtensions: [
                                      'pdf',
                                      'jpg',
                                      'jpeg',
                                      'png'
                                    ],
                                  );
                                  if (files.isNotEmpty) {
                                    final f = files.first;
                                    final bytes = await f.readAsBytes();
                                    setState(() {
                                      selectedFile = PickedDocFile(
                                        name: f.name,
                                        size: bytes.length,
                                        bytes: bytes,
                                      );
                                    });
                                  }
                                },
                                icon: const Icon(Icons.file_upload, size: 16),
                                label: const Text('Pick New File'),
                              ),
                            ],
                          ),
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
                    backgroundColor: Colors.amber.shade700,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (selectedFile == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Please select a new file to replace the existing one.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();
                      Navigator.pop(dialogContext);

                      final bytes = selectedFile!.bytes;
                      final success = await hrProvider.replaceDocument(
                        docId: doc.id,
                        employeeId: employeeId,
                        title: title,
                        description: description,
                        issueDate: issueDate,
                        expiryDate: expiryDate,
                        fileName: selectedFile!.name,
                        fileBytes: bytes,
                      );

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success
                                ? 'Document replaced successfully!'
                                : (hrProvider.employeeDocumentsError ??
                                    'Failed to replace document.')),
                            backgroundColor:
                                success ? Colors.green : Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Replace Document'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static void showArchiveConfirmModal(
      BuildContext context, HRDocumentItem doc, String employeeId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.archive_outlined, color: Colors.orange),
            SizedBox(width: 8),
            Text('Archive Document?'),
          ],
        ),
        content: Text(
          'Are you sure you want to archive "${doc.title}"? It will be safely archived and hidden from active records.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final hrProvider =
                  Provider.of<HRProvider>(context, listen: false);
              final success =
                  await hrProvider.archiveDocument(doc.id, employeeId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Document "${doc.title}" has been archived.'
                        : (hrProvider.employeeDocumentsError ??
                            'Failed to archive document.')),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }
}
