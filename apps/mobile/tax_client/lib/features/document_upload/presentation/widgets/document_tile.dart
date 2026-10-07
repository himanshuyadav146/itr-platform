import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tax_client/core/common/widgets/custom_card.dart';
import 'package:tax_client/core/common/widgets/document_viewer_modal.dart';
import 'package:tax_client/core/config/strings/app_strings.dart';
import 'package:tax_client/core/config/theme/app_colors.dart';
import 'package:tax_client/core/config/theme/app_spacing.dart';

class DocumentTile extends StatelessWidget {
  final File file;
  final VoidCallback onDelete;
  final String? pdfPassword;

  const DocumentTile({
    super.key,
    required this.file,
    required this.onDelete,
    this.pdfPassword,
  });

  bool _isPdf(String path) {
    final lowerPath = path.toLowerCase();
    return lowerPath.endsWith('.pdf') ||
        lowerPath.contains('.pdf?') ||
        lowerPath.contains('/pdf');
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
    final theme = Theme.of(context);
    final fileName = file.path.split('/').last;
    final isPdf = _isPdf(file.path);
    final isImage = _isImage(file.path);

    return CustomCard(
      padding: EdgeInsets.zero,
      backgroundColor: AppColors.surfaceVariantDark.withValues(alpha: 0.18),
      border: Border.all(color: AppColors.borderOnDark),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          onTap: () {
            DocumentViewerModal.show(
              context,
              url: file.path,
              fileName: fileName,
              isPdf: isPdf,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: isImage
                      ? Image.file(
                          file,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 52,
                          height: 52,
                          color: AppColors.surfaceDark,
                          child: Icon(
                            isPdf
                                ? Icons.picture_as_pdf_rounded
                                : Icons.insert_drive_file_rounded,
                            size: 28,
                            color: isPdf
                                ? AppColors.authAmber
                                : AppColors.authHeading,
                          ),
                        ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.authHeading,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        (pdfPassword != null && pdfPassword!.isNotEmpty)
                            ? AppStrings.form16PasswordAdded
                            : 'Ready to submit',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: (pdfPassword != null && pdfPassword!.isNotEmpty)
                              ? AppColors.authMint
                              : AppColors.authMuted,
                          fontWeight: (pdfPassword != null &&
                                  pdfPassword!.isNotEmpty)
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton(
                  onPressed: onDelete,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.error.withValues(alpha: 0.12),
                    foregroundColor: AppColors.error,
                  ),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
