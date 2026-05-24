import 'package:json_annotation/json_annotation.dart';

part 'save_documents_data.g.dart';

@JsonSerializable()
class SaveDocumentsData {
  final String message;

  SaveDocumentsData({
    required this.message,
  });

  factory SaveDocumentsData.fromJson(Map<String, dynamic> json) =>
      _$SaveDocumentsDataFromJson(json);

  Map<String, dynamic> toJson() => _$SaveDocumentsDataToJson(this);
}
