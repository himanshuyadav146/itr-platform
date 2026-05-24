import 'package:dartz/dartz.dart';
import 'package:tax_client/core/error/failures.dart';
import 'package:tax_client/core/usecase/usecase.dart';
import 'package:tax_client/features/document_upload/data/models/document_model.dart';
import 'package:tax_client/features/document_upload/domain/repositories/document_upload_repository.dart';

class GetDocuments implements UseCase<List<DocumentModel>, String> {
  final DocumentUploadRepository repository;

  GetDocuments(this.repository);

  @override
  Future<Either<Failure, List<DocumentModel>>> call(String panNumber) async {
    return await repository.getDocuments(panNumber);
  }
}
