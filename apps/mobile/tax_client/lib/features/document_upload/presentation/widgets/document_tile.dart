import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tax_client/core/common/widgets/document_viewer_modal.dart';

class DocumentTile extends StatelessWidget {
  final File file;
  final VoidCallback onDelete;

  const DocumentTile({Key? key, required this.file, required this.onDelete})
    : super(key: key);

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
  Widget build(BuildContext context) {
    final isPdf = _isPdf(file.path);
    final isImage = _isImage(file.path);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () {
          DocumentViewerModal.show(
            context,
            url: file.path,
            fileName: file.path.split('/').last,
            isPdf: isPdf,
          );
        },
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: isImage
              ? Image.file(file, width: 50, height: 50, fit: BoxFit.cover)
              : Container(
                  width: 50,
                  height: 50,
                  color: Colors.grey[200],
                  child: isPdf 
                    ? const Icon(Icons.picture_as_pdf, size: 28, color: Colors.redAccent)
                    : const Icon(Icons.insert_drive_file, size: 28),
                ),
        ),
        title: Text(
          file.path.split('/').last,
          style: const TextStyle(fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
