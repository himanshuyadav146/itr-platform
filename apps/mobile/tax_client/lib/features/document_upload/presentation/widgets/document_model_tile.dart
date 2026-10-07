import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tax_client/core/common/widgets/custom_card.dart';
import 'package:tax_client/core/common/widgets/document_viewer_modal.dart';
import 'package:tax_client/core/config/strings/app_strings.dart';
import 'package:tax_client/core/config/theme/app_colors.dart';
import 'package:tax_client/core/config/theme/app_spacing.dart';
import 'package:tax_client/core/network/token_storage.dart';
import 'package:tax_client/core/utils/document_url_helper.dart';

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

  bool _isForm16Document(String? documentName) {
    if (documentName == null || documentName.isEmpty) return false;
    final name = documentName.toLowerCase();
    return name.contains('form 16') || name.contains('form16');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final fileName = document.fileName ?? 'Unknown';
    final isPdf = document.fileType.toLowerCase() == 'pdf' || _isPdf(fileName);
    final isImage =
        ['jpg', 'jpeg', 'png'].contains(document.fileType.toLowerCase()) ||
        _isImage(fileName);

    return FutureBuilder<String?>(
      future: ref.read(tokenStorageProvider).getPanNumber(),
      builder: (context, snapshot) {
        final pan = snapshot.data;
        final viewUrl =
            (pan != null && pan.isNotEmpty && document.fileName != null)
            ? DocumentUrlHelper.getDocumentUrl(
                panNumber: pan,
                fileName: document.fileName!,
              )
            : null;

        return CustomCard(
          padding: EdgeInsets.zero,
          backgroundColor: AppColors.surfaceVariantDark.withValues(alpha: 0.18),
          border: Border.all(color: AppColors.borderOnDark),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
              onTap: viewUrl == null
                  ? null
                  : () {
                      DocumentViewerModal.show(
                        context,
                        url: viewUrl,
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
                      child: _buildThumbnailIcon(isImage, isPdf, viewUrl),
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
                            document.documentName ?? 'Uploaded document',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.authMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_isForm16Document(document.documentName)) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              (document.filePassword != null &&
                                      document.filePassword!.isNotEmpty)
                                  ? AppStrings.form16PasswordAdded
                                  : AppStrings.form16PasswordNotProvided,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: (document.filePassword != null &&
                                        document.filePassword!.isNotEmpty)
                                    ? AppColors.authMint
                                    : AppColors.authMuted,
                                fontWeight: (document.filePassword != null &&
                                        document.filePassword!.isNotEmpty)
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    IconButton(
                      onPressed: onDelete,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.error.withValues(
                          alpha: 0.12,
                        ),
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
      },
    );
  }

  Widget _buildThumbnailIcon(bool isImage, bool isPdf, String? viewUrl) {
    if (isImage && viewUrl != null) {
      return Image.network(
        viewUrl,
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fileIcon(isPdf),
      );
    }
    return _fileIcon(isPdf);
  }

  Widget _fileIcon(bool isPdf) {
    return Container(
      width: 52,
      height: 52,
      color: AppColors.surfaceDark,
      child: Icon(
        isPdf ? Icons.picture_as_pdf_rounded : Icons.insert_drive_file_rounded,
        color: isPdf ? AppColors.authAmber : AppColors.authHeading,
        size: 28,
      ),
    );
  }
}
