import 'package:dartz/dartz.dart';
import 'package:tax_client/core/error/failures.dart';
import 'package:tax_client/features/orders/data/datasources/orders_remote_data_source.dart';
import 'package:tax_client/features/orders/data/models/order_model.dart';
import 'package:tax_client/features/orders/domain/repositories/orders_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tax_client/core/network/exceptions.dart';

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return OrdersRepositoryImpl(ref.read(ordersRemoteDataSourceProvider));
});

class OrdersRepositoryImpl implements OrdersRepository {
  final OrdersRemoteDataSource _remoteDataSource;

  OrdersRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, List<OrderModel>>> getOrders({int page = 1, int limit = 20}) async {
    try {
      final result = await _remoteDataSource.getOrders(page: page, limit: limit);
      return Right(result);
    } on ApiException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
