import 'package:flutter/material.dart';

Widget buildPdfPlatformView({
  required String blobUrl,
  required String title,
}) {
  return Container(
    key: const Key('pdf_viewer_platform_view'),
    color: const Color(0xFFF8FAFC),
    child: const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.picture_as_pdf_rounded, size: 56, color: Color(0xFFDC2626)),
          SizedBox(height: 12),
          Text(
            'PDF Document Viewer',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    ),
  );
}
