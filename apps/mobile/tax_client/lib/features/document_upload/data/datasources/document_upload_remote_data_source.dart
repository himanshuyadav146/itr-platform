import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tax_client/core/constant/api_constants.dart';
import 'package:tax_client/core/network/api_client.dart';
import 'package:tax_client/features/document_upload/data/models/upload_document_data.dart';
import 'package:tax_client/features/document_upload/data/models/save_documents_request_model.dart';
import 'package:tax_client/features/document_upload/data/models/save_documents_data.dart';
import 'package:tax_client/features/document_upload/data/models/get_documents_data.dart';
import 'package:tax_client/features/document_upload/data/models/delete_document_request_model.dart';
import 'package:tax_client/features/document_upload/data/models/delete_document_data.dart';

final documentUploadRemoteDataSourceProvider =
    Provider<DocumentUploadRemoteDataSource>((ref) {
  return DocumentUploadRemoteDataSourceImpl(ref.read(apiClientProvider));
});

abstract class DocumentUploadRemoteDataSource {
  Future<UploadDocumentData> uploadDocument({
    required String panNumber,
    required String fileName,
    required File file,
  });

  Future<SaveDocumentsData> saveDocuments(
    SaveDocumentsRequestModel request,
  );

  Future<GetDocumentsData> getDocuments(String panNumber);

  Future<DeleteDocumentData> deleteDocument(
    DeleteDocumentRequestModel request,
  );
}

class DocumentUploadRemoteDataSourceImpl
    implements DocumentUploadRemoteDataSource {
  final ApiClient apiClient;

  DocumentUploadRemoteDataSourceImpl(this.apiClient);

  @override
  Future<UploadDocumentData> uploadDocument({
    required String panNumber,
    required String fileName,
    required File file,
  }) async {
    final response = await apiClient.postMultipart(
      ApiConstants.itrDetailsAddDocuments,
      (json) => UploadDocumentData.fromJson(json),
      fields: {
        'PanNumber': panNumber,
        'fileName': fileName,
      },
      files: {
        'file': file,
      },
    );

    return response.data;
  }

  @override
  Future<SaveDocumentsData> saveDocuments(
    SaveDocumentsRequestModel request,
  ) async {
    final response = await apiClient.post(
      ApiConstants.itrDetailsSaveDocuments,
      request.toJson(),
      (json) => SaveDocumentsData.fromJson(json),
    );

    return response.data;
  }

  @override
  Future<GetDocumentsData> getDocuments(String panNumber) async {
    final response = await apiClient.get(
      '${ApiConstants.itrDetailsGetDocuments}?PanNumber=$panNumber',
      (json) => GetDocumentsData.fromJson(json),
    );

    return response.data;
  }

  @override
  Future<DeleteDocumentData> deleteDocument(
    DeleteDocumentRequestModel request,
  ) async {
    final response = await apiClient.post(
      ApiConstants.itrDetailsDeleteDocument,
      request.toJson(),
      (json) => DeleteDocumentData.fromJson(json),
    );

    return response.data;
  }
}
