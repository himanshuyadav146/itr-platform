import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:tax_client/core/error/failures.dart';
import 'package:tax_client/core/usecase/usecase.dart';
import 'package:tax_client/features/document_upload/data/models/upload_document_data.dart';
import 'package:tax_client/features/document_upload/domain/repositories/document_upload_repository.dart';

class UploadDocument
    implements UseCase<UploadDocumentData, UploadDocumentParams> {
  final DocumentUploadRepository repository;

  UploadDocument(this.repository);

  @override
  Future<Either<Failure, UploadDocumentData>> call(
    UploadDocumentParams params,
  ) async {
    return await repository.uploadDocument(
      panNumber: params.panNumber,
      fileName: params.fileName,
      file: params.file,
    );
  }
}

class UploadDocumentParams {
  final String panNumber;
  final String fileName;
  final File file;

  UploadDocumentParams({
    required this.panNumber,
    required this.fileName,
    required this.file,
  });
}
