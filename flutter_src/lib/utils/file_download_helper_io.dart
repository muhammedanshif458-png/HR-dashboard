import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

Future<bool> downloadFileImpl({
  required List<int> bytes,
  required String fileName,
  required String mimeType,
}) async {
  try {
    final u8 = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    try {
      final savedPath = await FilePicker.saveFile(
        dialogTitle: 'Save document',
        fileName: fileName,
        bytes: u8,
        type: FileType.any,
      );
      if (savedPath != null) return true;
    } catch (_) {}

    // Fallback if picker is unsupported or headless: save to downloads/temp directory
    final tempDir = Directory.systemTemp;
    final fallbackFile = File('${tempDir.path}/$fileName');
    await fallbackFile.writeAsBytes(u8, flush: true);
    return fallbackFile.existsSync();
  } catch (e) {
    return false;
  }
}

Future<bool> openInBrowserTabImpl({
  required List<int> bytes,
  required String mimeType,
  String? fileName,
}) async {
  try {
    final tempDir = Directory.systemTemp;
    final cleanName = fileName ?? 'preview_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final tempFile = File('${tempDir.path}/$cleanName');
    final u8 = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    await tempFile.writeAsBytes(u8, flush: true);

    final uri = Uri.file(tempFile.path);
    return await launchUrl(uri);
  } catch (e) {
    return false;
  }
}

String createBlobUrlImpl({
  required List<int> bytes,
  required String mimeType,
}) {
  return '';
}

void revokeBlobUrlImpl(String url) {}
