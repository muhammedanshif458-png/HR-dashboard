import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/hr_document.dart';
import '../providers/hr_provider.dart';
import '../utils/file_download_helper.dart';
import '../services/api_service.dart';
import 'pdf_view/pdf_view_widget.dart';

class DocumentPreviewModal extends StatefulWidget {
  final HRDocumentItem doc;
  final String employeeId;
  final HRProvider? provider;

  const DocumentPreviewModal({
    super.key,
    required this.doc,
    required this.employeeId,
    this.provider,
  });

  static Future<void> show(
    BuildContext context, {
    required HRDocumentItem doc,
    required String employeeId,
    HRProvider? provider,
  }) {
    final hrProvider =
        provider ?? Provider.of<HRProvider>(context, listen: false);
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => DocumentPreviewModal(
        doc: doc,
        employeeId: employeeId,
        provider: hrProvider,
      ),
    );
  }

  @override
  State<DocumentPreviewModal> createState() => _DocumentPreviewModalState();
}

class _DocumentPreviewModalState extends State<DocumentPreviewModal> {
  bool _isLoading = true;
  bool _isDownloading = false;
  String? _errorMessage;
  Uint8List? _documentBytes;
  String? _contentType;
  String? _blobUrl;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  @override
  void dispose() {
    if (_blobUrl != null && _blobUrl!.isNotEmpty) {
      FileDownloadHelper.revokeBlobUrl(_blobUrl!);
    }
    super.dispose();
  }

  Future<void> _loadDocument() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final hrProvider =
        widget.provider ?? Provider.of<HRProvider>(context, listen: false);

    try {
      final downloaded =
          await hrProvider.downloadEmployeeDocument(widget.doc.id);
      if (!mounted) return;

      if (downloaded == null) {
        final err = hrProvider.employeeDocumentsError ??
            'Could not load document from server. Please check permissions or file availability.';
        setState(() {
          _errorMessage = err;
          _isLoading = false;
        });
        return;
      }

      final bytes = Uint8List.fromList(downloaded.bytes);
      if (bytes.isEmpty) {
        setState(() {
          _errorMessage = 'The retrieved document file is empty.';
          _isLoading = false;
        });
        return;
      }

      // Check if response is an error JSON payload disguised as 200
      if (_isJsonErrorPayload(bytes)) {
        setState(() {
          _errorMessage = 'Server returned an error message instead of the file.';
          _isLoading = false;
        });
        return;
      }

      // Verify PDF signature if file is supposed to be a PDF
      if (widget.doc.isPdf && !ApiService.isPdfSignature(bytes)) {
        setState(() {
          _errorMessage =
              'Invalid PDF file: document header does not contain the standard "%PDF-" signature.';
          _isLoading = false;
        });
        return;
      }

      final cType = downloaded.contentType.isNotEmpty
          ? downloaded.contentType
          : (widget.doc.isPdf
              ? 'application/pdf'
              : (widget.doc.isImage
                  ? 'image/png'
                  : 'application/octet-stream'));

      // If PDF, create blob URL for web iframe and browser tab opening
      String? blobUrl;
      try {
        blobUrl =
            FileDownloadHelper.createBlobUrl(bytes: bytes, mimeType: cType);
      } catch (_) {}

      setState(() {
        _documentBytes = bytes;
        _contentType = cType;
        _blobUrl = blobUrl;
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

  bool _isJsonErrorPayload(Uint8List bytes) {
    if (bytes.length < 500) {
      final text = String.fromCharCodes(bytes.take(200)).trimLeft();
      if (text.startsWith('{"success":false') ||
          text.startsWith('{"error"') ||
          text.startsWith('{"statusCode":4') ||
          text.startsWith('{"statusCode":5')) {
        return true;
      }
    }
    return false;
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
      final fileName = widget.doc.originalName.isNotEmpty
          ? widget.doc.originalName
          : widget.doc.fileName;

      final success = await FileDownloadHelper.downloadFile(
        bytes: _documentBytes!,
        fileName: fileName,
        mimeType: _contentType ?? 'application/octet-stream',
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloaded "$fileName" successfully.'),
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

    final fileName = widget.doc.originalName.isNotEmpty
        ? widget.doc.originalName
        : widget.doc.fileName;

    final success = await FileDownloadHelper.openInBrowserTab(
      bytes: _documentBytes!,
      mimeType:
          _contentType ?? (widget.doc.isPdf ? 'application/pdf' : 'image/png'),
      fileName: fileName,
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
    final dialogWidth = (screenSize.width * 0.92).clamp(360.0, 1300.0);
    final dialogHeight = (screenSize.height * 0.90).clamp(480.0, 950.0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          children: [
            // Clean, uncluttered header with Back to Staff Profile and direct actions
            _buildHeader(context),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

            // Dedicated document viewing body
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isPdf = widget.doc.isPdf;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          // 1. Back action to return to Staff Profile
          TextButton.icon(
            key: const Key('preview_back_button'),
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Back to Staff Profile'),
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

          // 2. Document Title (Clean, no metadata badges or category clutter)
          Expanded(
            child: Text(
              widget.doc.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),

          // 3. Actions: Open in new tab (for PDF) and Close button
          if (isPdf && _documentBytes != null)
            IconButton(
              key: const Key('preview_open_tab_button'),
              icon: const Icon(Icons.open_in_new_rounded, size: 20),
              tooltip: 'Open in Browser Tab',
              color: const Color(0xFF2563EB),
              onPressed: _handleOpenInBrowserTab,
            ),
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

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading "${widget.doc.title}"...',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 38,
                  color: Colors.red.shade600,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Unable to Preview Document',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _loadDocument,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Retry'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Back to Staff Profile'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (_documentBytes == null || _documentBytes!.isEmpty) {
      return const Center(
        child: Text(
          'No document content available.',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
      );
    }

    // 1. Direct PDF preview: Displays PDF directly without placeholder cards or duplicate buttons
    if (widget.doc.isPdf || (_contentType?.contains('pdf') ?? false)) {
      return PdfViewWidget(
        blobUrl: _blobUrl ?? '',
        title: widget.doc.title,
      );
    }

    // 2. Direct Image preview
    if (widget.doc.isImage || (_contentType?.startsWith('image/') ?? false)) {
      return Container(
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

    // 3. Unsupported file type: Minimal message and single download option
    return _buildUnsupported(
      'Preview is not available for this file type (${widget.doc.originalName.contains('.') ? widget.doc.originalName.split('.').last.toUpperCase() : 'document'}). Please download the document to view it.',
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
