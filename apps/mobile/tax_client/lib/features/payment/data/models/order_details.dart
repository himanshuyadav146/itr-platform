import 'package:json_annotation/json_annotation.dart';

part 'order_details.g.dart';

@JsonSerializable()
class OrderDetails {
  @JsonKey(name: 'Name')
  final String name;
  final String phone;
  final String email;

  OrderDetails({
    required this.name,
    required this.phone,
    required this.email,
  });

  factory OrderDetails.fromJson(Map<String, dynamic> json) =>
      _$OrderDetailsFromJson(json);

  Map<String, dynamic> toJson() => _$OrderDetailsToJson(this);
}

