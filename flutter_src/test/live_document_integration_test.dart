import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:ly_hr_dashboard_flutter/services/api_service.dart';
import 'package:ly_hr_dashboard_flutter/providers/hr_provider.dart';
import 'package:ly_hr_dashboard_flutter/utils/file_download_helper.dart';

void main() {
  const backendBaseUrl = 'http://localhost:5000';

  group('Live End-to-End Real Document & API Integration Tests', () {
    String? liveAuthToken;

    setUpAll(() async {
      // 1. Authenticate with real live backend
      final loginResp = await http.post(
        Uri.parse('$backendBaseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': 'admin@hrmanagement.com',
          'password': 'Admin@12345',
        }),
      );

      expect(loginResp.statusCode, 200, reason: 'Live backend login failed');
      final loginJson = jsonDecode(loginResp.body);
      expect(loginJson['success'], isTrue);
      final token = loginJson['data']?['accessToken'] ??
          loginJson['data']?['token'] ??
          loginJson['token'];
      expect(token, isNotNull);
      liveAuthToken = token.toString();
      ApiService.setToken(liveAuthToken!);
    });

    tearDownAll(() {
      ApiService.clearTokens();
    });

    test('1. Real PDF document retrieval, validation, and content integrity', () async {
      const realPdfDocId = '6ad5e4e18c4995472b211c06'; // java.pdf (81 KB)

      // Fetch metadata
      final docItem = await ApiService.getEmployeeDocument(realPdfDocId);
      expect(docItem.id, realPdfDocId);
      expect(docItem.isPdf, isTrue);
      expect(docItem.originalName, 'java.pdf');

      // Fetch actual document file bytes via live endpoint
      final response = await ApiService.downloadEmployeeDocument(realPdfDocId);
      expect(response.statusCode, 200);
      expect(response.headers['content-type'], anyOf(contains('application/pdf'), equals('application/octet-stream')));

      final bytes = response.bodyBytes;
      expect(bytes.length, greaterThan(1000));

      // Validate PDF Magic Header (%PDF)
      final magicHeader = String.fromCharCodes(bytes.take(4));
      expect(magicHeader, '%PDF', reason: 'File must be an authentic PDF file');

      // Validate PDF EOF marker at the end
      final tail = String.fromCharCodes(bytes.skip(bytes.length - 20));
      expect(tail, contains('%%EOF'), reason: 'PDF must have valid EOF termination');

      // Verify that FileDownloadHelper processes the bytes
      final dlSuccess = await FileDownloadHelper.downloadFile(
        bytes: bytes,
        fileName: docItem.originalName,
        mimeType: 'application/pdf',
      );
      expect(dlSuccess, isTrue);
    });

    test('2. Real Image document retrieval and image format validation', () async {
      const realImageDocId = '6ad5e53e8c4995472b211c25'; // adar card (1.98 MB JPG)

      // Fetch metadata
      final docItem = await ApiService.getEmployeeDocument(realImageDocId);
      expect(docItem.id, realImageDocId);
      expect(docItem.isImage, isTrue);
      expect(docItem.originalName, '134341138610677831.jpg');

      // Download image from live backend
      final response = await ApiService.downloadEmployeeDocument(realImageDocId);
      expect(response.statusCode, 200);
      expect(response.headers['content-type'], anyOf(contains('image'), equals('application/octet-stream')));

      final bytes = response.bodyBytes;
      expect(bytes.length, greaterThan(100000), reason: 'Should download full image bytes (1.98 MB)');

      // Validate JPEG Magic bytes (0xFF, 0xD8)
      expect(bytes[0], 0xFF);
      expect(bytes[1], 0xD8);

      final dlSuccess = await FileDownloadHelper.downloadFile(
        bytes: bytes,
        fileName: docItem.originalName,
        mimeType: 'image/jpeg',
      );
      expect(dlSuccess, isTrue);
    });

    test('3. Two different employee documents retrieve distinct files and employees', () async {
      // Document from Employee A
      const docAId = '6ad5e4e18c4995472b211c06'; // java.pdf (Employee 6ad5dfcc8c4995472b211b2d)
      // Document from Employee B
      const docBId = '6ad84e1609ebf148d34f6fdc'; // arjun resume (Employee 6ad84c0309ebf148d34f6fc5)

      final docA = await ApiService.getEmployeeDocument(docAId);
      final docB = await ApiService.getEmployeeDocument(docBId);

      expect(docA.employeeId, isNot(equals(docB.employeeId)));
      expect(docA.originalName, 'java.pdf');
      expect(docB.originalName, 'sample_resume_duplicate.pdf');

      final respA = await ApiService.downloadEmployeeDocument(docAId);
      final respB = await ApiService.downloadEmployeeDocument(docBId);

      expect(respA.bodyBytes.length, isNot(equals(respB.bodyBytes.length)));
      expect(respA.statusCode, 200);
      expect(respB.statusCode, 200);
    });

    test('4. Missing document returns clear 404 error and does not produce a false file', () async {
      const nonExistentId = '6ad000000000000000000000';
      expect(
        () => ApiService.downloadEmployeeDocument(nonExistentId),
        throwsA(isA<Exception>()),
      );
    });

    test('5. Unauthorized request without token returns 401 error', () async {
      ApiService.clearTokens();
      const realDocId = '6ad5e4e18c4995472b211c06';

      expect(
        () => ApiService.downloadEmployeeDocument(realDocId),
        throwsA(isA<Exception>()),
      );

      // Restore token
      ApiService.setToken(liveAuthToken!);
    });

    test('6. HRProvider.downloadEmployeeDocument returns DownloadedEmployeeDocument with live data', () async {
      final provider = HRProvider();
      const realDocId = '6ad5e4e18c4995472b211c06';

      final downloaded = await provider.downloadEmployeeDocument(realDocId);
      expect(downloaded, isNotNull);
      expect(downloaded!.bytes.length, greaterThan(1000));
      expect(downloaded.contentType, anyOf(contains('application/pdf'), equals('application/octet-stream')));
      expect(provider.employeeDocumentsError, isNull);
    });
  });
}
