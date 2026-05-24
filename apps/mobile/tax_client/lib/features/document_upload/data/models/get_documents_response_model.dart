import 'package:json_annotation/json_annotation.dart';
import 'package:tax_client/features/document_upload/data/models/document_model.dart';

part 'get_documents_response_model.g.dart';

@JsonSerializable(explicitToJson: true)
class GetDocumentsResponseModel {
  final String status;
  final String message;
  final List<DocumentModel>? documents;

  GetDocumentsResponseModel({
    required this.status,
    required this.message,
    this.documents,
  });

  factory GetDocumentsResponseModel.fromJson(Map<String, dynamic> json) =>
      _$GetDocumentsResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$GetDocumentsResponseModelToJson(this);
}
