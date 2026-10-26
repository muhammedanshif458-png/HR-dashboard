import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/hr_models.dart';
import '../providers/hr_provider.dart';
import '../services/api_service.dart';
import '../utils/file_download_helper.dart';
import 'pdf_view/pdf_view_widget.dart';

/// A secure, authenticated preview dialog for leave medical proofs.
/// Renders genuine PDF pages using the project's PDF viewer, displays images
/// with interactive zoom/pan, and provides real download actions without dummy stubs.
class MedicalDocumentPreviewDialog extends StatefulWidget {
  final LeaveRequest leave;
  final HRProvider? provider;

  const MedicalDocumentPreviewDialog({
    super.key,
    required this.leave,
    this.provider,
  });

  static Future<void> show(
    BuildContext context, {
    required LeaveRequest leave,
    HRProvider? provider,
  }) {
    final hrProvider =
        provider ?? Provider.of<HRProvider>(context, listen: false);
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => MedicalDocumentPreviewDialog(
        leave: leave,
        provider: hrProvider,
      ),
    );
  }

  @override
  State<MedicalDocumentPreviewDialog> createState() =>
      _MedicalDocumentPreviewDialogState();
}

class _MedicalDocumentPreviewDialogState
    extends State<MedicalDocumentPreviewDialog> {
  bool _isLoading = true;
  bool _isDownloading = false;
  String? _errorMessage;
  Uint8List? _documentBytes;
  String? _contentType;
  String? _blobUrl;
  bool _isPdf = false;
  bool _isImage = false;

  String get _fileName {
    final name = widget.leave.medicalProofFileName;
    if (name != null && name.trim().isNotEmpty) {
      return name.trim();
    }
    final url = widget.leave.medicalProofUrl ?? '';
    if (url.contains('/')) {
      final lastSegment = url.split('/').last;
      if (lastSegment.contains('.')) return lastSegment;
    }
    return widget.leave.isMedical ? 'medical_certificate.pdf' : 'document.pdf';
  }

  @override
  void initState() {
    super.initState();
    _loadMedicalDocument();
  }

  @override
  void dispose() {
    if (_blobUrl != null && _blobUrl!.isNotEmpty) {
      FileDownloadHelper.revokeBlobUrl(_blobUrl!);
    }
    super.dispose();
  }

  Future<void> _loadMedicalDocument() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final docUrlOrId = widget.leave.medicalProofUrl ?? widget.leave.id;

    if (docUrlOrId.isEmpty) {
      setState(() {
        _errorMessage =
            'No medical document reference or URL found for this leave request.';
        _isLoading = false;
      });
      return;
    }

    try {
      final result = await ApiService.fetchMedicalDocumentSecurely(
        docUrlOrId,
        expectedFileName: widget.leave.medicalProofFileName,
        expectedFileType: widget.leave.medicalProofFileType,
      );

      if (!mounted) return;

      final bytes = result['bytes'] as Uint8List;
      final cType = result['contentType'] as String;
      final isPdf = result['isPdf'] as bool? ?? false;
      final isImage = result['isImage'] as bool? ?? false;

      String? blobUrl;
      try {
        blobUrl = FileDownloadHelper.createBlobUrl(
          bytes: bytes,
          mimeType: cType,
        );
      } catch (_) {}

      setState(() {
        _documentBytes = bytes;
        _contentType = cType;
        _blobUrl = blobUrl;
        _isPdf = isPdf;
        _isImage = isImage;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _handleDownload() async {
    if (_documentBytes == null || _documentBytes!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document data is not loaded yet.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isDownloading = true);

    try {
      final success = await FileDownloadHelper.downloadFile(
        bytes: _documentBytes!,
        fileName: _fileName,
        mimeType: _contentType ?? (_isPdf ? 'application/pdf' : 'application/octet-stream'),
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloaded "$_fileName" successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download was cancelled or not saved.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download document: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  Future<void> _handleOpenInBrowserTab() async {
    if (_documentBytes == null || _documentBytes!.isEmpty) return;

    final success = await FileDownloadHelper.openInBrowserTab(
      bytes: _documentBytes!,
      mimeType: _contentType ?? (_isPdf ? 'application/pdf' : 'application/octet-stream'),
      fileName: _fileName,
    );

    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Could not open document in a new tab. Pop-up may be blocked.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = (screenSize.width * 0.92).clamp(380.0, 1300.0);
    final dialogHeight = (screenSize.height * 0.92).clamp(500.0, 960.0);

    return Dialog(
      key: const Key('medical_document_preview_dialog'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          children: [
            _buildHeader(context),
            _buildSupplementaryInfoBar(),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          TextButton.icon(
            key: const Key('preview_back_button'),
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Back to Leave Requests'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1E293B),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isPdf
                      ? Icons.picture_as_pdf_rounded
                      : (_isImage ? Icons.image_rounded : Icons.description_rounded),
                  size: 20,
                  color: _isPdf ? const Color(0xFFDC2626) : const Color(0xFF2563EB),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _fileName,
                    key: const Key('preview_dialog_title'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (_documentBytes != null && _documentBytes!.isNotEmpty) ...[
            if (_isPdf)
              IconButton(
                key: const Key('preview_open_tab_button'),
                icon: const Icon(Icons.open_in_new_rounded, size: 20),
                tooltip: 'Open in Browser Tab',
                color: const Color(0xFF2563EB),
                onPressed: _handleOpenInBrowserTab,
              ),
            IconButton(
              key: const Key('preview_download_button'),
              icon: _isDownloading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_rounded, size: 20),
              tooltip: 'Download File',
              color: const Color(0xFF0F766E),
              onPressed: _isDownloading ? null : _handleDownload,
            ),
          ],
          IconButton(
            key: const Key('preview_close_button'),
            icon: const Icon(Icons.close_rounded, size: 22),
            tooltip: 'Close Preview',
            color: const Color(0xFF64748B),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  /// Supplementary metadata bar showing leave context without replacing the actual document view
  Widget _buildSupplementaryInfoBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0)),
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 6,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_outline, size: 15, color: Color(0xFF475569)),
              const SizedBox(width: 5),
              Text(
                'Employee: ${widget.leave.employeeName}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF475569)),
              const SizedBox(width: 5),
              Text(
                'Dates: ${widget.leave.fromDate} to ${widget.leave.toDate} (${widget.leave.calculatedDays} ${widget.leave.calculatedDays == 1 ? 'day' : 'days'})',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF475569),
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 13, color: Color(0xFF2563EB)),
              const SizedBox(width: 4),
              Text(
                'Ref: ${widget.leave.medicalProofUrl ?? widget.leave.id}',
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          key: const Key('preview_loading_indicator'),
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 18),
            Text(
              'Retrieving medical certificate for ${widget.leave.employeeName}...',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Authenticating with HR security credentials...',
              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: SingleChildScrollView(
          child: Container(
            key: const Key('preview_error_banner'),
            padding: const EdgeInsets.all(28),
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 44,
                    color: Colors.red.shade600,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Unable to Retrieve Medical Certificate',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      key: const Key('preview_retry_button'),
                      onPressed: _loadMedicalDocument,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_documentBytes == null || _documentBytes!.isEmpty) {
      return const Center(
        child: Text(
          'No document content retrieved.',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
      );
    }

    // 1. PDF Viewer: Renders every page with zoom and scrolling
    if (_isPdf || (_contentType?.contains('pdf') ?? false)) {
      return Container(
        key: const Key('medical_pdf_viewer_container'),
        color: const Color(0xFF525659),
        child: PdfViewWidget(
          blobUrl: _blobUrl ?? '',
          title: _fileName,
        ),
      );
    }

    // 2. Direct Image Viewer with smooth zoom and pan
    if (_isImage || (_contentType?.startsWith('image/') ?? false)) {
      return Container(
        key: const Key('medical_image_viewer_container'),
        color: const Color(0xFF0F172A),
        child: Center(
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.memory(
              _documentBytes!,
              fit: BoxFit.contain,
              errorBuilder: (ctx, err, stack) => _buildUnsupported(
                'Image rendering failed. The image format may be damaged.',
              ),
            ),
          ),
        ),
      );
    }

    // 3. Other unsupported document types
    return _buildUnsupported(
      'Preview is not available for this file type (${_fileName.contains('.') ? _fileName.split('.').last.toUpperCase() : 'document'}). Please download the document to inspect it.',
    );
  }

  Widget _buildUnsupported(String message) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.insert_drive_file_outlined,
                  size: 42,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF334155),
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _isDownloading ? null : _handleDownload,
                icon: _isDownloading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.download_rounded, size: 16),
                label: const Text('Download Document'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
