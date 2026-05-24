import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tax_client/features/status/data/models/itr_detailed_status_model.dart';

part 'status_state.freezed.dart';

@freezed
class StatusState with _$StatusState {
  const factory StatusState.initial() = StatusInitial;
  const factory StatusState.loading() = StatusLoading;
  const factory StatusState.loaded(ItrDetailedStatusModel status) = StatusLoaded;
  const factory StatusState.error(String message) = StatusError;
}
