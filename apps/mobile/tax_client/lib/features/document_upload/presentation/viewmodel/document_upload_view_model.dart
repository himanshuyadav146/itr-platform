import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tax_client/core/error/failures.dart';
import 'package:tax_client/core/network/token_storage.dart';
import 'package:tax_client/features/document_upload/data/models/document_item_model.dart';
import 'package:tax_client/features/document_upload/data/models/document_model.dart';
import 'package:tax_client/features/document_upload/domain/usecases/upload_document.dart';
import 'package:tax_client/features/document_upload/domain/usecases/save_documents.dart';
import 'package:tax_client/features/document_upload/domain/usecases/get_documents.dart';
import 'package:tax_client/features/document_upload/domain/usecases/delete_document.dart';
import 'package:tax_client/features/document_upload/presentation/providers/document_upload_state.dart';

class DocumentUploadViewModel extends StateNotifier<DocumentUploadState> {
  final UploadDocument _uploadDocument;
  final SaveDocuments _saveDocuments;
  final GetDocuments _getDocuments;
  final DeleteDocument _deleteDocument;
  final TokenStorage _tokenStorage;

  // Store uploaded documents with their file paths
  final Map<String, Map<String, String>> _uploadedDocuments = {};
  // Store fetched documents from server
  List<DocumentModel> _fetchedDocuments = [];

  DocumentUploadViewModel(
    this._uploadDocument,
    this._saveDocuments,
    this._getDocuments,
    this._deleteDocument,
    this._tokenStorage,
  ) : super(const DocumentUploadInitial());

  Future<void> fetchDocuments() async {
    state = const DocumentsLoading();

    // Get PAN number from SharedPreferences
    final panNumber = await _tokenStorage.getPanNumber();
    if (panNumber == null || panNumber.isEmpty) {
      state = const DocumentUploadError(
        'PAN number not found. Please complete personal information first.',
      );
      return;
    }

    final result = await _getDocuments(panNumber);

    result.fold(
      (failure) => state = DocumentUploadError(_getErrorMessage(failure)),
      (documents) {
        _fetchedDocuments = documents;
        state = DocumentsLoaded(documents);
      },
    );
  }

  Future<void> deleteDocument({
    required String docId,
    required String fileName,
  }) async {
    state = DocumentDeleting(docId);

    // Get PAN number from SharedPreferences
    final panNumber = await _tokenStorage.getPanNumber();
    if (panNumber == null || panNumber.isEmpty) {
      state = const DocumentUploadError(
        'PAN number not found. Please complete personal information first.',
      );
      return;
    }

    final params = DeleteDocumentParams(
      docId: docId,
      panNumber: panNumber,
      fileName: fileName,
    );

    final result = await _deleteDocument(params);

    result.fold(
      (failure) => state = DocumentUploadError(_getErrorMessage(failure)),
      (message) {
        // Remove from fetched documents list
        _fetchedDocuments.removeWhere((doc) => doc.docId == docId);
        state = DocumentDeleted(message: message, docId: docId);
        // Update state to show remaining documents
        state = DocumentsLoaded(_fetchedDocuments);
      },
    );
  }

  Future<void> uploadDocument({
    required String documentCategory,
    required String fileName,
    required File file,
  }) async {
    state = DocumentUploading(fileName);

    // Get PAN number from SharedPreferences
    final panNumber = await _tokenStorage.getPanNumber();
    if (panNumber == null || panNumber.isEmpty) {
      state = const DocumentUploadError(
        'PAN number not found. Please complete personal information first.',
      );
      return;
    }

    final params = UploadDocumentParams(
      panNumber: panNumber,
      fileName: documentCategory,
      file: file,
    );

    final result = await _uploadDocument(params);

    result.fold(
      (failure) => state = DocumentUploadError(_getErrorMessage(failure)),
      (response) {
        final uploadedPath = response.fileUrl ?? response.filePath ?? '';
        // Store the uploaded document info
        _uploadedDocuments[documentCategory] = {
          'fileName': response.fileName ?? fileName,
          'filePath': uploadedPath,
          'fileType': _getFileType(file.path),
          'docId': '', // Will be set after save
        };

        state = DocumentUploadSuccess(
          fileName: response.fileName ?? fileName,
          filePath: uploadedPath,
          message: response.message,
        );
      },
    );
  }

  Future<void> saveAllDocuments({
    List<DocumentModel>? existingDocuments,
    required String journeyType,
  }) async {
    // Combine existing documents and newly uploaded documents
    final allDocuments = <DocumentItemModel>[];

    // Add existing documents from server
    if (existingDocuments != null && existingDocuments.isNotEmpty) {
      for (final doc in existingDocuments) {
        // Skip documents with missing required fields
        if (doc.documentName != null && doc.fileName != null) {
          allDocuments.add(
            DocumentItemModel(
              documentName: doc.documentName!,
              fileType: doc.fileType,
              filePassword: '',
              fileName: doc.fileName!,
            ),
          );
        }
      }
    }

    // Add newly uploaded documents
    if (_uploadedDocuments.isNotEmpty) {
      final newDocuments = _uploadedDocuments.entries.map((entry) {
        final docName = _getDocumentName(entry.key);
        final fileInfo = entry.value;

        return DocumentItemModel(
          documentName: docName,
          fileType: fileInfo['fileType'] ?? 'pdf',
          filePassword: '',
          fileName: fileInfo['fileName'] ?? '',
        );
      }).toList();

      allDocuments.addAll(newDocuments);
    }

    if (allDocuments.isEmpty) {
      state = const DocumentUploadError('No documents to save');
      return;
    }

    state = const DocumentsSaving();

    // Get PAN number from SharedPreferences
    final panNumber = await _tokenStorage.getPanNumber();
    if (panNumber == null || panNumber.isEmpty) {
      state = const DocumentUploadError(
        'PAN number not found. Please complete personal information first.',
      );
      return;
    }

    final params = SaveDocumentsParams(
      panNumber: panNumber,
      journeyType: journeyType,
      documents: allDocuments,
    );

    final result = await _saveDocuments(params);

    result.fold(
      (failure) => state = DocumentUploadError(_getErrorMessage(failure)),
      (message) {
        // Clear uploaded documents after successful save
        _uploadedDocuments.clear();
        state = DocumentsSaveSuccess(message: message);
      },
    );
  }

  String _getDocumentName(String category) {
    switch (category) {
      case 'form16a':
        return 'Form 16-A';
      case 'form16b':
        return 'Form 16-B';
      case 'others':
        return 'Other Documents';
      default:
        return category;
    }
  }

  String _getFileType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    return extension == 'pdf' ? 'pdf' : extension;
  }

  void resetState() {
    state = const DocumentUploadInitial();
  }

  String _getErrorMessage(Failure failure) {
    if (failure is ServerFailure && failure.message != null) {
      return failure.message!;
    }
    return 'An error occurred. Please try again.';
  }

  bool hasUploadedDocuments() => _uploadedDocuments.isNotEmpty;

  List<DocumentModel> get fetchedDocuments => _fetchedDocuments;
}
