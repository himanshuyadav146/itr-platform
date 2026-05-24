import 'package:json_annotation/json_annotation.dart';
import 'package:tax_client/features/document_upload/data/models/document_model.dart';

part 'get_documents_data.g.dart';

@JsonSerializable(explicitToJson: true)
class GetDocumentsData {
  final String? message;
  final List<DocumentModel>? documents;

  GetDocumentsData({
    this.message,
    this.documents,
  });

  factory GetDocumentsData.fromJson(Map<String, dynamic> json) {
    return GetDocumentsData(
      message: json['message'] as String?,
      documents: (json['documents'] as List<dynamic>?)
          ?.map((e) => DocumentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => _$GetDocumentsDataToJson(this);
}
