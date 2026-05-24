import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:tax_client/core/error/failures.dart';
import 'package:tax_client/features/document_upload/data/models/save_documents_request_model.dart';
import 'package:tax_client/features/document_upload/data/models/upload_document_data.dart';
import 'package:tax_client/features/document_upload/data/models/document_model.dart';
import 'package:tax_client/features/document_upload/data/models/delete_document_request_model.dart';

abstract class DocumentUploadRepository {
  Future<Either<Failure, UploadDocumentData>> uploadDocument({
    required String panNumber,
    required String fileName,
    required File file,
  });

  Future<Either<Failure, String>> saveDocuments(
    SaveDocumentsRequestModel request,
  );

  Future<Either<Failure, List<DocumentModel>>> getDocuments(String panNumber);

  Future<Either<Failure, String>> deleteDocument(
    DeleteDocumentRequestModel request,
  );
}
