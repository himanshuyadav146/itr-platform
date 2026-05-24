import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tax_client/core/network/token_storage.dart';
import 'package:tax_client/features/document_upload/data/repositories/document_upload_repository_impl.dart';
import 'package:tax_client/features/document_upload/domain/usecases/upload_document.dart';
import 'package:tax_client/features/document_upload/domain/usecases/save_documents.dart';
import 'package:tax_client/features/document_upload/domain/usecases/get_documents.dart';
import 'package:tax_client/features/document_upload/domain/usecases/delete_document.dart';
import 'package:tax_client/features/document_upload/presentation/providers/document_upload_state.dart';
import 'package:tax_client/features/document_upload/presentation/viewmodel/document_upload_view_model.dart';

/// DI: Exposes use cases with repository dependencies
final uploadDocumentProvider = Provider<UploadDocument>((ref) {
  return UploadDocument(ref.watch(documentUploadRepositoryProvider));
});

final saveDocumentsProvider = Provider<SaveDocuments>((ref) {
  return SaveDocuments(ref.watch(documentUploadRepositoryProvider));
});

final getDocumentsProvider = Provider<GetDocuments>((ref) {
  return GetDocuments(ref.watch(documentUploadRepositoryProvider));
});

final deleteDocumentProvider = Provider<DeleteDocument>((ref) {
  return DeleteDocument(ref.watch(documentUploadRepositoryProvider));
});

/// DI: ViewModel provider managing document upload UI state and actions
final documentUploadViewModelProvider =
    StateNotifierProvider<DocumentUploadViewModel, DocumentUploadState>((ref) {
  return DocumentUploadViewModel(
    ref.watch(uploadDocumentProvider),
    ref.watch(saveDocumentsProvider),
    ref.watch(getDocumentsProvider),
    ref.watch(deleteDocumentProvider),
    ref.watch(tokenStorageProvider),
  );
});
