// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_summary_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentSummaryItem _$PaymentSummaryItemFromJson(Map<String, dynamic> json) =>
    PaymentSummaryItem(
      displayTitle: json['display_title'] as String,
      displayValue: json['display_value'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String?,
    );

Map<String, dynamic> _$PaymentSummaryItemToJson(PaymentSummaryItem instance) =>
    <String, dynamic>{
      'display_title': instance.displayTitle,
      'display_value': instance.displayValue,
      'amount': instance.amount,
      'type': instance.type,
    };
