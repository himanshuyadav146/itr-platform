import 'package:json_annotation/json_annotation.dart';
import 'package:tax_client/features/document_upload/data/models/document_item_model.dart';

part 'save_documents_request_model.g.dart';

@JsonSerializable(explicitToJson: true)
class SaveDocumentsRequestModel {
  @JsonKey(name: 'PanNumber')
  final String panNumber;
  final String journeyType;
  final List<DocumentItemModel> documents;

  SaveDocumentsRequestModel({
    required this.panNumber,
    required this.documents,
    required this.journeyType,
  });

  factory SaveDocumentsRequestModel.fromJson(Map<String, dynamic> json) =>
      _$SaveDocumentsRequestModelFromJson(json);

  Map<String, dynamic> toJson() => _$SaveDocumentsRequestModelToJson(this);
}
