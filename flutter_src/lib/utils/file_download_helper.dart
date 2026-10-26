import 'file_download_helper_stub.dart'
    if (dart.library.html) 'file_download_helper_web.dart'
    if (dart.library.io) 'file_download_helper_io.dart';

abstract class FileDownloadHelper {
  /// Downloads a file to the user's device with the provided file name and MIME type.
  static Future<bool> downloadFile({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
  }) =>
      downloadFileImpl(
        bytes: bytes,
        fileName: fileName,
        mimeType: mimeType,
      );

  /// Opens the document in a new browser tab or system default viewer.
  static Future<bool> openInBrowserTab({
    required List<int> bytes,
    required String mimeType,
    String? fileName,
  }) =>
      openInBrowserTabImpl(
        bytes: bytes,
        mimeType: mimeType,
        fileName: fileName,
      );

  /// Creates a local Blob/object URL for web iframes or browsers.
  static String createBlobUrl({
    required List<int> bytes,
    required String mimeType,
  }) =>
      createBlobUrlImpl(
        bytes: bytes,
        mimeType: mimeType,
      );

  /// Cleans up a Blob/object URL.
  static void revokeBlobUrl(String url) => revokeBlobUrlImpl(url);
}
