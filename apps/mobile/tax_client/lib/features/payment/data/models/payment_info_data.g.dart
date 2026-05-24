// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_info_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentInfoData _$PaymentInfoDataFromJson(Map<String, dynamic> json) =>
    PaymentInfoData(
      orderDetails: OrderDetails.fromJson(
        json['order_details'] as Map<String, dynamic>,
      ),
      paymentSummary: (json['payment_summary'] as List<dynamic>)
          .map((e) => PaymentSummaryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      gatewayDetails: GatewayDetails.fromJson(
        json['gateway_details'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$PaymentInfoDataToJson(
  PaymentInfoData instance,
) => <String, dynamic>{
  'order_details': instance.orderDetails.toJson(),
  'payment_summary': instance.paymentSummary.map((e) => e.toJson()).toList(),
  'gateway_details': instance.gatewayDetails.toJson(),
};
