import 'package:json_annotation/json_annotation.dart';

part 'upload_document_response_model.g.dart';

@JsonSerializable()
class UploadDocumentResponseModel {
  final String status;
  final String message;
  final String? filePath;
  final String? fileName;

  UploadDocumentResponseModel({
    required this.status,
    required this.message,
    this.filePath,
    this.fileName,
  });

  factory UploadDocumentResponseModel.fromJson(Map<String, dynamic> json) =>
      _$UploadDocumentResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$UploadDocumentResponseModelToJson(this);
}
