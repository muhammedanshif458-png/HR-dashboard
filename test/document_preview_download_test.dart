import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:ly_hr_dashboard_flutter/models/hr_document.dart';
import 'package:ly_hr_dashboard_flutter/models/staff.dart';
import 'package:ly_hr_dashboard_flutter/providers/hr_provider.dart';
import 'package:ly_hr_dashboard_flutter/services/api_service.dart';
import 'package:ly_hr_dashboard_flutter/features/dashboard/staff_profile_view.dart';
import 'package:ly_hr_dashboard_flutter/widgets/document_preview_modal.dart';
import 'package:ly_hr_dashboard_flutter/widgets/pdf_view/pdf_view_widget.dart';

void main() {
  tearDown(() {
    ApiService.client = http.Client();
    ApiService.clearTokens();
  });

  group('Staff Profile HR Document Preview & Download Tests', () {
    testWidgets(
        'Renders distinct Preview and Download buttons with appropriate icons',
        (tester) async {
      final doc = HRDocumentItem(
        id: 'doc-101',
        employeeId: 'emp-101',
        title: 'Offer Letter 2026',
        category: 'Offer Letter',
        fileName: 'offer_101.pdf',
        originalName: 'offer_letter.pdf',
        filePath: '/uploads/documents/offer_101.pdf',
        fileType: 'application/pdf',
        fileSize: 1024 * 50,
      );

      final staff = Staff(
        id: 'emp-101',
        name: 'Arjun Kumar',
        email: 'arjun@company.com',
        phoneNumber: '9876543210',
        department: 'Tech',
        role: 'Engineer',
        joinDate: '2024-01-15',
        status: 'active',
        onLeaveToday: false,
      );

      final provider = HRProvider();
      provider.employeeDirectory = [staff];
      provider.selectedStaffId = 'emp-101';
      provider.documentsList = [doc];

      await tester.binding.setSurfaceSize(const Size(1600, 1200));

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<HRProvider>.value(
            value: provider,
            child: const Scaffold(
              body: StaffProfileView(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify that both distinct buttons exist with their respective icons
      final previewButton = find.byKey(const ValueKey('doc_preview_doc-101'));
      final downloadButton = find.byKey(const ValueKey('doc_download_doc-101'));

      expect(previewButton, findsOneWidget);
      expect(downloadButton, findsOneWidget);

      expect(find.descendant(of: previewButton, matching: find.text('Preview')),
          findsOneWidget);
      expect(
          find.descendant(
              of: previewButton,
              matching: find.byIcon(Icons.remove_red_eye_outlined)),
          findsOneWidget);

      expect(find.descendant(of: downloadButton, matching: find.text('Download')),
          findsOneWidget);
      expect(
          find.descendant(
              of: downloadButton, matching: find.byIcon(Icons.download_rounded)),
          findsOneWidget);
    });

    testWidgets(
        'Clicking Preview displays simplified DocumentPreviewModal with direct PDF viewer and Back action',
        (tester) async {
      final pdfBytes =
          Uint8List.fromList([37, 80, 68, 70, 45, 49, 46, 52]); // %PDF-1.4

      ApiService.setToken('test-hr-token');
      ApiService.client = MockClient((request) async {
        if (request.url.path == '/api/hr/documents/doc-pdf/download') {
          return http.Response.bytes(
            pdfBytes,
            200,
            headers: {'content-type': 'application/pdf'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final doc = HRDocumentItem(
        id: 'doc-pdf',
        employeeId: 'emp-202',
        title: 'Employment Agreement',
        category: 'Employment Agreement',
        fileName: 'contract.pdf',
        originalName: 'contract.pdf',
        filePath: '/uploads/documents/contract.pdf',
        fileType: 'application/pdf',
        fileSize: 1024 * 80,
      );

      final provider = HRProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => DocumentPreviewModal.show(
                  context,
                  doc: doc,
                  employeeId: 'emp-202',
                  provider: provider,
                ),
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Verify clean header with Back to Staff Profile and Document Title
      expect(find.text('Employment Agreement'), findsOneWidget);
      expect(find.text('Back to Staff Profile'), findsOneWidget);
      expect(find.byKey(const Key('preview_open_tab_button')), findsOneWidget);
      expect(find.byKey(const Key('preview_close_button')), findsOneWidget);

      // 2. Verify direct PDF viewer is rendered without placeholder card
      expect(find.byType(PdfViewWidget), findsOneWidget);

      // 3. Confirm absence of duplicate Download buttons, status/version chips, and redundant instructions
      expect(find.text('Download PDF'), findsNothing);
      expect(find.textContaining('Status:'), findsNothing);
      expect(find.textContaining('Click "Open in Browser Tab" to view'), findsNothing);

      // 4. Verify simple Back action closes preview and returns to Staff Profile
      await tester.tap(find.text('Back to Staff Profile'));
      await tester.pumpAndSettle();
      expect(find.byType(DocumentPreviewModal), findsNothing);
    });

    testWidgets('Preview for image formats renders Image.memory viewer',
        (tester) async {
      // 1x1 transparent PNG bytes
      final pngBytes = Uint8List.fromList([
        137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0,
        1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 10, 73, 68,
        65, 84, 120, 156, 99, 0, 1, 0, 0, 5, 0, 1, 13, 10, 45, 180, 0, 0, 0, 0,
        73, 69, 78, 68, 174, 66, 96, 130
      ]);

      ApiService.setToken('test-hr-token');
      ApiService.client = MockClient((request) async {
        return http.Response.bytes(
          pngBytes,
          200,
          headers: {'content-type': 'image/png'},
        );
      });

      final doc = HRDocumentItem(
        id: 'doc-img',
        employeeId: 'emp-203',
        title: 'ID Proof Photo',
        category: 'Identity Proof',
        fileName: 'id_card.png',
        originalName: 'id_card.png',
        filePath: '/uploads/documents/id_card.png',
        fileType: 'image/png',
        fileSize: 1024 * 30,
      );

      final provider = HRProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => DocumentPreviewModal.show(
                  context,
                  doc: doc,
                  employeeId: 'emp-203',
                  provider: provider,
                ),
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('ID Proof Photo'), findsOneWidget);
    });

    testWidgets(
        'Unsupported file format displays informative message and offers download',
        (tester) async {
      final docBytes = Uint8List.fromList([80, 75, 3, 4]); // ZIP/DOCX header

      ApiService.setToken('test-hr-token');
      ApiService.client = MockClient((request) async {
        return http.Response.bytes(
          docBytes,
          200,
          headers: {
            'content-type':
                'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
          },
        );
      });

      final doc = HRDocumentItem(
        id: 'doc-docx',
        employeeId: 'emp-204',
        title: 'Project Notes',
        category: 'Other',
        fileName: 'notes.docx',
        originalName: 'notes.docx',
        filePath: '/uploads/documents/notes.docx',
        fileType:
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        fileSize: 1024 * 40,
      );

      final provider = HRProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => DocumentPreviewModal.show(
                  context,
                  doc: doc,
                  employeeId: 'emp-204',
                  provider: provider,
                ),
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Preview is not available for this file type'),
          findsOneWidget);
      expect(find.text('Download Document'), findsOneWidget);
    });

    testWidgets(
        'Document missing (HTTP 404) displays clear error message and retry button',
        (tester) async {
      ApiService.setToken('test-hr-token');
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Document file does not exist on disk',
          }),
          404,
          headers: {'content-type': 'application/json'},
        );
      });

      final doc = HRDocumentItem(
        id: 'doc-missing',
        employeeId: 'emp-205',
        title: 'Missing Document',
        category: 'Other',
        fileName: 'missing.pdf',
        originalName: 'missing.pdf',
        filePath: '/uploads/documents/missing.pdf',
        fileType: 'application/pdf',
        fileSize: 1024,
      );

      final provider = HRProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => DocumentPreviewModal.show(
                  context,
                  doc: doc,
                  employeeId: 'emp-205',
                  provider: provider,
                ),
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Unable to Preview Document'), findsOneWidget);
      expect(find.textContaining('Document file does not exist on disk'),
          findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets(
        'Two different employee documents load their respective details and files',
        (tester) async {
      final requestedDocIds = <String>[];

      ApiService.setToken('test-hr-token');
      ApiService.client = MockClient((request) async {
        final docId = request.url.pathSegments[3];
        requestedDocIds.add(docId);
        return http.Response.bytes(
          Uint8List.fromList([37, 80, 68, 70]),
          200,
          headers: {'content-type': 'application/pdf'},
        );
      });

      final doc1 = HRDocumentItem(
        id: 'doc-emp1',
        employeeId: 'emp-1',
        title: 'Arjun Resume',
        category: 'Resume',
        fileName: 'arjun.pdf',
        originalName: 'arjun.pdf',
        filePath: '/uploads/documents/arjun.pdf',
        fileType: 'application/pdf',
        fileSize: 2048,
      );

      final doc2 = HRDocumentItem(
        id: 'doc-emp2',
        employeeId: 'emp-2',
        title: 'Deepa Contract',
        category: 'Employment Agreement',
        fileName: 'deepa.pdf',
        originalName: 'deepa.pdf',
        filePath: '/uploads/documents/deepa.pdf',
        fileType: 'application/pdf',
        fileSize: 4096,
      );

      final provider = HRProvider();

      // Fetch first employee's document
      final res1 = await provider.downloadEmployeeDocument(doc1.id);
      expect(res1, isNotNull);
      expect(requestedDocIds.last, 'doc-emp1');

      // Fetch second employee's document
      final res2 = await provider.downloadEmployeeDocument(doc2.id);
      expect(res2, isNotNull);
      expect(requestedDocIds.last, 'doc-emp2');

      expect(requestedDocIds, ['doc-emp1', 'doc-emp2']);
    });
  });
}
