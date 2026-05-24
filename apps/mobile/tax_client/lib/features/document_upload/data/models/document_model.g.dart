// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DocumentModel _$DocumentModelFromJson(Map<String, dynamic> json) =>
    DocumentModel(
      docId: json['docId'] as String?,
      documentName: json['documentName'] as String?,
      fileName: json['fileName'] as String?,
      filePath: json['filePath'] as String?,
      fileType: json['fileType'] as String,
      uploadedAt: json['uploadedAt'] as String?,
    );

Map<String, dynamic> _$DocumentModelToJson(DocumentModel instance) =>
    <String, dynamic>{
      'docId': instance.docId,
      'documentName': instance.documentName,
      'fileName': instance.fileName,
      'filePath': instance.filePath,
      'fileType': instance.fileType,
      'uploadedAt': instance.uploadedAt,
    };
