import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tax_client/core/error/failures.dart';
import 'package:tax_client/features/status/domain/usecases/get_detailed_status.dart';
import 'package:tax_client/features/status/presentation/viewmodel/status_state.dart';

final statusViewModelProvider = StateNotifierProvider<StatusViewModel, StatusState>((ref) {
  return StatusViewModel(ref.read(getDetailedStatusProvider));
});

class StatusViewModel extends StateNotifier<StatusState> {
  final GetDetailedStatus _getDetailedStatus;

  StatusViewModel(this._getDetailedStatus) : super(const StatusInitial());

  Future<void> fetchDetailedStatus(String orderId,String itrId) async {
    state = const StatusLoading();

    final result = await _getDetailedStatus(orderId,itrId);

    result.fold(
      (failure) => state = StatusError(_getErrorMessage(failure)),
      (status) => state = StatusLoaded(status),
    );
  }

  String _getErrorMessage(Failure failure) {
    if (failure is ServerFailure && failure.message != null) {
      return failure.message!;
    }
    return 'An error occurred. Please try again.';
  }
}
