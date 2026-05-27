import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tax_client/core/common/widgets/core_scaffold.dart';
import 'package:tax_client/core/common/widgets/custom_card.dart';
import 'package:tax_client/core/common/widgets/primary_button.dart';
import 'package:tax_client/core/config/strings/app_strings.dart';
import 'package:tax_client/core/config/theme/app_colors.dart';
import 'package:tax_client/core/config/theme/app_spacing.dart';
import 'package:tax_client/core/utils/error_handler.dart';
import 'package:tax_client/features/document_upload/data/models/document_model.dart';
import 'package:tax_client/features/document_upload/presentation/providers/document_upload_provider.dart';
import 'package:tax_client/features/document_upload/presentation/providers/document_upload_state.dart';
import 'package:tax_client/features/document_upload/presentation/widgets/document_model_tile.dart';
import 'package:tax_client/features/document_upload/presentation/widgets/document_tile.dart';
import 'package:tax_client/features/document_upload/providers/documents_provider.dart';
import 'package:tax_client/features/packages/presentation/providers/package_provider.dart';
import 'package:tax_client/features/personal_info/presentation/providers/personal_info_provider.dart';

class UploadDocumentsScreen extends ConsumerStatefulWidget {
  const UploadDocumentsScreen({super.key});

  @override
  ConsumerState<UploadDocumentsScreen> createState() =>
      _UploadDocumentsScreenState();
}

class _UploadDocumentsScreenState extends ConsumerState<UploadDocumentsScreen> {
  List<DocumentModel> _fetchedDocuments = [];

