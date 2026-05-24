// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delete_document_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeleteDocumentResponseModel _$DeleteDocumentResponseModelFromJson(
  Map<String, dynamic> json,
) => DeleteDocumentResponseModel(
  status: json['status'] as String,
  message: json['message'] as String,
);

Map<String, dynamic> _$DeleteDocumentResponseModelToJson(
  DeleteDocumentResponseModel instance,
) => <String, dynamic>{'status': instance.status, 'message': instance.message};
