import 'package:json_annotation/json_annotation.dart';

part 'itr_detailed_status_model.g.dart';

@JsonSerializable()
class ItrDetailedStatusModel {
  final String? orderId;
  final int? userId;
  final String? panNumber;
  final ItrStatusInfoModel? itrStatus;
  final List<StatusUpdateModel>? statusUpdates;
  final AssignmentStatusModel? assignmentStatus;

  ItrDetailedStatusModel({
    this.orderId,
    this.userId,
    this.panNumber,
    this.itrStatus,
    this.statusUpdates,
    this.assignmentStatus,
  });

  factory ItrDetailedStatusModel.fromJson(Map<String, dynamic> json) =>
      _$ItrDetailedStatusModelFromJson(json);

  Map<String, dynamic> toJson() => _$ItrDetailedStatusModelToJson(this);
}

@JsonSerializable()
class ItrStatusInfoModel {
  final List<ItrStatusStepModel>? steps;
  final String? overallStatus;
  final int? currentStep;
  final int? totalSteps;
  final int? progressPercentage;

  ItrStatusInfoModel({
    this.steps,
    this.overallStatus,
    this.currentStep,
    this.totalSteps,
    this.progressPercentage,
  });

  factory ItrStatusInfoModel.fromJson(Map<String, dynamic> json) =>
      _$ItrStatusInfoModelFromJson(json);

  Map<String, dynamic> toJson() => _$ItrStatusInfoModelToJson(this);
}

@JsonSerializable()
class ItrStatusStepModel {
  final String? step;
  final String? title;
  final int? order;
  final bool? isCompleted;
  final String? completedAt;
  final bool? hasConcern;
  final String? notes;
  final String? concern;

  ItrStatusStepModel({
    this.step,
    this.title,
    this.order,
    this.isCompleted,
    this.completedAt,
    this.hasConcern,
    this.notes,
    this.concern,
  });

  factory ItrStatusStepModel.fromJson(Map<String, dynamic> json) =>
      _$ItrStatusStepModelFromJson(json);

  Map<String, dynamic> toJson() => _$ItrStatusStepModelToJson(this);
}

@JsonSerializable()
class StatusUpdateModel {
  final int? id;
  final String? message;
  final String? status;
  final String? createdAt;
  final String? resolvedAt;
  final int? resolvedBy;

  StatusUpdateModel({
    this.id,
    this.message,
    this.status,
    this.createdAt,
    this.resolvedAt,
    this.resolvedBy,
  });

  factory StatusUpdateModel.fromJson(Map<String, dynamic> json) =>
      _$StatusUpdateModelFromJson(json);

  Map<String, dynamic> toJson() => _$StatusUpdateModelToJson(this);
}

@JsonSerializable()
class AssignmentStatusModel {
  final int? assignmentId;
  final int? professionalId;
  final String? professionalName;
  final String? professionalEmail;
  final String? professionalMobile;
  final String? professionalRole;
  final String? assignedAt;

  AssignmentStatusModel({
    this.assignmentId,
    this.professionalId,
    this.professionalName,
    this.professionalEmail,
    this.professionalMobile,
    this.professionalRole,
    this.assignedAt,
  });

  factory AssignmentStatusModel.fromJson(Map<String, dynamic> json) =>
      _$AssignmentStatusModelFromJson(json);

  Map<String, dynamic> toJson() => _$AssignmentStatusModelToJson(this);
}
