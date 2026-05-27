import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tax_client/core/network/token_storage.dart';
import 'package:tax_client/features/home/domain/dashboard_mode.dart';
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

  final focus = _resolveDashboardFocus(filings, orders);

  ItrDetailedStatusModel? status;
  if (focus.mode == DashboardMode.postPayment && focus.focusItr != null) {
    status = await _loadStatus(
      getDetailedStatus,
      focus.focusOrder,
      focus.focusItr!,
    );
  }

  return HomeDashboardSnapshot(
    userId: userId,
    orders: orders,
    filings: filings,
    mode: focus.mode,
    focusItr: focus.focusItr,
    focusOrder: focus.focusOrder,
    activeStatus: status,
  );
});

class _DashboardFocus {
  final DashboardMode mode;
  final ItrPersonalDetailModel? focusItr;
  final OrderModel? focusOrder;

  const _DashboardFocus({
    required this.mode,
    this.focusItr,
    this.focusOrder,
  });
}

class HomeDashboardSnapshot {
  final String? userId;
  final List<OrderModel> orders;
  final List<ItrPersonalDetailModel> filings;
  final DashboardMode mode;
  final ItrPersonalDetailModel? focusItr;
  final OrderModel? focusOrder;
  final ItrDetailedStatusModel? activeStatus;

  const HomeDashboardSnapshot({
    this.userId,
    this.orders = const [],
    this.filings = const [],
    this.mode = DashboardMode.none,
    this.focusItr,
    this.focusOrder,
    this.activeStatus,
  });

  /// Backward-compatible aliases used across the home screen helpers.
  ItrPersonalDetailModel? get activeDraft => focusItr;

  OrderModel? get activeOrder => focusOrder;

  bool get hasWorkspace =>
      mode != DashboardMode.none ||
      focusItr != null ||
      focusOrder != null ||
      filings.isNotEmpty;

  bool get showPendingPayment => mode == DashboardMode.prePayment;

  bool get showLiveTracking => mode == DashboardMode.postPayment;

  bool get showCriticalActions =>
      showLiveTracking && pendingActions.isNotEmpty;

  int get pendingActionsCount => pendingActions.length;

  List<DashboardActionItem> get pendingActions {
    if (!showLiveTracking || activeStatus == null) {
      return const [];
    }

    final expertName =
        activeStatus!.assignmentStatus?.professionalName?.trim().isNotEmpty ==
                true
            ? activeStatus!.assignmentStatus!.professionalName!.trim()
            : 'Tax Expert';

    final items = <DashboardActionItem>[];
    final seenMessages = <String>{};

    for (final update in activeStatus!.statusUpdates ?? const []) {
      if (!_isPendingStatusUpdate(update)) {
        continue;
      }
      final item = DashboardActionItem.fromStatusUpdate(
        id: update.id,
        message: update.message,
        status: update.status,
        createdAt: update.createdAt,
        expertName: expertName,
      );
      if (seenMessages.add(item.message)) {
        items.add(item);
      }
    }

    for (final step in activeStatus!.itrStatus?.steps ?? const []) {
      if (step.hasConcern != true) {
        continue;
      }
      final item = DashboardActionItem.fromStepConcern(
        stepTitle: step.title ?? step.step ?? 'Filing step',
        concernText: step.concern ?? step.notes,
        expertName: expertName,
      );
      if (seenMessages.add(item.message)) {
        items.add(item);
      }
    }

    return items;
  }

  /// True when at least one filing has a PAN (filings are sorted newest first).
  bool get hasDocumentVaultAccess =>
      filings.any((filing) => filing.panNumber.trim().isNotEmpty);

  /// Filing used for document vault — focus ITR when available, else newest with PAN.
  ItrPersonalDetailModel? get documentVaultItr {
    if (focusItr != null && focusItr!.panNumber.trim().isNotEmpty) {
      return focusItr;
    }
    for (final filing in filings) {
      if (filing.panNumber.trim().isNotEmpty) {
        return filing;
      }
    }
    return null;
  }
}

_DashboardFocus _resolveDashboardFocus(
  List<ItrPersonalDetailModel> filings,
  List<OrderModel> orders,
) {
  if (filings.isEmpty) {
    return const _DashboardFocus(mode: DashboardMode.none);
  }

  final newest = filings.first;

  if (_hasPaymentSuccess(newest)) {
    return _DashboardFocus(
      mode: DashboardMode.postPayment,
      focusItr: newest,
      focusOrder: _findOrderForItr(orders, newest),
    );
  }

  // Newest ITR is unpaid — pending payment UI (even if older paid ITRs exist).
  return _DashboardFocus(
    mode: DashboardMode.prePayment,
    focusItr: newest,
    focusOrder: null,
  );
}

OrderModel? _findOrderForItr(
  List<OrderModel> orders,
  ItrPersonalDetailModel itr,
) {
  final itrId = itr.itrId;
  if (itrId == null || itrId.isEmpty) {
    return null;
  }

  for (final order in orders) {
    if (order.itrId?.toString() == itrId) {
      return order;
    }
  }
  return null;
}

bool _hasPaymentSuccess(ItrPersonalDetailModel filing) {
  return (filing.paymentStatus ?? '').trim().toLowerCase() == 'success';
}

Future<List<OrderModel>> _loadOrders(GetOrders getOrders) async {
  final result = await getOrders(page: 1, limit: 20);

  return result.fold(
    (_) => <OrderModel>[],
    (orders) {
      final sorted = [...orders];
      sorted.sort(
        (a, b) => _compareDates(b.paidAt ?? b.createdAt, a.paidAt ?? a.createdAt),
      );
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
  OrderModel? focusOrder,
  ItrPersonalDetailModel focusItr,
) async {
  final itrId = focusItr.itrId;
  if (itrId == null || itrId.isEmpty) {
    return null;
  }

  final orderId = focusOrder?.orderId ?? '';
  final result = await getDetailedStatus(orderId, itrId);
  return result.fold((_) => null, (status) => status);
}

bool _isPendingStatusUpdate(StatusUpdateModel update) {
  final status = (update.status ?? '').trim().toLowerCase();
  if (update.resolvedAt != null && update.resolvedAt!.trim().isNotEmpty) {
    return false;
  }
  if (status == 'resolved' || status == 'closed') {
    return false;
  }
  return update.message != null && update.message!.trim().isNotEmpty;
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
