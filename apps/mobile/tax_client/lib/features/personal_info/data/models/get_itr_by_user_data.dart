import 'package:json_annotation/json_annotation.dart';
import 'package:tax_client/features/personal_info/data/models/itr_personal_detail_model.dart';

part 'get_itr_by_user_data.g.dart';

@JsonSerializable()
class GetItrByUserData {
  @JsonKey(name: 'personalDetails')
  final List<ItrPersonalDetailModel> personalDetails;
  final int count;
  final String message;

  GetItrByUserData({
    required this.personalDetails,
    required this.count,
    required this.message,
  });

  factory GetItrByUserData.fromJson(Map<String, dynamic> json) =>
      _$GetItrByUserDataFromJson(json);

  Map<String, dynamic> toJson() => _$GetItrByUserDataToJson(this);
}

