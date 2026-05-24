import 'package:equatable/equatable.dart';
import 'package:tax_client/features/document_upload/data/models/document_model.dart';

abstract class DocumentUploadState extends Equatable {
  const DocumentUploadState();

  @override
  List<Object?> get props => [];
}

class DocumentUploadInitial extends DocumentUploadState {
  const DocumentUploadInitial();
}

class DocumentsLoading extends DocumentUploadState {
  const DocumentsLoading();
}

class DocumentsLoaded extends DocumentUploadState {
  final List<DocumentModel> documents;

  const DocumentsLoaded(this.documents);

  @override
  List<Object?> get props => [documents];
}

class DocumentUploading extends DocumentUploadState {
  final String fileName;
  
  const DocumentUploading(this.fileName);

  @override
  List<Object?> get props => [fileName];
}

class DocumentUploadSuccess extends DocumentUploadState {
  final String fileName;
  final String filePath;
  final String message;

  const DocumentUploadSuccess({
    required this.fileName,
    required this.filePath,
    required this.message,
  });

  @override
  List<Object?> get props => [fileName, filePath, message];
}

class DocumentDeleting extends DocumentUploadState {
  final String docId;

  const DocumentDeleting(this.docId);

  @override
  List<Object?> get props => [docId];
}

class DocumentDeleted extends DocumentUploadState {
  final String message;
  final String docId;

  const DocumentDeleted({
    required this.message,
    required this.docId,
  });

  @override
  List<Object?> get props => [message, docId];
}

class DocumentsSaving extends DocumentUploadState {
  const DocumentsSaving();
}

class DocumentsSaveSuccess extends DocumentUploadState {
  final String message;

  const DocumentsSaveSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class DocumentUploadError extends DocumentUploadState {
  final String message;

  const DocumentUploadError(this.message);

  @override
  List<Object?> get props => [message];
}
