import 'package:tax_client/core/constant/api_constants.dart';
import 'package:tax_client/core/network/api_client.dart';
import 'package:tax_client/features/orders/data/models/order_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ordersRemoteDataSourceProvider = Provider<OrdersRemoteDataSource>((ref) {
  return OrdersRemoteDataSource(ref.read(apiClientProvider));
});

class OrdersRemoteDataSource {
  final ApiClient _apiClient;

  OrdersRemoteDataSource(this._apiClient);

  Future<List<OrderModel>> getOrders({int page = 1, int limit = 20}) async {
    final response = await _apiClient.get(
      '${ApiConstants.itrGetOrders}?page=$page&limit=$limit',
      (json) {
        if (json['orders'] != null && json['orders'] is List) {
          return (json['orders'] as List)
              .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return <OrderModel>[];
      },
    );
    return response.data ?? [];
  }
}
