import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:tax_client/core/common/widgets/bottom_nav_bar.dart';
import 'package:tax_client/core/common/widgets/core_scaffold.dart';
import 'package:tax_client/core/common/widgets/custom_card.dart';
import 'package:tax_client/core/common/widgets/primary_button.dart';
import 'package:tax_client/core/config/strings/app_strings.dart';
import 'package:tax_client/core/config/theme/app_colors.dart';
import 'package:tax_client/core/config/theme/app_spacing.dart';
import 'package:tax_client/features/orders/data/models/order_model.dart';
import 'package:tax_client/features/orders/presentation/viewmodel/orders_view_model.dart';
import 'package:tax_client/features/personal_info/data/models/itr_personal_detail_model.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ordersViewModelProvider.notifier).fetchOrders();
    });
  }

  void _openOrderStatus(BuildContext context, OrderModel order) {
    final itrData = ItrPersonalDetailModel(
      id: order.orderId ?? '',
      itrId: order.itrId?.toString() ?? '',
      userId: '0',
      panNumber: order.panNumber ?? '',
      firstName: order.firstName ?? order.fullName ?? 'Order',
      lastName: order.lastName ?? (order.orderId ?? ''),
      email: order.email ?? '',
      mobileNumber: order.mobile ?? '',
      aadharCardNumber: '',
      gender: '',
      financialYear: order.financialYear ?? 'N/A',
      address: '',
      country: '',
      isActive: '1',
      createdAt: order.createdAt ?? '',
    );
    context.push('/status', extra: itrData);
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(ordersViewModelProvider);

    final orderCount = ordersState.maybeWhen(
      loaded: (orders) => orders.length,
      orElse: () => null,
    );

    return CoreScaffold(
      includeAppBar: false,
      backgroundColor: AppColors.authBackground,
      useScrollView: false,
      centered: true,
      useResponsiveMaxWidth: true,
      maxContentWidth: 560,
      padding: EdgeInsets.zero,
      bottomNavigationBar: const BottomNavBar(),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _OrdersHeader(),
            const SizedBox(height: AppSpacing.xl),
            _OrdersHeroCard(orderCount: orderCount),
            const SizedBox(height: AppSpacing.xl),
            Expanded(
              child: ordersState.when(
                initial: () => const _OrdersLoadingState(),
                loading: () => const _OrdersLoadingState(),
                error: (message) => _OrdersErrorState(
                  message: message,
                  onRetry: () =>
                      ref.read(ordersViewModelProvider.notifier).fetchOrders(),
                ),
                loaded: (orders) {
                  if (orders.isEmpty) {
                    return const _OrdersEmptyState();
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return _OrderCard(
                        order: order,
                        onView: () => _openOrderStatus(context, order),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersHeader extends StatelessWidget {
  const _OrdersHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.orders,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: AppColors.authHeading,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Track payments, review filing activity, and open any order in progress.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.authMuted,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _OrdersHeroCard extends StatelessWidget {
  final int? orderCount;

  const _OrdersHeroCard({required this.orderCount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final countLabel = orderCount == null
        ? 'Loading orders'
        : orderCount == 0
        ? 'No orders yet'
        : '$orderCount order${orderCount == 1 ? '' : 's'} available';

    return CustomCard(
      backgroundColor: AppColors.authCardSurface,
      border: Border.all(color: AppColors.authCardBorder),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'All your filing orders in one place',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppColors.authHeading,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Review payment status, package details, and open an order to see the current filing progress.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.authMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _OrdersChip(
                icon: Icons.receipt_long_outlined,
                label: countLabel,
                accent: AppColors.authMint,
              ),
              const _OrdersChip(
                icon: Icons.verified_user_outlined,
                label: 'Status updates stay linked',
                accent: AppColors.authAmber,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrdersChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;

  const _OrdersChip({
    required this.icon,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.authHeading,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdersLoadingState extends StatelessWidget {
  const _OrdersLoadingState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.authMint),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Loading your orders...',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.authHeading,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Preparing payment and filing history.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.authMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdersErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _OrdersErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: CustomCard(
        backgroundColor: const Color(0x08FFFFFF),
        border: Border.all(color: AppColors.borderOnDark),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.authAmber.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AppColors.authAmber,
                size: 30,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Unable to load orders',
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.authHeading,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.authMuted,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                text: 'RETRY',
                onPressed: onRetry,
                borderRadius: AppSpacing.radiusPill,
                foregroundColor: AppColors.authButtonText,
                gradient: const LinearGradient(
                  colors: [AppColors.authMint, AppColors.authMintDark],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersEmptyState extends StatelessWidget {
  const _OrdersEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: CustomCard(
        backgroundColor: const Color(0x08FFFFFF),
        border: Border.all(color: AppColors.borderOnDark),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.authMuted.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: AppColors.authMuted,
                size: 30,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No orders found',
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.authHeading,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Your filing and payment orders will appear here once they are created.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.authMuted,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onView;

  const _OrderCard({required this.order, required this.onView});

  String _displayName() {
    final fullName = (order.fullName ?? '').trim();
    if (fullName.isNotEmpty) return fullName;
    final nameParts = [
      order.firstName ?? '',
      order.lastName ?? '',
    ].where((part) => part.trim().isNotEmpty).join(' ');
    return nameParts.isNotEmpty ? nameParts : 'Order';
  }

  String _formatDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Date unavailable';
    }
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(value));
    } catch (_) {
      return value;
    }
  }

  ({Color background, Color foreground}) _statusColors(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
        return (
          background: AppColors.success.withValues(alpha: 0.16),
          foreground: AppColors.success,
        );
      case 'processing':
      case 'pending':
        return (
          background: AppColors.authAmber.withValues(alpha: 0.16),
          foreground: AppColors.authAmber,
        );
      default:
        return (
          background: AppColors.error.withValues(alpha: 0.16),
          foreground: AppColors.error,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amount = order.amount?.grandTotal ?? order.packagePrice ?? 0;
    final status = (order.status ?? 'Pending').trim();
    final statusColors = _statusColors(status);

    return CustomCard(
      padding: EdgeInsets.zero,
      backgroundColor: const Color(0x08FFFFFF),
      border: Border.all(color: AppColors.borderOnDark),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          onTap: onView,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.orderId ?? 'N/A',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: AppColors.authHeading,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            _displayName(),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.authMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: statusColors.background,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusPill,
                        ),
                      ),
                      child: Text(
                        status,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: statusColors.foreground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    if ((order.packageName ?? '').trim().isNotEmpty)
                      _OrderMetaChip(
                        icon: Icons.inventory_2_outlined,
                        label: order.packageName!,
                      ),
                    if ((order.financialYear ?? '').trim().isNotEmpty)
                      _OrderMetaChip(
                        icon: Icons.calendar_today_outlined,
                        label: order.financialYear!,
                      ),
                    if ((order.paymentMethod ?? '').trim().isNotEmpty)
                      _OrderMetaChip(
                        icon: Icons.payments_outlined,
                        label: order.paymentMethod!,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: _OrderInfoTile(
                        icon: Icons.calendar_today_outlined,
                        label: AppStrings.date,
                        value: _formatDate(order.createdAt),
                        accent: AppColors.authHeading,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _OrderInfoTile(
                        icon: Icons.currency_rupee_rounded,
                        label: AppStrings.amount,
                        value: '₹${amount.toStringAsFixed(0)}',
                        accent: AppColors.authMint,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Open this order to review the current filing status and payment progress.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.authMuted,
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      AppStrings.view,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.authMint,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderMetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _OrderMetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantDark.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.authMuted),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.authHeading,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const _OrderInfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: accent.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, size: 16, color: accent),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.authMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.authHeading,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
