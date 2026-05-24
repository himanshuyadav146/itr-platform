import 'package:dartz/dartz.dart';
import 'package:tax_client/core/error/failures.dart';
import 'package:tax_client/core/usecase/usecase.dart';
import 'package:tax_client/features/document_upload/data/models/document_item_model.dart';
import 'package:tax_client/features/document_upload/data/models/save_documents_request_model.dart';
import 'package:tax_client/features/document_upload/domain/repositories/document_upload_repository.dart';

class SaveDocuments implements UseCase<String, SaveDocumentsParams> {
  final DocumentUploadRepository repository;

  SaveDocuments(this.repository);

  @override
  Future<Either<Failure, String>> call(SaveDocumentsParams params) async {
    final request = SaveDocumentsRequestModel(
      panNumber: params.panNumber,
      journeyType: params.journeyType,
      documents: params.documents,
    );
    return await repository.saveDocuments(request);
  }
}

class SaveDocumentsParams {
  final String panNumber;
  final String journeyType;
  final List<DocumentItemModel> documents;

  SaveDocumentsParams({
    required this.panNumber,
    required this.journeyType,
    required this.documents,
  });
}
