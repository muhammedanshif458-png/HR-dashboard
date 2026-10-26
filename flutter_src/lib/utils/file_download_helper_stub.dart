Future<bool> downloadFileImpl({
  required List<int> bytes,
  required String fileName,
  required String mimeType,
}) {
  throw UnsupportedError('downloadFile is not supported on this platform');
}

Future<bool> openInBrowserTabImpl({
  required List<int> bytes,
  required String mimeType,
  String? fileName,
}) {
  throw UnsupportedError('openInBrowserTab is not supported on this platform');
}

String createBlobUrlImpl({
  required List<int> bytes,
  required String mimeType,
}) {
  return '';
}

void revokeBlobUrlImpl(String url) {}
