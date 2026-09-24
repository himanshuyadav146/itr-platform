import 'package:json_annotation/json_annotation.dart';

part 'upload_document_data.g.dart';

@JsonSerializable()
class UploadDocumentData {
  final String message;
  @JsonKey(name: 'fileUrl')
  final String? fileUrl;
  @JsonKey(name: 'filePath')
  final String? filePath;
  final String? fileName;

  UploadDocumentData({
    required this.message,
    this.fileUrl,
    this.filePath,
    this.fileName,
  });

  factory UploadDocumentData.fromJson(Map<String, dynamic> json) =>
      _$UploadDocumentDataFromJson(json);

  Map<String, dynamic> toJson() => _$UploadDocumentDataToJson(this);
}
