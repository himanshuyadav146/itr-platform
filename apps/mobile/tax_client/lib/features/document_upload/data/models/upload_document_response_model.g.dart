// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upload_document_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UploadDocumentResponseModel _$UploadDocumentResponseModelFromJson(
  Map<String, dynamic> json,
) => UploadDocumentResponseModel(
  status: json['status'] as String,
  message: json['message'] as String,
  filePath: json['filePath'] as String?,
  fileName: json['fileName'] as String?,
);

Map<String, dynamic> _$UploadDocumentResponseModelToJson(
  UploadDocumentResponseModel instance,
) => <String, dynamic>{
  'status': instance.status,
  'message': instance.message,
  'filePath': instance.filePath,
  'fileName': instance.fileName,
};
