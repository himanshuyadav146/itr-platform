// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delete_document_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeleteDocumentRequestModel _$DeleteDocumentRequestModelFromJson(
  Map<String, dynamic> json,
) => DeleteDocumentRequestModel(
  docId: json['id'] as String,
  panNumber: json['PanNumber'] as String,
  fileName: json['fileName'] as String,
);

Map<String, dynamic> _$DeleteDocumentRequestModelToJson(
  DeleteDocumentRequestModel instance,
) => <String, dynamic>{
  'id': instance.docId,
  'PanNumber': instance.panNumber,
  'fileName': instance.fileName,
};
