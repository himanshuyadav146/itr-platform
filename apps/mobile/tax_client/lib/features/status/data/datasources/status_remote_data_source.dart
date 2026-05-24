import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tax_client/core/constant/api_constants.dart';
import 'package:tax_client/core/network/api_client.dart';
import 'package:tax_client/features/status/data/models/itr_detailed_status_model.dart';

final statusRemoteDataSourceProvider = Provider<StatusRemoteDataSource>((ref) {
  return StatusRemoteDataSourceImpl(ref.read(apiClientProvider));
});

abstract class StatusRemoteDataSource {
  Future<ItrDetailedStatusModel> getDetailedStatus(String orderId,String itrId);
}

class StatusRemoteDataSourceImpl implements StatusRemoteDataSource {
  final ApiClient apiClient;

  StatusRemoteDataSourceImpl(this.apiClient);

  @override
  Future<ItrDetailedStatusModel> getDetailedStatus(String orderId,String itrId) async {
    final response = await apiClient.get(
      // '${ApiConstants.itrGetDetailedStatus}?orderId=$orderId&itrId=$itrId&debug=1',
      '${ApiConstants.itrGetDetailedStatus}?orderId=$orderId&itrId=$itrId',
      (json) => ItrDetailedStatusModel.fromJson(json),
    );

    return response.data;
  }
}
