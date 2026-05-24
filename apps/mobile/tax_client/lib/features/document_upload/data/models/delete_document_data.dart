import 'package:json_annotation/json_annotation.dart';

part 'delete_document_data.g.dart';

@JsonSerializable()
class DeleteDocumentData {
  final String message;

  DeleteDocumentData({
    required this.message,
  });

  factory DeleteDocumentData.fromJson(Map<String, dynamic> json) =>
      _$DeleteDocumentDataFromJson(json);

  Map<String, dynamic> toJson() => _$DeleteDocumentDataToJson(this);
}
