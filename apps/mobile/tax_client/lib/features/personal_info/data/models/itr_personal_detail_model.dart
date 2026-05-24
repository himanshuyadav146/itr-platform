import 'package:json_annotation/json_annotation.dart';
import 'package:tax_client/features/personal_info/data/models/itr_document_model.dart';

part 'itr_personal_detail_model.g.dart';

@JsonSerializable()
class ItrPersonalDetailModel {
  final String id;
  @JsonKey(name: 'itrId')
  final String? itrId;
  @JsonKey(name: 'UserId')
  final String userId;
  @JsonKey(name: 'PANNumber')
  final String panNumber;
  @JsonKey(name: 'FirstName')
  final String firstName;
  @JsonKey(name: 'MiddleName')
  final String? middleName;
  @JsonKey(name: 'LastName')
  final String lastName;
  @JsonKey(name: 'EMAIL')
  final String email;
  @JsonKey(name: 'MobileNumber')
  final String mobileNumber;
  @JsonKey(name: 'aadharCardNumber')
  final String aadharCardNumber;
  @JsonKey(name: 'Gender')
  final String gender;
  @JsonKey(name: 'DATEOFBIRTH')
  final String? dateOfBirth;
  @JsonKey(name: 'FinancialYear')
  final String financialYear;
  @JsonKey(name: 'Address')
  final String address;
  @JsonKey(name: 'Country')
  final String country;
  @JsonKey(name: 'isActive')
  final String isActive;
  @JsonKey(name: 'createdAt')
  final String createdAt;
  @JsonKey(name: 'createdBy')
  final String? createdBy;
  @JsonKey(name: 'updatedAt')
  final String? updatedAt;
  @JsonKey(name: 'updatedBy')
  final String? updatedBy;
  @JsonKey(name: 'documents')
  final List<ItrDocumentModel>? documents;
  @JsonKey(name: 'documentCount')
  final int? documentCount;
  @JsonKey(name: 'packageId')
  final int? packageId;
  @JsonKey(name: 'packageName')
  final String? packageName;
  @JsonKey(name: 'paymentStatus')
  final String? paymentStatus;
  @JsonKey(name: 'itrStatus')
  final String? itrStatus;
  @JsonKey(name: 'statusDisplayText')
  final String? statusDisplayText;

  ItrPersonalDetailModel({
    required this.id,
    this.itrId,
    required this.userId,
    required this.panNumber,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.email,
    required this.mobileNumber,
    required this.aadharCardNumber,
    required this.gender,
    this.dateOfBirth,
    required this.financialYear,
    required this.address,
    required this.country,
    required this.isActive,
    required this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
    this.documents,
    this.documentCount,
    this.packageId,
    this.packageName,
    this.paymentStatus,
    this.itrStatus,
    this.statusDisplayText,
  });

  factory ItrPersonalDetailModel.fromJson(Map<String, dynamic> json) =>
      _$ItrPersonalDetailModelFromJson(json);

  Map<String, dynamic> toJson() => _$ItrPersonalDetailModelToJson(this);
}

