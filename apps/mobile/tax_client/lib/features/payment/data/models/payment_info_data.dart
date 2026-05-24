import 'package:json_annotation/json_annotation.dart';
import 'package:tax_client/features/payment/data/models/order_details.dart';
import 'package:tax_client/features/payment/data/models/payment_summary_item.dart';
import 'package:tax_client/features/payment/data/models/gateway_details.dart';

part 'payment_info_data.g.dart';

@JsonSerializable(explicitToJson: true)
class PaymentInfoData {
  @JsonKey(name: 'order_details')
  final OrderDetails orderDetails;
  @JsonKey(name: 'payment_summary')
  final List<PaymentSummaryItem> paymentSummary;
  @JsonKey(name: 'gateway_details')
  final GatewayDetails gatewayDetails;

  PaymentInfoData({
    required this.orderDetails,
    required this.paymentSummary,
    required this.gatewayDetails,
  });

  factory PaymentInfoData.fromJson(Map<String, dynamic> json) =>
      _$PaymentInfoDataFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentInfoDataToJson(this);
}

