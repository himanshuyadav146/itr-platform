import 'package:dartz/dartz.dart';
import 'package:tax_client/core/error/failures.dart';
import 'package:tax_client/core/usecase/usecase.dart';
import 'package:tax_client/features/document_upload/data/models/delete_document_request_model.dart';
import 'package:tax_client/features/document_upload/domain/repositories/document_upload_repository.dart';

class DeleteDocument implements UseCase<String, DeleteDocumentParams> {
  final DocumentUploadRepository repository;

  DeleteDocument(this.repository);

  @override
  Future<Either<Failure, String>> call(DeleteDocumentParams params) async {
    final request = DeleteDocumentRequestModel(
      docId: params.docId,
      panNumber: params.panNumber,
      fileName: params.fileName,
    );
    return await repository.deleteDocument(request);
  }
}

class DeleteDocumentParams {
  final String docId;
  final String panNumber;
  final String fileName;

  DeleteDocumentParams({
    required this.docId,
    required this.panNumber,
    required this.fileName,
  });
}
