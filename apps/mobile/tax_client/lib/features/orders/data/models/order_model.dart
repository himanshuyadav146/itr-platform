import 'package:json_annotation/json_annotation.dart';

part 'order_model.g.dart';

@JsonSerializable()
class OrderModel {
  final String? orderId;
  final String? paymentId;
  final int? itrId;
  final String? firstName;
  final String? lastName;
  final String? fullName;
  final String? mobile;
  final String? email;
  final String? panNumber;
  final String? financialYear;
  final String? packageName;
  final double? packagePrice;
  final OrderAmount? amount;
  
  @JsonKey(name: 'paymentStatus')
  final String? status;
  
  final String? paymentMethod;
  final String? transactionId;
  final String? paidAt;
  final String? createdAt;

  OrderModel({
    this.orderId,
    this.paymentId,
    this.itrId,
    this.firstName,
    this.lastName,
    this.fullName,
    this.mobile,
    this.email,
    this.panNumber,
    this.financialYear,
    this.packageName,
    this.packagePrice,
    this.amount,
    this.status,
    this.paymentMethod,
    this.transactionId,
    this.paidAt,
    this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) =>
      _$OrderModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderModelToJson(this);
}

@JsonSerializable()
class OrderAmount {
  final double? subtotal;
  final double? gstAmount;
  final double? grandTotal;
  final String? currency;

  OrderAmount({
    this.subtotal,
    this.gstAmount,
    this.grandTotal,
    this.currency,
  });

  factory OrderAmount.fromJson(Map<String, dynamic> json) =>
      _$OrderAmountFromJson(json);

  Map<String, dynamic> toJson() => _$OrderAmountToJson(this);
}
