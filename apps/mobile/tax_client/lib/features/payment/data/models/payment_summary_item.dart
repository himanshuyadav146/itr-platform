import 'package:json_annotation/json_annotation.dart';

part 'payment_summary_item.g.dart';

@JsonSerializable()
class PaymentSummaryItem {
  @JsonKey(name: 'display_title')
  final String displayTitle;
  @JsonKey(name: 'display_value')
  final String displayValue;
  final double amount;
  final String? type;

  PaymentSummaryItem({
    required this.displayTitle,
    required this.displayValue,
    required this.amount,
    this.type,
  });

  factory PaymentSummaryItem.fromJson(Map<String, dynamic> json) =>
      _$PaymentSummaryItemFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentSummaryItemToJson(this);
}

