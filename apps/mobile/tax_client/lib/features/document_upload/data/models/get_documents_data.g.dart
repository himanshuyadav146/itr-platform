// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_documents_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetDocumentsData _$GetDocumentsDataFromJson(Map<String, dynamic> json) =>
    GetDocumentsData(
      message: json['message'] as String?,
      documents: (json['documents'] as List<dynamic>?)
          ?.map((e) => DocumentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$GetDocumentsDataToJson(GetDocumentsData instance) =>
    <String, dynamic>{
      'message': instance.message,
      'documents': instance.documents?.map((e) => e.toJson()).toList(),
    };
