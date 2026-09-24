// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_initiate_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentInitiateResponse _$PaymentInitiateResponseFromJson(
  Map<String, dynamic> json,
) => PaymentInitiateResponse(
  paymentId: json['payment_id'] as String,
  orderId: json['order_id'] as String,
  userId: (json['user_id'] as num).toInt(),
  panNumber: json['pan_number'] as String?,
  amount: (json['amount'] as num).toDouble(),
  currency: json['currency'] as String,
  merchantId: json['merchant_id'] as String,
  razorpayOrderId: json['razorpay_order_id'] as String?,
  message: json['message'] as String,
);

Map<String, dynamic> _$PaymentInitiateResponseToJson(
  PaymentInitiateResponse instance,
) => <String, dynamic>{
  'payment_id': instance.paymentId,
  'order_id': instance.orderId,
  'user_id': instance.userId,
  'pan_number': instance.panNumber,
  'amount': instance.amount,
  'currency': instance.currency,
  'merchant_id': instance.merchantId,
  'razorpay_order_id': instance.razorpayOrderId,
  'message': instance.message,
};
