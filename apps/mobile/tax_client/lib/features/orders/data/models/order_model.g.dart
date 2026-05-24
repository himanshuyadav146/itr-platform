// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderModel _$OrderModelFromJson(Map<String, dynamic> json) => OrderModel(
  orderId: json['orderId'] as String?,
  paymentId: json['paymentId'] as String?,
  itrId: (json['itrId'] as num?)?.toInt(),
  firstName: json['firstName'] as String?,
  lastName: json['lastName'] as String?,
  fullName: json['fullName'] as String?,
  mobile: json['mobile'] as String?,
  email: json['email'] as String?,
  panNumber: json['panNumber'] as String?,
  financialYear: json['financialYear'] as String?,
  packageName: json['packageName'] as String?,
  packagePrice: (json['packagePrice'] as num?)?.toDouble(),
  amount: json['amount'] == null
      ? null
      : OrderAmount.fromJson(json['amount'] as Map<String, dynamic>),
  status: json['paymentStatus'] as String?,
  paymentMethod: json['paymentMethod'] as String?,
  transactionId: json['transactionId'] as String?,
  paidAt: json['paidAt'] as String?,
  createdAt: json['createdAt'] as String?,
);

Map<String, dynamic> _$OrderModelToJson(OrderModel instance) =>
    <String, dynamic>{
      'orderId': instance.orderId,
      'paymentId': instance.paymentId,
      'itrId': instance.itrId,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'fullName': instance.fullName,
      'mobile': instance.mobile,
      'email': instance.email,
      'panNumber': instance.panNumber,
      'financialYear': instance.financialYear,
      'packageName': instance.packageName,
      'packagePrice': instance.packagePrice,
      'amount': instance.amount,
      'paymentStatus': instance.status,
      'paymentMethod': instance.paymentMethod,
      'transactionId': instance.transactionId,
      'paidAt': instance.paidAt,
      'createdAt': instance.createdAt,
    };

OrderAmount _$OrderAmountFromJson(Map<String, dynamic> json) => OrderAmount(
  subtotal: (json['subtotal'] as num?)?.toDouble(),
  gstAmount: (json['gstAmount'] as num?)?.toDouble(),
  grandTotal: (json['grandTotal'] as num?)?.toDouble(),
  currency: json['currency'] as String?,
);

Map<String, dynamic> _$OrderAmountToJson(OrderAmount instance) =>
    <String, dynamic>{
      'subtotal': instance.subtotal,
      'gstAmount': instance.gstAmount,
      'grandTotal': instance.grandTotal,
      'currency': instance.currency,
    };
