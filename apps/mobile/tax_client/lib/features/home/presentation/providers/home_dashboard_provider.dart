import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tax_client/core/network/token_storage.dart';
import 'package:tax_client/features/orders/data/models/order_model.dart';
import 'package:tax_client/features/orders/domain/usecases/get_orders.dart';
import 'package:tax_client/features/personal_info/data/models/get_itr_by_user_data.dart';
import 'package:tax_client/features/personal_info/data/models/itr_personal_detail_model.dart';
import 'package:tax_client/features/personal_info/domain/usecases/get_itr_by_user.dart';
import 'package:tax_client/features/personal_info/presentation/providers/personal_info_provider.dart';
import 'package:tax_client/features/status/data/models/itr_detailed_status_model.dart';
import 'package:tax_client/features/status/domain/usecases/get_detailed_status.dart';

final homeDashboardSnapshotProvider =
    FutureProvider<HomeDashboardSnapshot>((ref) async {
  final tokenStorage = ref.read(tokenStorageProvider);
  final userId = await tokenStorage.getUserId();

  if (userId == null || userId.isEmpty) {
    return const HomeDashboardSnapshot();
  }

  final getOrders = ref.read(getOrdersProvider);
  final getItrByUser = ref.read(getItrByUserProvider);
  final getDetailedStatus = ref.read(getDetailedStatusProvider);

  final orders = await _loadOrders(getOrders);
  final filings = await _loadItrs(getItrByUser, userId);

  final activeDraft = _pickActiveDraft(filings);
  final activeOrder = _pickActiveOrder(orders, activeDraft);
  final status = await _loadStatus(getDetailedStatus, activeOrder, activeDraft);

  return HomeDashboardSnapshot(
    userId: userId,
    orders: orders,
    filings: filings,
    activeDraft: activeDraft,
    activeOrder: activeOrder,
    activeStatus: status,
  );
});

class HomeDashboardSnapshot {
  final String? userId;
  final List<OrderModel> orders;
  final List<ItrPersonalDetailModel> filings;
  final ItrPersonalDetailModel? activeDraft;
  final OrderModel? activeOrder;
  final ItrDetailedStatusModel? activeStatus;

  const HomeDashboardSnapshot({
    this.userId,
    this.orders = const [],
    this.filings = const [],
    this.activeDraft,
    this.activeOrder,
    this.activeStatus,
  });

  bool get hasWorkspace =>
      activeDraft != null || activeOrder != null || filings.isNotEmpty;

  int get unresolvedConcernsCount {
    final updates = activeStatus?.statusUpdates ?? const <StatusUpdateModel>[];
    return updates.where(_isUrgentStatusUpdate).length;
  }

  List<StatusUpdateModel> get urgentUpdates {
    final updates = activeStatus?.statusUpdates ?? const <StatusUpdateModel>[];
    return updates.where(_isUrgentStatusUpdate).take(2).toList();
  }
}

Future<List<OrderModel>> _loadOrders(GetOrders getOrders) async {
  final result = await getOrders(page: 1, limit: 20);

  return result.fold(
    (_) => <OrderModel>[],
    (orders) {
      final sorted = [...orders];
      sorted.sort((a, b) => _compareDates(b.paidAt ?? b.createdAt, a.paidAt ?? a.createdAt));
      return sorted;
    },
  );
}

Future<List<ItrPersonalDetailModel>> _loadItrs(
  GetItrByUser getItrByUser,
  String userId,
) async {
  final result = await getItrByUser(GetItrByUserParams(userId: userId));

  return result.fold(
    (_) => <ItrPersonalDetailModel>[],
    (GetItrByUserData data) {
      final sorted = [...data.personalDetails];
      sorted.sort((a, b) => _compareDates(b.createdAt, a.createdAt));
      return sorted;
    },
  );
}

Future<ItrDetailedStatusModel?> _loadStatus(
  GetDetailedStatus getDetailedStatus,
  OrderModel? activeOrder,
  ItrPersonalDetailModel? activeDraft,
) async {
  final orderId = activeOrder?.orderId;
  final itrId = activeDraft?.itrId ?? activeOrder?.itrId?.toString();

  if (orderId == null || orderId.isEmpty || itrId == null || itrId.isEmpty) {
    return null;
  }

  final result = await getDetailedStatus(orderId, itrId);
  return result.fold((_) => null, (status) => status);
}

ItrPersonalDetailModel? _pickActiveDraft(List<ItrPersonalDetailModel> filings) {
  for (final filing in filings) {
    if (!_isCompletedFiling(filing)) {
      return filing;
    }
  }
  return null;
}

OrderModel? _pickActiveOrder(
  List<OrderModel> orders,
  ItrPersonalDetailModel? activeDraft,
) {
  if (activeDraft?.itrId != null && activeDraft!.itrId!.isNotEmpty) {
    for (final order in orders) {
      if (order.itrId?.toString() == activeDraft.itrId) {
        return order;
      }
    }
  }

  for (final order in orders) {
    if (!_isFailedOrder(order)) {
      return order;
    }
  }

  return null;
}

bool _isCompletedFiling(ItrPersonalDetailModel filing) {
  final paymentStatus = (filing.paymentStatus ?? '').trim().toLowerCase();
  final itrStatus = (filing.itrStatus ?? '').trim().toLowerCase();

  if (paymentStatus == 'success') {
    return itrStatus.isEmpty ||
        itrStatus == 'completed' ||
        itrStatus == 'filed' ||
        itrStatus == 'delivered';
  }

  return false;
}

bool _isFailedOrder(OrderModel order) {
  final status = (order.status ?? '').trim().toLowerCase();
  return status == 'failed' || status == 'cancelled' || status == 'canceled';
}

bool _isUrgentStatusUpdate(StatusUpdateModel update) {
  final status = (update.status ?? '').trim().toLowerCase();
  final message = (update.message ?? '').trim().toLowerCase();

  if (update.resolvedAt == null && update.message != null && update.message!.trim().isNotEmpty) {
    return true;
  }

  return status.contains('pending') ||
      status.contains('concern') ||
      status.contains('missing') ||
      message.contains('missing') ||
      message.contains('action') ||
      message.contains('upload') ||
      message.contains('required');
}

int _compareDates(String? a, String? b) {
  final first = _tryParseDate(a);
  final second = _tryParseDate(b);

  if (first == null && second == null) return 0;
  if (first == null) return -1;
  if (second == null) return 1;
  return first.compareTo(second);
}

DateTime? _tryParseDate(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }

  return DateTime.tryParse(value);
}
