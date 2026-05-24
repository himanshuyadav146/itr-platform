import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tax_client/features/orders/data/models/order_model.dart';

part 'orders_state.freezed.dart';

@freezed
class OrdersState with _$OrdersState {
  const factory OrdersState.initial() = OrdersInitial;
  const factory OrdersState.loading() = OrdersLoading;
  const factory OrdersState.loaded(List<OrderModel> orders) = OrdersLoaded;
  const factory OrdersState.error(String message) = OrdersError;
}
