import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:ly_hr_dashboard_flutter/core/config.dart';
import 'package:ly_hr_dashboard_flutter/models/hr_models.dart';
import 'package:ly_hr_dashboard_flutter/providers/hr_provider.dart';
import 'package:ly_hr_dashboard_flutter/services/api_service.dart';
import 'package:ly_hr_dashboard_flutter/widgets/medical_document_preview_dialog.dart';
import 'package:ly_hr_dashboard_flutter/widgets/pdf_view/pdf_view_widget.dart';
import 'package:ly_hr_dashboard_flutter/features/leaves/leave_management_view.dart';

void main() {
  setUp(() {
    AppConfig.resetApiBaseUrl();
    ApiService.clearTokens();
    ApiService.client = http.Client();
  });

  tearDown(() {
    AppConfig.resetApiBaseUrl();
    ApiService.clearTokens();
    ApiService.client = http.Client();
  });

  // Standard %PDF-1.5 test bytes
  final validPdfBytes = Uint8List.fromList([
    0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x35, 0x0A, 0x25, 0xE2, 0xE3,
    0xCF, 0xD3, 0x0A, 0x31, 0x20, 0x30, 0x20, 0x6F, 0x62, 0x6A, 0x0A, 0x3C,
    0x3C, 0x2F, 0x54, 0x79, 0x70, 0x65, 0x2F, 0x43, 0x61, 0x74, 0x61, 0x6C,
    0x6F, 0x67, 0x2F, 0x50, 0x61, 0x67, 0x65, 0x73, 0x20, 0x32, 0x20, 0x30,
    0x20, 0x52, 0x3E, 0x3E, 0x0A, 0x65, 0x6E, 0x64, 0x6F, 0x62, 0x6A, 0x0A,
  ]);

  // Valid 1x1 PNG bytes
  final validPngBytes = Uint8List.fromList([
    137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0,
    1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 10, 73, 68,
    65, 84, 120, 156, 99, 0, 1, 0, 0, 5, 0, 1, 13, 10, 45, 180, 0, 0, 0, 0,
    73, 69, 78, 68, 174, 66, 96, 130,
  ]);

  final sampleLeave = LeaveRequest(
    id: 'leave-med-001',
    staffId: 'staff-101',
    employeeName: 'Rahul Menon',
    employeeEmail: 'rahul.menon@company.com',
    department: 'Engineering',
    leaveType: 'Medical',
    fromDate: '2026-11-01',
    toDate: '2026-11-05',
    daysCount: 5,
    reason: 'Undergoing knee arthroscopy and post-op rehabilitation',
    status: 'Pending',
    hasMedicalProof: true,
    medicalProofUrl: '/api/hr/documents/6ad9c4638bc6d26cc2a3dd84/download',
    medicalProofFileName: 'dr_sharma_medical_cert.pdf',
    medicalProofFileType: 'application/pdf',
  );

  group('1. ApiService URL Normalization & Resolution', () {
    test('resolves bare document ID into authenticated HR download endpoint', () {
      final uri = ApiService.buildDocumentUri('6ad9c4638bc6d26cc2a3dd84');
      expect(
        uri.toString(),
        'http://localhost:5000/api/hr/documents/6ad9c4638bc6d26cc2a3dd84/download',
      );
    });

    test('preserves relative /api/hr/documents path correctly', () {
      final uri = ApiService.buildDocumentUri(
          '/api/hr/documents/6ad9c4638bc6d26cc2a3dd84/download');
      expect(
        uri.toString(),
        'http://localhost:5000/api/hr/documents/6ad9c4638bc6d26cc2a3dd84/download',
      );
    });

    test('fixes missing /api in relative path', () {
      final uri = ApiService.buildDocumentUri(
          '/hr/documents/6ad9c4638bc6d26cc2a3dd84/download');
      expect(
        uri.toString(),
        'http://localhost:5000/api/hr/documents/6ad9c4638bc6d26cc2a3dd84/download',
      );
    });

    test('cleans up duplicated /api/api in path', () {
      final uri = ApiService.buildDocumentUri(
          '/api/api/hr/documents/6ad9c4638bc6d26cc2a3dd84/download');
      expect(
        uri.toString(),
        'http://localhost:5000/api/hr/documents/6ad9c4638bc6d26cc2a3dd84/download',
      );
    });

    test('avoids duplicated /api when baseUrl ends with /api', () {
      AppConfig.setApiBaseUrl('http://192.168.1.100:5000/api');
      final uri = ApiService.buildDocumentUri(
          '/api/hr/documents/6ad9c4638bc6d26cc2a3dd84/download');
      expect(
        uri.toString(),
        'http://192.168.1.100:5000/api/hr/documents/6ad9c4638bc6d26cc2a3dd84/download',
      );
    });

    test('maps staff documents route to hr download endpoint for HR admin access', () {
      final uri = ApiService.buildDocumentUri(
          '/staff/documents/6ad9c4638bc6d26cc2a3dd84/download');
      expect(
        uri.toString(),
        'http://localhost:5000/api/hr/documents/6ad9c4638bc6d26cc2a3dd84/download',
      );
    });
  });

  group('2. PDF Signature Validation (%PDF-)', () {
    test('returns true for bytes starting with standard %PDF- header', () {
      expect(ApiService.isPdfSignature(validPdfBytes), isTrue);
    });

    test('returns true when %PDF- is preceded by leading whitespace or comments', () {
      final bytesWithLeadingBytes = Uint8List.fromList([
        0xEF, 0xBB, 0xBF, // UTF-8 BOM
        0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x37,
      ]);
      expect(ApiService.isPdfSignature(bytesWithLeadingBytes), isTrue);
    });

    test('returns false for plain text, JSON, or HTML content', () {
      final jsonBytes = utf8.encode('{"success":false,"message":"Not a PDF"}');
      final htmlBytes = utf8.encode('<!DOCTYPE html><html><body>Error</body></html>');
      expect(ApiService.isPdfSignature(jsonBytes), isFalse);
      expect(ApiService.isPdfSignature(htmlBytes), isFalse);
    });

    test('returns false for empty bytes or truncated bytes < 5 chars', () {
      expect(ApiService.isPdfSignature([]), isFalse);
      expect(ApiService.isPdfSignature([0x25, 0x50]), isFalse);
    });
  });

  group('3. ApiService.fetchMedicalDocumentSecurely API & Error Handling', () {
    test('throws 401 error when authentication token is missing', () async {
      ApiService.clearTokens();
      expect(
        () => ApiService.fetchMedicalDocumentSecurely(
            '/api/hr/documents/doc-1/download'),
        throwsA(predicate((e) =>
            e.toString().contains('Authentication required') &&
            e.toString().contains('401'))),
      );
    });

    test('sends Bearer token and returns binary bytes on HTTP 200', () async {
      String? sentAuth;
      String? sentPath;

      ApiService.setToken('hr-super-secret-token');
      ApiService.client = MockClient((request) async {
        sentAuth = request.headers['Authorization'];
        sentPath = request.url.path;
        return http.Response.bytes(
          validPdfBytes,
          200,
          headers: {'content-type': 'application/pdf'},
        );
      });

      final res = await ApiService.fetchMedicalDocumentSecurely(
        '6ad9c4638bc6d26cc2a3dd84',
        expectedFileName: 'dr_sharma_medical_cert.pdf',
        expectedFileType: 'application/pdf',
      );

      expect(sentAuth, 'Bearer hr-super-secret-token');
      expect(sentPath, '/api/hr/documents/6ad9c4638bc6d26cc2a3dd84/download');
      expect(res['statusCode'], 200);
      expect(res['bytes'], validPdfBytes);
      expect(res['isPdf'], isTrue);
      expect(res['contentType'], 'application/pdf');
    });

    test('handles 401 unauthenticated response from server', () async {
      ApiService.setToken('expired-token');
      ApiService.client = MockClient((request) async {
        return http.Response('Unauthorized', 401);
      });

      expect(
        () => ApiService.fetchMedicalDocumentSecurely(
            '/api/hr/documents/doc-1/download'),
        throwsA(predicate((e) =>
            e.toString().contains('Authentication expired') &&
            e.toString().contains('401'))),
      );
    });

    test('handles 403 forbidden response from server', () async {
      ApiService.setToken('staff-token');
      ApiService.client = MockClient((request) async {
        return http.Response('Forbidden', 403);
      });

      expect(
        () => ApiService.fetchMedicalDocumentSecurely(
            '/api/hr/documents/doc-1/download'),
        throwsA(predicate((e) =>
            e.toString().contains('Access denied') &&
            e.toString().contains('403'))),
      );
    });

    test('handles 404 document not found response from server', () async {
      ApiService.setToken('hr-token');
      ApiService.client = MockClient((request) async {
        return http.Response('Not Found', 404);
      });

      expect(
        () => ApiService.fetchMedicalDocumentSecurely(
            '/api/hr/documents/missing-doc/download'),
        throwsA(predicate((e) =>
            e.toString().contains('Medical document not found') &&
            e.toString().contains('404'))),
      );
    });

    test('handles HTTP 200 with JSON error message instead of PDF file', () async {
      ApiService.setToken('hr-token');
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Document file does not exist on disk',
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      expect(
        () => ApiService.fetchMedicalDocumentSecurely(
            '/api/hr/documents/doc-missing/download',
            expectedFileName: 'medical_cert.pdf'),
        throwsA(predicate((e) =>
            e.toString().contains('Document file does not exist on disk'))),
      );
    });

    test('handles HTTP 200 with HTML error page', () async {
      ApiService.setToken('hr-token');
      ApiService.client = MockClient((request) async {
        return http.Response(
          '<!DOCTYPE html><html><body>Error 502 Bad Gateway</body></html>',
          200,
          headers: {'content-type': 'text/html; charset=utf-8'},
        );
      });

      expect(
        () => ApiService.fetchMedicalDocumentSecurely(
            '/api/hr/documents/doc-1/download',
            expectedFileName: 'medical_cert.pdf'),
        throwsA(predicate((e) =>
            e.toString().contains('HTML error page'))),
      );
    });

    test('rejects empty response bytes (0 bytes)', () async {
      ApiService.setToken('hr-token');
      ApiService.client = MockClient((request) async {
        return http.Response.bytes(
          [],
          200,
          headers: {'content-type': 'application/pdf'},
        );
      });

      expect(
        () => ApiService.fetchMedicalDocumentSecurely(
            '/api/hr/documents/empty-doc/download',
            expectedFileName: 'medical_cert.pdf'),
        throwsA(predicate((e) => e.toString().contains('empty (0 bytes)'))),
      );
    });

    test('rejects non-PDF bytes when PDF document is expected', () async {
      ApiService.setToken('hr-token');
      ApiService.client = MockClient((request) async {
        return http.Response.bytes(
          utf8.encode('corrupted content without magic header'),
          200,
          headers: {'content-type': 'application/pdf'},
        );
      });

      expect(
        () => ApiService.fetchMedicalDocumentSecurely(
            '/api/hr/documents/corrupt-pdf/download',
            expectedFileName: 'medical_cert.pdf',
            expectedFileType: 'application/pdf'),
        throwsA(predicate((e) => e.toString().contains('%PDF-'))),
      );
    });

    test('correctly detects and returns image content', () async {
      ApiService.setToken('hr-token');
      ApiService.client = MockClient((request) async {
        return http.Response.bytes(
          validPngBytes,
          200,
          headers: {'content-type': 'image/png'},
        );
      });

      final res = await ApiService.fetchMedicalDocumentSecurely(
        '/api/hr/documents/image-doc/download',
        expectedFileName: 'cert.png',
        expectedFileType: 'image/png',
      );

      expect(res['statusCode'], 200);
      expect(res['isImage'], isTrue);
      expect(res['isPdf'], isFalse);
      expect(res['contentType'], 'image/png');
    });
  });

  group('4. MedicalDocumentPreviewDialog Widget & Render Tests', () {
    testWidgets('renders loading state initially while fetching bytes',
        (tester) async {
      ApiService.setToken('hr-token');
      ApiService.client = MockClient((request) async {
        await Future.delayed(const Duration(milliseconds: 500));
        return http.Response.bytes(
          validPdfBytes,
          200,
          headers: {'content-type': 'application/pdf'},
        );
      });

      await tester.binding.setSurfaceSize(const Size(1200, 900));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MedicalDocumentPreviewDialog(leave: sampleLeave),
          ),
        ),
      );

      // Verify loading state is shown initially
      expect(find.byKey(const Key('preview_loading_indicator')), findsOneWidget);
      expect(
        find.textContaining('Retrieving medical certificate for Rahul Menon'),
        findsOneWidget,
      );

      // Settle async loading
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
    });

    testWidgets('renders genuine PdfViewWidget and supplementary bar when valid PDF retrieved',
        (tester) async {
      ApiService.setToken('hr-token');
      ApiService.client = MockClient((request) async {
        return http.Response.bytes(
          validPdfBytes,
          200,
          headers: {'content-type': 'application/pdf'},
        );
      });

      await tester.binding.setSurfaceSize(const Size(1200, 900));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MedicalDocumentPreviewDialog(leave: sampleLeave),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Verify header elements
      expect(find.text('Back to Leave Requests'), findsOneWidget);
      expect(find.text('dr_sharma_medical_cert.pdf'), findsOneWidget);
      expect(find.byKey(const Key('preview_open_tab_button')), findsOneWidget);
      expect(find.byKey(const Key('preview_download_button')), findsOneWidget);
      expect(find.byKey(const Key('preview_close_button')), findsOneWidget);

      // 2. Verify supplementary information bar
      expect(find.textContaining('Employee: Rahul Menon'), findsOneWidget);
      expect(find.textContaining('Dates: 2026-11-01 to 2026-11-05 (5 days)'), findsOneWidget);
      expect(find.textContaining('Ref: /api/hr/documents/6ad9c4638bc6d26cc2a3dd84/download'), findsOneWidget);

      // 3. Verify real PdfViewWidget is rendered in the main area (NOT a metadata card pretending to be preview)
      expect(find.byType(PdfViewWidget), findsOneWidget);

      // 4. Verify absence of misleading fake metadata card in preview area
      expect(find.text('Verified via HR Security Policy. Sensitive medical files are not cached locally.'), findsNothing);
    });

    testWidgets('renders interactive image viewer for image certificate',
        (tester) async {
      final imageLeave = LeaveRequest(
        id: 'leave-img-001',
        staffId: 'staff-102',
        employeeName: 'Priya Nair',
        employeeEmail: 'priya@company.com',
        department: 'Finance',
        leaveType: 'Medical',
        fromDate: '2026-10-10',
        toDate: '2026-10-12',
        daysCount: 3,
        reason: 'Viral fever',
        status: 'Pending',
        hasMedicalProof: true,
        medicalProofUrl: '/api/hr/documents/doc-img-99/download',
        medicalProofFileName: 'prescription.png',
        medicalProofFileType: 'image/png',
      );

      ApiService.setToken('hr-token');
      ApiService.client = MockClient((request) async {
        return http.Response.bytes(
          validPngBytes,
          200,
          headers: {'content-type': 'image/png'},
        );
      });

      await tester.binding.setSurfaceSize(const Size(1200, 900));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MedicalDocumentPreviewDialog(leave: imageLeave),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify interactive image viewer is rendered
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.byKey(const Key('medical_image_viewer_container')), findsOneWidget);
    });

    testWidgets('displays actual API error with Retry and does NOT fall back to fake document',
        (tester) async {
      ApiService.setToken('hr-token');
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'Medical document has been archived or relocated'}),
          404,
          headers: {'content-type': 'application/json'},
        );
      });

      await tester.binding.setSurfaceSize(const Size(1200, 900));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MedicalDocumentPreviewDialog(leave: sampleLeave),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify error banner is shown with actual error message
      expect(find.byKey(const Key('preview_error_banner')), findsOneWidget);
      expect(find.text('Unable to Retrieve Medical Certificate'), findsOneWidget);
      expect(find.textContaining('Medical document not found'), findsOneWidget);
      expect(find.byKey(const Key('preview_retry_button')), findsOneWidget);

      // Verify NO fake document is rendered
      expect(find.byType(PdfViewWidget), findsNothing);
      expect(find.byType(InteractiveViewer), findsNothing);
    });
  });

  group('5. Leave Management View Integration & Actions', () {
    testWidgets(
        'Leave Details modal displays real Preview and Download buttons for medical leave',
        (tester) async {
      final provider = HRProvider();
      provider.leaveRequests = [sampleLeave];

      ApiService.setToken('hr-test-token');
      ApiService.client = MockClient((request) async {
        if (request.url.path == '/api/hr/leaves') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  '_id': 'leave-med-001',
                  'employee': {
                    '_id': 'staff-101',
                    'firstName': 'Rahul',
                    'lastName': 'Menon',
                    'email': 'rahul.menon@company.com',
                    'department': 'Engineering',
                  },
                  'leaveType': 'MEDICAL',
                  'startDate': '2026-11-01T00:00:00.000Z',
                  'endDate': '2026-11-05T00:00:00.000Z',
                  'daysCount': 5,
                  'reason': 'Undergoing knee arthroscopy',
                  'status': 'PENDING',
                  'hasMedicalProof': true,
                  'medicalProofUrl':
                      '/api/hr/documents/6ad9c4638bc6d26cc2a3dd84/download',
                  'medicalProofFileName': 'dr_sharma_medical_cert.pdf',
                  'medicalProofFileType': 'application/pdf',
                }
              ],
              'pagination': {
                'page': 1,
                'limit': 20,
                'total': 1,
                'totalPages': 1,
              }
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path.contains('/download')) {
          return http.Response.bytes(
            validPdfBytes,
            200,
            headers: {'content-type': 'application/pdf'},
          );
        }
        return http.Response('Not Found', 404);
      });

      await tester.binding.setSurfaceSize(const Size(2400, 1200));

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<HRProvider>.value(
            value: provider,
            child: const Scaffold(
              body: LeaveManagementView(),
            ),
          ),
        ),
      );

      // Trigger post frame callback and settle data loading
      await tester.pump();
      await tester.pumpAndSettle();

      // 1. Verify medical proof badge is present in table
      expect(find.text('Proof Attached'), findsOneWidget);

      // 2. Click "View Details & Proof" action button on the leave row
      final viewButton = find.byTooltip('View Details & Proof');
      expect(viewButton, findsOneWidget);
      await tester.tap(viewButton);
      await tester.pumpAndSettle();

      // 3. Verify Leave Request Details modal is displayed with medical proof section
      expect(find.text('Leave Request Details'), findsOneWidget);
      expect(find.text('Medical Document & Supporting Evidence'), findsOneWidget);

      // 4. Verify distinct Preview and Download buttons exist
      final previewBtn = find.byKey(const Key('leave_medical_proof_preview_button'));
      final downloadBtn = find.byKey(const Key('leave_medical_proof_download_button'));
      expect(previewBtn, findsOneWidget);
      expect(downloadBtn, findsOneWidget);
      expect(find.text('Preview Medical PDF'), findsOneWidget);
      expect(find.text('Download Certificate'), findsOneWidget);

      // 5. Clicking "Preview Medical PDF" launches MedicalDocumentPreviewDialog
      await tester.tap(previewBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.byType(MedicalDocumentPreviewDialog), findsOneWidget);
      expect(find.byType(PdfViewWidget), findsOneWidget);

      // 6. Back button dismisses preview and returns to details modal
      await tester.tap(find.byKey(const Key('preview_back_button')));
      await tester.pumpAndSettle();
      expect(find.byType(MedicalDocumentPreviewDialog), findsNothing);
      expect(find.text('Leave Request Details'), findsOneWidget);
    });
  });
}
