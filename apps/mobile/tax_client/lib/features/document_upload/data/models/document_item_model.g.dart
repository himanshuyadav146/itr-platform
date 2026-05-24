// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DocumentItemModel _$DocumentItemModelFromJson(Map<String, dynamic> json) =>
    DocumentItemModel(
      documentName: json['documentName'] as String,
      fileType: json['fileType'] as String,
      filePassword: json['filePassword'] as String,
      fileName: json['fileName'] as String,
    );

Map<String, dynamic> _$DocumentItemModelToJson(DocumentItemModel instance) =>
    <String, dynamic>{
      'documentName': instance.documentName,
      'fileType': instance.fileType,
      'filePassword': instance.filePassword,
      'fileName': instance.fileName,
    };
