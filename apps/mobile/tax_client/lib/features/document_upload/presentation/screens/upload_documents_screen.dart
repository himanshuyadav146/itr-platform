import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/common/widgets/core_scaffold.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/common/widgets/primary_button.dart';
import '../../../../core/common/widgets/custom_card.dart';
import '../../../../core/utils/error_handler.dart';
import '../../providers/documents_provider.dart';
import '../../presentation/providers/document_upload_provider.dart';
import '../../presentation/providers/document_upload_state.dart';
import '../widgets/document_tile.dart';
import '../widgets/document_model_tile.dart';
import 'package:tax_client/features/personal_info/presentation/providers/personal_info_provider.dart';
import 'package:tax_client/core/common/enums/journey_type.dart';
import 'package:tax_client/core/config/strings/app_strings.dart';
import 'package:tax_client/features/document_upload/data/models/document_model.dart';
import 'package:tax_client/features/packages/presentation/providers/package_provider.dart';

class UploadDocumentsScreen extends ConsumerStatefulWidget {
  const UploadDocumentsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<UploadDocumentsScreen> createState() => _UploadDocumentsScreenState();
}

class _UploadDocumentsScreenState extends ConsumerState<UploadDocumentsScreen> {
  // Store fetched documents from server
  List<DocumentModel> _fetchedDocuments = [];

