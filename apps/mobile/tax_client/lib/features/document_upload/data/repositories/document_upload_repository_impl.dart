import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tax_client/core/error/failures.dart';
import 'package:tax_client/features/document_upload/data/datasources/document_upload_remote_data_source.dart';
import 'package:tax_client/features/document_upload/data/models/save_documents_request_model.dart';
import 'package:tax_client/features/document_upload/data/models/upload_document_data.dart';
import 'package:tax_client/features/document_upload/data/models/document_model.dart';
import 'package:tax_client/features/document_upload/data/models/delete_document_request_model.dart';
import 'package:tax_client/features/document_upload/domain/repositories/document_upload_repository.dart';

final documentUploadRepositoryProvider =
    Provider<DocumentUploadRepository>((ref) {
  return DocumentUploadRepositoryImpl(
    remoteDataSource: ref.read(documentUploadRemoteDataSourceProvider),
  );
});

class DocumentUploadRepositoryImpl implements DocumentUploadRepository {
  final DocumentUploadRemoteDataSource remoteDataSource;

  DocumentUploadRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, UploadDocumentData>> uploadDocument({
    required String panNumber,
    required String fileName,
    required File file,
  }) async {
    try {
      final result = await remoteDataSource.uploadDocument(
        panNumber: panNumber,
        fileName: fileName,
        file: file,
      );

      // UploadDocumentData contains: message, filePath, fileName
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> saveDocuments(
    SaveDocumentsRequestModel request,
  ) async {
    try {
      final result = await remoteDataSource.saveDocuments(request);

      // SaveDocumentsData contains: message
      return Right(result.message);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DocumentModel>>> getDocuments(
    String panNumber,
  ) async {
    try {
      final result = await remoteDataSource.getDocuments(panNumber);

      // GetDocumentsData contains: message, documents
      return Right(result.documents ?? []);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> deleteDocument(
    DeleteDocumentRequestModel request,
  ) async {
    try {
      final result = await remoteDataSource.deleteDocument(request);

      // DeleteDocumentData contains: message
      return Right(result.message);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
