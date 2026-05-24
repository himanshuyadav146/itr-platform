import 'package:json_annotation/json_annotation.dart';

part 'delete_document_request_model.g.dart';

@JsonSerializable()
class DeleteDocumentRequestModel {
  @JsonKey(name: 'id')
  final String docId;
  @JsonKey(name: 'PanNumber')
  final String panNumber;
  final String fileName;

  DeleteDocumentRequestModel({
    required this.docId,
    required this.panNumber,
    required this.fileName,
  });

  factory DeleteDocumentRequestModel.fromJson(Map<String, dynamic> json) =>
      _$DeleteDocumentRequestModelFromJson(json);

  Map<String, dynamic> toJson() => _$DeleteDocumentRequestModelToJson(this);
}
