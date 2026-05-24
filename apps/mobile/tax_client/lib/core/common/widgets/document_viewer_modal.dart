import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';

/// Full-screen viewer modal for documents (images + PDFs).
///
/// Usage:
/// ```dart
/// DocumentViewerModal.show(
///   context,
///   url: imageOrPdfUrl,
///   fileName: document.fileName ?? '',
///   isPdf: document.fileType.toLowerCase() == 'pdf',
/// );
/// ```
class DocumentViewerModal extends StatelessWidget {
  final String url;
  final String fileName;
  final bool isPdf;

  const DocumentViewerModal({
    super.key,
    required this.url,
    required this.fileName,
    required this.isPdf,
  });

  /// Convenience method — shows the modal as a full-screen bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required String url,
    required String fileName,
    required bool isPdf,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DocumentViewerModal(
        url: url,
        fileName: fileName,
        isPdf: isPdf,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: true,
      top: false,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.93,
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // ── Header bar ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // ── Content ─────────────────────────────────────────────
            Expanded(
              child: isPdf
                  ? _PdfViewerContent(url: url)
                  : _ImageViewerContent(url: url),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Image viewer with pinch-to-zoom ──────────────────────────────────────────
class _ImageViewerContent extends StatelessWidget {
  final String url;
  const _ImageViewerContent({required this.url});

  @override
  Widget build(BuildContext context) {
    final bool isLocal = !url.startsWith('http');
    return ClipRRect(
      child: PhotoView(
        imageProvider: isLocal ? FileImage(File(url)) : NetworkImage(url) as ImageProvider,
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 4,
        initialScale: PhotoViewComputedScale.contained,
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        loadingBuilder: (context, event) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48),
              SizedBox(height: 12),
              Text('Could not load image',
                  style: TextStyle(color: Colors.white54)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── PDF viewer ───────────────────────────────────────────────────────────────
class _PdfViewerContent extends StatefulWidget {
  final String url;
  const _PdfViewerContent({required this.url});

  @override
  State<_PdfViewerContent> createState() => _PdfViewerContentState();
}

class _PdfViewerContentState extends State<_PdfViewerContent> {
  String? _localPath;
  bool _isLoading = true;
  String? _error;
  int _totalPages = 0;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _downloadAndLoad();
  }

  Future<void> _downloadAndLoad() async {
    try {
      if (!widget.url.startsWith('http')) {
        if (mounted) {
          setState(() {
            _localPath = widget.url;
            _isLoading = false;
          });
        }
        return;
      }
      final response = await http.get(Uri.parse(widget.url));
      if (response.statusCode != 200) {
        throw Exception('Server returned ${response.statusCode}');
      }
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/doc_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(response.bodyBytes);
      if (mounted) {
        setState(() {
          _localPath = file.path;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not load PDF: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text('Loading PDF…', style: TextStyle(color: Colors.white54)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.picture_as_pdf_outlined,
                color: Colors.white54, size: 48),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54)),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        PDFView(
          filePath: _localPath!,
          enableSwipe: true,
          swipeHorizontal: false,
          autoSpacing: true,
          pageFling: true,
          pageSnap: true,
          fitPolicy: FitPolicy.BOTH,
          onRender: (pages) => setState(() => _totalPages = pages ?? 0),
          onPageChanged: (page, _) => setState(() => _currentPage = (page ?? 0) + 1),
          onError: (error) => setState(() => _error = error.toString()),
        ),
        // Page indicator
        if (_totalPages > 0)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_currentPage / $_totalPages',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
