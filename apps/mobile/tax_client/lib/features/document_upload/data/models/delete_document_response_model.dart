import 'package:json_annotation/json_annotation.dart';

part 'delete_document_response_model.g.dart';

@JsonSerializable()
class DeleteDocumentResponseModel {
  final String status;
  final String message;

  DeleteDocumentResponseModel({
    required this.status,
    required this.message,
  });

  factory DeleteDocumentResponseModel.fromJson(Map<String, dynamic> json) =>
      _$DeleteDocumentResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$DeleteDocumentResponseModelToJson(this);
}
