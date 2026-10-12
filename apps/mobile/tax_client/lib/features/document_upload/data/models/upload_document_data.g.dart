// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upload_document_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UploadDocumentData _$UploadDocumentDataFromJson(Map<String, dynamic> json) =>
    UploadDocumentData(
      message: json['message'] as String,
      fileUrl: json['fileUrl'] as String?,
      fileName: json['fileName'] as String?,
    );

Map<String, dynamic> _$UploadDocumentDataToJson(UploadDocumentData instance) =>
    <String, dynamic>{
      'message': instance.message,
      'fileUrl': instance.fileUrl,
      'fileName': instance.fileName,
    };
