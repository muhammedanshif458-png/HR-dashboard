// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:async';

Future<bool> downloadFileImpl({
  required List<int> bytes,
  required String fileName,
  required String mimeType,
}) async {
  try {
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrl(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..style.display = 'none';

    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);

    Timer(const Duration(seconds: 15), () {
      try {
        html.Url.revokeObjectUrl(url);
      } catch (_) {}
    });
    return true;
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
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrl(blob);
    html.window.open(url, '_blank');

    // Keep object URL active for 10 minutes to allow previewing
    Timer(const Duration(minutes: 10), () {
      try {
        html.Url.revokeObjectUrl(url);
      } catch (_) {}
    });
    return true;
  } catch (e) {
    return false;
  }
}

String createBlobUrlImpl({
  required List<int> bytes,
  required String mimeType,
}) {
  try {
    final blob = html.Blob([bytes], mimeType);
    return html.Url.createObjectUrl(blob);
  } catch (_) {
    return '';
  }
}

void revokeBlobUrlImpl(String url) {
  try {
    if (url.isNotEmpty) {
      html.Url.revokeObjectUrl(url);
    }
  } catch (_) {}
}
