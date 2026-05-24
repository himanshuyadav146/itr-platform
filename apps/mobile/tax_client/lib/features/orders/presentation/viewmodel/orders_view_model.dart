import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tax_client/core/error/failures.dart';
import 'package:tax_client/features/orders/domain/usecases/get_orders.dart';
import 'package:tax_client/features/orders/presentation/viewmodel/orders_state.dart';

final ordersViewModelProvider = StateNotifierProvider<OrdersViewModel, OrdersState>((ref) {
  return OrdersViewModel(ref.read(getOrdersProvider));
});

class OrdersViewModel extends StateNotifier<OrdersState> {
  final GetOrders _getOrders;

  OrdersViewModel(this._getOrders) : super(const OrdersInitial());

  Future<void> fetchOrders({int page = 1, int limit = 20}) async {
    state = const OrdersLoading();

    final result = await _getOrders(page: page, limit: limit);

    result.fold(
      (failure) => state = OrdersError(_getErrorMessage(failure)),
      (orders) => state = OrdersLoaded(orders),
    );
  }

  String _getErrorMessage(Failure failure) {
    if (failure is ServerFailure && failure.message != null) {
      return failure.message!;
    }
    return 'Failed to fetch orders. Please try again.';
  }
}
