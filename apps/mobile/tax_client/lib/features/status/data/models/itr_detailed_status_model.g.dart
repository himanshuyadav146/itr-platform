// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'itr_detailed_status_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ItrDetailedStatusModel _$ItrDetailedStatusModelFromJson(
  Map<String, dynamic> json,
) => ItrDetailedStatusModel(
  orderId: json['orderId'] as String?,
  userId: (json['userId'] as num?)?.toInt(),
  panNumber: json['panNumber'] as String?,
  itrStatus: json['itrStatus'] == null
      ? null
      : ItrStatusInfoModel.fromJson(json['itrStatus'] as Map<String, dynamic>),
  statusUpdates: (json['statusUpdates'] as List<dynamic>?)
      ?.map((e) => StatusUpdateModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  assignmentStatus: json['assignmentStatus'] == null
      ? null
      : AssignmentStatusModel.fromJson(
          json['assignmentStatus'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$ItrDetailedStatusModelToJson(
  ItrDetailedStatusModel instance,
) => <String, dynamic>{
  'orderId': instance.orderId,
  'userId': instance.userId,
  'panNumber': instance.panNumber,
  'itrStatus': instance.itrStatus,
  'statusUpdates': instance.statusUpdates,
  'assignmentStatus': instance.assignmentStatus,
};

ItrStatusInfoModel _$ItrStatusInfoModelFromJson(Map<String, dynamic> json) =>
    ItrStatusInfoModel(
      steps: (json['steps'] as List<dynamic>?)
          ?.map((e) => ItrStatusStepModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      overallStatus: json['overallStatus'] as String?,
      currentStep: (json['currentStep'] as num?)?.toInt(),
      totalSteps: (json['totalSteps'] as num?)?.toInt(),
      progressPercentage: (json['progressPercentage'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ItrStatusInfoModelToJson(ItrStatusInfoModel instance) =>
    <String, dynamic>{
      'steps': instance.steps,
      'overallStatus': instance.overallStatus,
      'currentStep': instance.currentStep,
      'totalSteps': instance.totalSteps,
      'progressPercentage': instance.progressPercentage,
    };

ItrStatusStepModel _$ItrStatusStepModelFromJson(Map<String, dynamic> json) =>
    ItrStatusStepModel(
      step: json['step'] as String?,
      title: json['title'] as String?,
      order: (json['order'] as num?)?.toInt(),
      isCompleted: json['isCompleted'] as bool?,
      completedAt: json['completedAt'] as String?,
      hasConcern: json['hasConcern'] as bool?,
      notes: json['notes'] as String?,
      concern: json['concern'] as String?,
    );

Map<String, dynamic> _$ItrStatusStepModelToJson(ItrStatusStepModel instance) =>
    <String, dynamic>{
      'step': instance.step,
      'title': instance.title,
      'order': instance.order,
      'isCompleted': instance.isCompleted,
      'completedAt': instance.completedAt,
      'hasConcern': instance.hasConcern,
      'notes': instance.notes,
      'concern': instance.concern,
    };

StatusUpdateModel _$StatusUpdateModelFromJson(Map<String, dynamic> json) =>
    StatusUpdateModel(
      id: (json['id'] as num?)?.toInt(),
      message: json['message'] as String?,
      status: json['status'] as String?,
      createdAt: json['createdAt'] as String?,
      resolvedAt: json['resolvedAt'] as String?,
      resolvedBy: (json['resolvedBy'] as num?)?.toInt(),
    );

Map<String, dynamic> _$StatusUpdateModelToJson(StatusUpdateModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'message': instance.message,
      'status': instance.status,
      'createdAt': instance.createdAt,
      'resolvedAt': instance.resolvedAt,
      'resolvedBy': instance.resolvedBy,
    };

AssignmentStatusModel _$AssignmentStatusModelFromJson(
  Map<String, dynamic> json,
) => AssignmentStatusModel(
  assignmentId: (json['assignmentId'] as num?)?.toInt(),
  professionalId: (json['professionalId'] as num?)?.toInt(),
  professionalName: json['professionalName'] as String?,
  professionalEmail: json['professionalEmail'] as String?,
  professionalMobile: json['professionalMobile'] as String?,
  professionalRole: json['professionalRole'] as String?,
  assignedAt: json['assignedAt'] as String?,
);

Map<String, dynamic> _$AssignmentStatusModelToJson(
  AssignmentStatusModel instance,
) => <String, dynamic>{
  'assignmentId': instance.assignmentId,
  'professionalId': instance.professionalId,
  'professionalName': instance.professionalName,
  'professionalEmail': instance.professionalEmail,
  'professionalMobile': instance.professionalMobile,
  'professionalRole': instance.professionalRole,
  'assignedAt': instance.assignedAt,
};
