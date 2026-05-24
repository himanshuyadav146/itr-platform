import 'package:json_annotation/json_annotation.dart';

part 'itr_document_model.g.dart';

@JsonSerializable()
class ItrDocumentModel {
  final String id;
  @JsonKey(name: 'documentName')
  final String documentName;
  @JsonKey(name: 'fileType')
  final String fileType;
  @JsonKey(name: 'filePassword')
  final String? filePassword;
  @JsonKey(name: 'fileName')
  final String fileName;
  @JsonKey(name: 'createdAt')
  final String createdAt;

  ItrDocumentModel({
    required this.id,
    required this.documentName,
    required this.fileType,
    this.filePassword,
    required this.fileName,
    required this.createdAt,
  });

  factory ItrDocumentModel.fromJson(Map<String, dynamic> json) =>
      _$ItrDocumentModelFromJson(json);

  Map<String, dynamic> toJson() => _$ItrDocumentModelToJson(this);
}

