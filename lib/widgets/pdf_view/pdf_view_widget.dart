import 'package:flutter/material.dart';
import 'pdf_view_stub.dart'
    if (dart.library.html) 'pdf_view_web.dart'
    if (dart.library.io) 'pdf_view_io.dart';

class PdfViewWidget extends StatelessWidget {
  final String blobUrl;
  final String title;

  const PdfViewWidget({
    super.key,
    required this.blobUrl,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return buildPdfPlatformView(blobUrl: blobUrl, title: title);
  }
}
