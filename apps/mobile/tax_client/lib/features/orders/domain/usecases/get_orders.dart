import 'package:dartz/dartz.dart';
import 'package:tax_client/core/error/failures.dart';
import 'package:tax_client/features/orders/data/models/order_model.dart';
import 'package:tax_client/features/orders/domain/repositories/orders_repository.dart';
import 'package:tax_client/features/orders/data/repositories/orders_repository_impl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final getOrdersProvider = Provider<GetOrders>((ref) {
  return GetOrders(ref.read(ordersRepositoryProvider));
});

class GetOrders {
  final OrdersRepository _repository;

  GetOrders(this._repository);

  Future<Either<Failure, List<OrderModel>>> call({int page = 1, int limit = 20}) async {
    return await _repository.getOrders(page: page, limit: limit);
  }
}