  @override
  void initState() {
    super.initState();
    // Fetch documents when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(documentUploadViewModelProvider.notifier).fetchDocuments();
    });
  }

  // Helper method to map document name to category key
  String _getCategoryKey(String? documentName) {
    if (documentName == null || documentName.isEmpty) {
      return 'others';
    }
    final name = documentName.toLowerCase();
    if (name.contains('form 16-a') || name.contains('form16a')) {
      return 'form16a';
    } else if (name.contains('form 16-b') || name.contains('form16b')) {
      return 'form16b';
    } else {
      return 'others';
    }
  }

  // Get documents for a specific category
  List<DocumentModel> _getDocumentsForCategory(String categoryKey) {
    return _fetchedDocuments
        .where((doc) => _getCategoryKey(doc.documentName) == categoryKey)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final documents = ref.watch(documentsProvider);
    final notifier = ref.read(documentsProvider.notifier);
    final uploadState = ref.watch(documentUploadViewModelProvider);
    
    // Check for different loading states
    final isLoading = uploadState is DocumentsLoading;
    final isSaving = uploadState is DocumentsSaving;
    final isUploading = uploadState is DocumentUploading;
    final isDeleting = uploadState is DocumentDeleting;
    final isAnyLoading = isLoading || isSaving || isUploading || isDeleting;

    // Listen to upload state changes
    ref.listen<DocumentUploadState>(
      documentUploadViewModelProvider,
      (previous, next) {
        if (next is DocumentsLoaded) {
          // Store fetched documents
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
          // Remove from fetched documents
          setState(() {
            _fetchedDocuments.removeWhere((doc) => doc.docId == next.docId);
          });
        } else if (next is DocumentsSaveSuccess) {
          ErrorHandler.showSuccess(context, next.message);
          // Only navigate after successful API response
          if (context.mounted) {
            final selectedPackage = ref.read(selectedPackageProvider);
            final packageId = selectedPackage?.id ?? '1';
            context.push('/payment?packageId=$packageId');
          }
        } else if (next is DocumentUploadError) {
          ErrorHandler.showError(context, next.message);
        }
      },
    );

    final scheme = Theme.of(context).colorScheme;
    
    // Show loader when fetching documents
    if (isLoading) {
      return CoreScaffold(
        title: AppStrings.uploadDocuments,
        centerTitle: true,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return CoreScaffold(
      title: AppStrings.uploadDocuments,
      centerTitle: true,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: PrimaryButton(
          text: AppStrings.submitAllDocuments,
          isLoading: isSaving,
          onPressed: isAnyLoading
              ? () {}
              : () {
                  // VALIDATION: Check if at least one document exists
                  bool hasDocuments = false;
                  // Check server documents
                  if (_fetchedDocuments.isNotEmpty) {
                    hasDocuments = true;
                  }
                  // Check locally uploaded documents (in viewmodel)
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
                },
        ),
      ),
      backgroundColor: null,
      useScrollView: false,
      centered: false,
      padding: const EdgeInsets.all(20),
      body: Stack(
        fit: StackFit.expand,
        children: [
          SingleChildScrollView(
            child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                AppStrings.attachTaxDocuments,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.uploadSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 25),

          // SECTION 1: Form 16-A
          _buildCategorySection(
            context,
            categoryKey: 'form16a',
            title: documents['form16a']!.title,
            files: documents['form16a']!.files,
            serverDocuments: _getDocumentsForCategory('form16a'),
            isUploading: isUploading,
            onUpload: () async {
              await notifier.pickDocument('form16a');
              final files = ref.read(documentsProvider)['form16a']!.files;
              if (files.isNotEmpty) {
                final file = files.last;
                ref.read(documentUploadViewModelProvider.notifier).uploadDocument(
                      documentCategory: 'form16a',
                      fileName: 'form16a',
                      file: file,
                    );
              }
            },
            onDeleteFile: (file) => notifier.removeDocument('form16a', file),
            onDeleteDocument: (doc) {
              if (doc.docId != null && doc.fileName != null) {
                ref.read(documentUploadViewModelProvider.notifier).deleteDocument(
                      docId: doc.docId!,
                      fileName: doc.fileName!,
                    );
              }
            },
          ),

          const SizedBox(height: 25),

          // SECTION 2: Form 16-B
          _buildCategorySection(
            context,
            categoryKey: 'form16b',
            title: documents['form16b']!.title,
            files: documents['form16b']!.files,
            serverDocuments: _getDocumentsForCategory('form16b'),
            isUploading: isUploading,
            onUpload: () async {
              await notifier.pickDocument('form16b');
              final files = ref.read(documentsProvider)['form16b']!.files;
              if (files.isNotEmpty) {
                final file = files.last;
                ref.read(documentUploadViewModelProvider.notifier).uploadDocument(
                      documentCategory: 'form16b',
                      fileName: 'form16b',
                      file: file,
                    );
              }
            },
            onDeleteFile: (file) => notifier.removeDocument('form16b', file),
            onDeleteDocument: (doc) {
              if (doc.docId != null && doc.fileName != null) {
                ref.read(documentUploadViewModelProvider.notifier).deleteDocument(
                      docId: doc.docId!,
                      fileName: doc.fileName!,
                    );
              }
            },
          ),

          const SizedBox(height: 25),

          // SECTION 3: Other Documents
          _buildCategorySection(
            context,
            categoryKey: 'others',
            title: documents['others']!.title,
            files: documents['others']!.files,
            serverDocuments: _getDocumentsForCategory('others'),
            isUploading: isUploading,
            onUpload: () async {
              await notifier.pickDocument('others');
              final files = ref.read(documentsProvider)['others']!.files;
              if (files.isNotEmpty) {
                final file = files.last;
                ref.read(documentUploadViewModelProvider.notifier).uploadDocument(
                      documentCategory: 'others',
                      fileName: 'others',
                      file: file,
                    );
              }
            },
            onDeleteFile: (file) => notifier.removeDocument('others', file),
            onDeleteDocument: (doc) {
              if (doc.docId != null && doc.fileName != null) {
                ref.read(documentUploadViewModelProvider.notifier).deleteDocument(
                      docId: doc.docId!,
                      fileName: doc.fileName!,
                    );
              }
            },
          ),
            ],
          ),
          ),
          // Show loading overlay during API operations (except initial load)
          if (isUploading || isSaving || isDeleting)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(
    BuildContext context, {
    required String categoryKey,
    required String title,
    required List<File> files,
    required List<DocumentModel> serverDocuments,
    required bool isUploading,
    required VoidCallback onUpload,
    required Function(File) onDeleteFile,
    required Function(DocumentModel) onDeleteDocument,
  }) {
    final hasFiles = files.isNotEmpty || serverDocuments.isNotEmpty;
    
    return CustomCard(
      padding: const EdgeInsets.all(16),
      // decoration removed as it's inside CustomCard
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700, // Made bolder to match design
                ),
              ),
              TextButton(
                onPressed: isUploading ? null : onUpload,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.black, // Dark background like "Join" button
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  AppStrings.upload,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!hasFiles)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  AppStrings.noFiles,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            )
          else
            Column(
              children: [
                // Show server documents first
                ...serverDocuments.map(
                  (doc) => DocumentModelTile(
                    document: doc,
                    onDelete: () => onDeleteDocument(doc),
                  ),
                ),
                // Show local files
                ...files.map(
                  (f) => DocumentTile(
                    file: f,
                    onDelete: () => onDeleteFile(f),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
