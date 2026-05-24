import 'package:json_annotation/json_annotation.dart';

part 'document_item_model.g.dart';

@JsonSerializable()
class DocumentItemModel {
  final String documentName;
  final String fileType;
  final String filePassword;
  final String fileName;

  DocumentItemModel({
    required this.documentName,
    required this.fileType,
    required this.filePassword,
    required this.fileName,
  });

  factory DocumentItemModel.fromJson(Map<String, dynamic> json) =>
      _$DocumentItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$DocumentItemModelToJson(this);
}
