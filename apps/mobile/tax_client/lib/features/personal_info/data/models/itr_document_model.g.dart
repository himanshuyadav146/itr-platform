// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'itr_document_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ItrDocumentModel _$ItrDocumentModelFromJson(Map<String, dynamic> json) =>
    ItrDocumentModel(
      id: json['id'] as String,
      documentName: json['documentName'] as String,
      fileType: json['fileType'] as String,
      filePassword: json['filePassword'] as String?,
      fileName: json['fileName'] as String,
      createdAt: json['createdAt'] as String,
    );

Map<String, dynamic> _$ItrDocumentModelToJson(ItrDocumentModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'documentName': instance.documentName,
      'fileType': instance.fileType,
      'filePassword': instance.filePassword,
      'fileName': instance.fileName,
      'createdAt': instance.createdAt,
    };
