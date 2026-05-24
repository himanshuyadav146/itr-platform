import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tax_client/core/network/token_storage.dart';
import 'package:tax_client/core/utils/document_url_helper.dart';
import 'package:tax_client/core/common/widgets/document_viewer_modal.dart';

import '../../data/models/document_model.dart';

class DocumentModelTile extends ConsumerWidget {
  final DocumentModel document;
  final VoidCallback onDelete;

  const DocumentModelTile({
    super.key,
    required this.document,
    required this.onDelete,
  });

  bool _isPdf(String path) {
    final lowerPath = path.toLowerCase();
    return lowerPath.endsWith('.pdf') || lowerPath.contains('.pdf?') || lowerPath.contains('/pdf');
  }

  bool _isImage(String path) {
    final lowerPath = path.toLowerCase();
    return lowerPath.endsWith('.jpg') || 
           lowerPath.endsWith('.jpeg') || 
           lowerPath.endsWith('.png') ||
           lowerPath.contains('.jpg?') ||
           lowerPath.contains('.jpeg?') ||
           lowerPath.contains('.png?');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileName = document.fileName ?? '';
    final isPdf = document.fileType.toLowerCase() == 'pdf' || _isPdf(fileName);
    final isImage = ['jpg', 'jpeg', 'png'].contains(document.fileType.toLowerCase()) || _isImage(fileName);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        // ── Thumbnail (tappable) ────────────────────────────────
        leading: FutureBuilder<String?>(
          future: ref.read(tokenStorageProvider).getPanNumber(),
          builder: (context, snapshot) {
            final pan = snapshot.data;
            final fileName = document.fileName;

            // Build the view URL if we have both PAN and fileName
            final viewUrl = (pan != null && pan.isNotEmpty && fileName != null)
                ? DocumentUrlHelper.getDocumentUrl(
                    panNumber: pan,
                    fileName: fileName,
                  )
                : null;

            Widget thumbnail = _buildThumbnailIcon(isImage, isPdf, viewUrl);

            // Make thumbnail tappable to open full viewer
            if (viewUrl != null) {
              thumbnail = GestureDetector(
                onTap: () => DocumentViewerModal.show(
                  context,
                  url: viewUrl,
                  fileName: document.fileName ?? 'Document',
                  isPdf: isPdf,
                ),
                child: thumbnail,
              );
            }

            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: thumbnail,
            );
          },
        ),
        title: Text(
          document.fileName ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          document.documentName ?? '',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        // ── Tap whole tile to open viewer too ──────────────────
        onTap: () async {
          final pan = await ref.read(tokenStorageProvider).getPanNumber();
          if (pan == null || pan.isEmpty || document.fileName == null) return;
          final viewUrl = DocumentUrlHelper.getDocumentUrl(
            panNumber: pan,
            fileName: document.fileName!,
          );
          if (context.mounted) {
            DocumentViewerModal.show(
              context,
              url: viewUrl,
              fileName: document.fileName ?? 'Document',
              isPdf: isPdf,
            );
          }
        },
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: onDelete,
        ),
      ),
    );
  }

  Widget _buildThumbnailIcon(bool isImage, bool isPdf, String? viewUrl) {
    if (isImage && viewUrl != null) {
      return Image.network(
        viewUrl,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fileIcon(isPdf),
      );
    }
    return _fileIcon(isPdf);
  }

  Widget _fileIcon(bool isPdf) {
    return Container(
      width: 50,
      height: 50,
      color: Colors.grey[200],
      child: isPdf
          ? const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 28)
          : const Icon(Icons.insert_drive_file, size: 28),
    );
  }
}
