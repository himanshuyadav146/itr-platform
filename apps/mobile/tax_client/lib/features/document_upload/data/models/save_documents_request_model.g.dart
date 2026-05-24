// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'save_documents_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaveDocumentsRequestModel _$SaveDocumentsRequestModelFromJson(
  Map<String, dynamic> json,
) => SaveDocumentsRequestModel(
  panNumber: json['PanNumber'] as String,
  documents: (json['documents'] as List<dynamic>)
      .map((e) => DocumentItemModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  journeyType: json['journeyType'] as String,
);

Map<String, dynamic> _$SaveDocumentsRequestModelToJson(
  SaveDocumentsRequestModel instance,
) => <String, dynamic>{
  'PanNumber': instance.panNumber,
  'journeyType': instance.journeyType,
  'documents': instance.documents.map((e) => e.toJson()).toList(),
};