  static const Map<String, String> _categorySubtitles = {
    'form16a':
        'Upload salary, interest, or TDS-related statements for the filing.',
    'form16b':
        'Attach property sale or transaction certificates if they apply.',
    'others':
        'Add bank statements, proofs, deductions, or any supporting files.',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(documentUploadViewModelProvider.notifier).fetchDocuments();
    });
  }

  String _getCategoryKey(String? documentName) {
    if (documentName == null || documentName.isEmpty) {
      return 'others';
    }
    final name = documentName.toLowerCase();
    if (name.contains('form 16-a') || name.contains('form16a')) {
      return 'form16a';
    }
    if (name.contains('form 16-b') || name.contains('form16b')) {
      return 'form16b';
    }
    return 'others';
  }

  List<DocumentModel> _getDocumentsForCategory(String categoryKey) {
    return _fetchedDocuments
        .where((doc) => _getCategoryKey(doc.documentName) == categoryKey)
        .toList();
  }

  Future<void> _pickAndUpload(String categoryKey) async {
    final notifier = ref.read(documentsProvider.notifier);
    final beforeCount = ref.read(documentsProvider)[categoryKey]!.files.length;
    await notifier.pickDocument(categoryKey);
    final files = ref.read(documentsProvider)[categoryKey]!.files;
    if (files.length <= beforeCount) {
      return;
    }

    final file = files.last;
    ref
        .read(documentUploadViewModelProvider.notifier)
        .uploadDocument(
          documentCategory: categoryKey,
          fileName: categoryKey,
          file: file,
        );
  }

  int _totalDocumentCount(Map<String, DocumentCategory> documents) {
    final localCount = documents.values.fold<int>(
      0,
      (sum, category) => sum + category.files.length,
    );
    return localCount + _fetchedDocuments.length;
  }

  void _handleSubmit(bool isAnyLoading) {
    if (isAnyLoading) {
      return;
    }

    var hasDocuments = _fetchedDocuments.isNotEmpty;
    if (!hasDocuments) {
      hasDocuments = ref
          .read(documentUploadViewModelProvider.notifier)
          .hasUploadedDocuments();
    }

    if (!hasDocuments) {
      ErrorHandler.showError(
        context,
        'Please upload at least one document to proceed.',
      );
      return;
    }

    final journeyType = ref.read(journeyTypeProvider);
    ref
        .read(documentUploadViewModelProvider.notifier)
        .saveAllDocuments(
          existingDocuments: _fetchedDocuments,
          journeyType: journeyType.apiValue,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final documents = ref.watch(documentsProvider);
    final notifier = ref.read(documentsProvider.notifier);
    final uploadState = ref.watch(documentUploadViewModelProvider);
    final selectedPackage = ref.watch(selectedPackageProvider);

    final isLoading = uploadState is DocumentsLoading;
    final isSaving = uploadState is DocumentsSaving;
    final isUploading = uploadState is DocumentUploading;
    final isDeleting = uploadState is DocumentDeleting;
    final isBusy = isSaving || isUploading || isDeleting;
    final totalDocuments = _totalDocumentCount(documents);

    ref.listen<DocumentUploadState>(documentUploadViewModelProvider, (
      previous,
      next,
    ) {
      if (next is DocumentsLoaded) {
        setState(() {
          _fetchedDocuments = next.documents;
        });
      } else if (next is DocumentUploadSuccess) {
        ErrorHandler.showSuccess(
          context,
          '${next.fileName} ${AppStrings.uploadedSuccessfully}',
        );
      } else if (next is DocumentDeleted) {
        ErrorHandler.showSuccess(context, next.message);
        setState(() {
          _fetchedDocuments.removeWhere((doc) => doc.docId == next.docId);
        });
      } else if (next is DocumentsSaveSuccess) {
        ErrorHandler.showSuccess(context, next.message);
        if (context.mounted) {
          final packageId = ref.read(selectedPackageProvider)?.id ?? '1';
          context.push('/payment?packageId=$packageId');
        }
      } else if (next is DocumentUploadError) {
        ErrorHandler.showError(context, next.message);
      }
    });

    if (isLoading) {
      return CoreScaffold(
        includeAppBar: false,
        backgroundColor: AppColors.authBackground,
        centered: true,
        useResponsiveMaxWidth: true,
        maxContentWidth: 560,
        useScrollView: false,
        padding: const EdgeInsets.all(AppSpacing.lg),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.authMint),
        ),
      );
    }

    return CoreScaffold(
      includeAppBar: false,
      backgroundColor: AppColors.authBackground,
      useScrollView: false,
      centered: true,
      useResponsiveMaxWidth: true,
      maxContentWidth: 560,
      padding: EdgeInsets.zero,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: SizedBox(
          height: 56,
          child: PrimaryButton(
            text: 'SUBMIT ALL DOCUMENTS',
            isLoading: isSaving,
            onPressed: isBusy ? null : () => _handleSubmit(isBusy),
            borderRadius: AppSpacing.radiusPill,
            foregroundColor: AppColors.authButtonText,
            textStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [AppColors.authMint, AppColors.authMintDark],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x334EDEA3),
                blurRadius: 20,
                spreadRadius: -6,
                offset: Offset(0, 10),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DocumentUploadHeader(
                        onBack: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/');
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _DocumentUploadHeroCard(
                        packageName:
                            selectedPackage?.name ??
                            'Package will be used for payment',
                        totalDocuments: totalDocuments,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                sliver: SliverList.separated(
                  itemCount: documents.keys.length,
                  itemBuilder: (context, index) {
                    final categoryKey = documents.keys.elementAt(index);
                    final category = documents[categoryKey]!;
                    final serverDocuments = _getDocumentsForCategory(
                      categoryKey,
                    );

                    return _DocumentCategoryCard(
                      title: category.title,
                      subtitle:
                          _categorySubtitles[categoryKey] ??
                          'Attach the files required for this step.',
                      serverCount: serverDocuments.length,
                      localCount: category.files.length,
                      isUploading: isUploading,
                      onUpload: () => _pickAndUpload(categoryKey),
                      child: (category.files.isEmpty && serverDocuments.isEmpty)
                          ? const _DocumentEmptyState()
                          : Column(
                              children: [
                                ...serverDocuments.map(
                                  (doc) => Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AppSpacing.sm,
                                    ),
                                    child: DocumentModelTile(
                                      document: doc,
                                      onDelete: () {
                                        if (doc.docId != null &&
                                            doc.fileName != null) {
                                          ref
                                              .read(
                                                documentUploadViewModelProvider
                                                    .notifier,
                                              )
                                              .deleteDocument(
                                                docId: doc.docId!,
                                                fileName: doc.fileName!,
                                              );
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                ...category.files.map(
                                  (file) => Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AppSpacing.sm,
                                    ),
                                    child: DocumentTile(
                                      file: file,
                                      onDelete: () => notifier.removeDocument(
                                        categoryKey,
                                        file,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    );
                  },
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.lg),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
            ],
          ),
          if (isBusy)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.32),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        color: AppColors.authMint,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        isSaving
                            ? 'Saving your documents...'
                            : isUploading
                            ? 'Uploading document...'
                            : 'Updating document list...',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.authHeading,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DocumentUploadHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _DocumentUploadHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surfaceVariantDark,
            foregroundColor: AppColors.authHeading,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.uploadDocuments,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.authHeading,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Attach the documents needed before moving to payment.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.authMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DocumentUploadHeroCard extends StatelessWidget {
  final String packageName;
  final int totalDocuments;

  const _DocumentUploadHeroCard({
    required this.packageName,
    required this.totalDocuments,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomCard(
      backgroundColor: AppColors.authCardSurface,
      border: Border.all(color: AppColors.authCardBorder),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.attachTaxDocuments,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppColors.authHeading,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppStrings.uploadSubtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.authMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _DocumentInfoChip(
                icon: Icons.inventory_2_outlined,
                label: packageName,
                accent: AppColors.authMint,
              ),
              _DocumentInfoChip(
                icon: Icons.folder_copy_outlined,
                label:
                    '$totalDocuments document${totalDocuments == 1 ? '' : 's'} attached',
                accent: AppColors.authAmber,
              ),
              const _DocumentInfoChip(
                icon: Icons.verified_user_outlined,
                label: 'PDF, JPG, PNG supported',
                accent: AppColors.authHeading,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DocumentCategoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int serverCount;
  final int localCount;
  final bool isUploading;
  final VoidCallback onUpload;
  final Widget child;

  const _DocumentCategoryCard({
    required this.title,
    required this.subtitle,
    required this.serverCount,
    required this.localCount,
    required this.isUploading,
    required this.onUpload,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomCard(
      backgroundColor: const Color(0x08FFFFFF),
      border: Border.all(color: AppColors.borderOnDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: AppColors.authHeading,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.authMuted,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              TextButton.icon(
                onPressed: isUploading ? null : onUpload,
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.surfaceVariantDark,
                  foregroundColor: AppColors.authHeading,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                ),
                icon: const Icon(Icons.upload_file_rounded, size: 18),
                label: const Text(
                  AppStrings.upload,
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _DocumentCountChip(
                icon: Icons.cloud_done_outlined,
                label: '$serverCount saved',
              ),
              _DocumentCountChip(
                icon: Icons.schedule_outlined,
                label: '$localCount local',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

class _DocumentEmptyState extends StatelessWidget {
  const _DocumentEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantDark.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.file_open_outlined,
            color: AppColors.authMuted,
            size: 30,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppStrings.noFiles,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.authMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;

  const _DocumentInfoChip({
    required this.icon,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.authHeading,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentCountChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DocumentCountChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantDark.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.authMuted),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.authMuted,
            ),
          ),
        ],
      ),
    );
  }
}
