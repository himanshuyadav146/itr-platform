import 'package:json_annotation/json_annotation.dart';

part 'gateway_details.g.dart';

@JsonSerializable()
class GatewayDetails {
  @JsonKey(name: 'key_id')
  final String mid;

  GatewayDetails({
    required this.mid,
  });

  factory GatewayDetails.fromJson(Map<String, dynamic> json) =>
      _$GatewayDetailsFromJson(json);

  Map<String, dynamic> toJson() => _$GatewayDetailsToJson(this);
}

