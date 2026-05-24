import 'package:json_annotation/json_annotation.dart';

part 'save_documents_response_model.g.dart';

@JsonSerializable()
class SaveDocumentsResponseModel {
  final String status;
  final String message;

  SaveDocumentsResponseModel({
    required this.status,
    required this.message,
  });

  factory SaveDocumentsResponseModel.fromJson(Map<String, dynamic> json) =>
      _$SaveDocumentsResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$SaveDocumentsResponseModelToJson(this);
}
