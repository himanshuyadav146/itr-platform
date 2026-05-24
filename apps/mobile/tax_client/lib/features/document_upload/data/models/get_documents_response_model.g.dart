// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_documents_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetDocumentsResponseModel _$GetDocumentsResponseModelFromJson(
  Map<String, dynamic> json,
) => GetDocumentsResponseModel(
  status: json['status'] as String,
  message: json['message'] as String,
  documents: (json['documents'] as List<dynamic>?)
      ?.map((e) => DocumentModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$GetDocumentsResponseModelToJson(
  GetDocumentsResponseModel instance,
) => <String, dynamic>{
  'status': instance.status,
  'message': instance.message,
  'documents': instance.documents?.map((e) => e.toJson()).toList(),
};
