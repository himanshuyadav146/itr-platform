import 'package:json_annotation/json_annotation.dart';

part 'payment_initiate_response.g.dart';

@JsonSerializable()
class PaymentInitiateResponse {
  @JsonKey(name: 'payment_id')
  final String paymentId;
  
  @JsonKey(name: 'order_id')
  final String orderId;
  
  @JsonKey(name: 'user_id')
  final int userId;
  
  @JsonKey(name: 'pan_number')
  final String? panNumber;
  
  final double amount;
  final String currency;
  
  @JsonKey(name: 'merchant_id')
  final String merchantId;

  @JsonKey(name: 'razorpay_order_id')
  final String? razorpayOrderId;
  
  final String message;

  PaymentInitiateResponse({
    required this.paymentId,
    required this.orderId,
    required this.userId,
    this.panNumber,
    required this.amount,
    required this.currency,
    required this.merchantId,
    this.razorpayOrderId,
    required this.message,
  });

  factory PaymentInitiateResponse.fromJson(Map<String, dynamic> json) =>
      _$PaymentInitiateResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentInitiateResponseToJson(this);
}

