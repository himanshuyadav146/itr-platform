import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tax_client/core/common/widgets/core_scaffold.dart';
import 'package:tax_client/core/common/widgets/custom_card.dart';
import 'package:tax_client/core/common/widgets/primary_button.dart';
import 'package:tax_client/core/config/strings/app_strings.dart';
import 'package:tax_client/core/config/theme/app_colors.dart';
import 'package:tax_client/core/config/theme/app_spacing.dart';
import 'package:tax_client/core/network/token_storage.dart';
import 'package:tax_client/core/payments/razorpay_service.dart';
import 'package:tax_client/features/packages/presentation/providers/package_provider.dart';
import 'package:tax_client/features/payment/data/datasources/payment_remote_data_source.dart';
import 'package:tax_client/features/payment/data/models/payment_info_data.dart';
import 'package:tax_client/features/payment/data/models/payment_initiate_response.dart';
import 'package:tax_client/features/payment/data/models/payment_summary_item.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final int packageId;

  const PaymentScreen({super.key, this.packageId = 1});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen>
    with SingleTickerProviderStateMixin {
  PaymentInfoData? paymentInfo;
  bool isLoading = true;
  String? errorMessage;

  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _fade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
    _fetchPaymentInfo();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _fetchPaymentInfo() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final dataSource = ref.read(paymentRemoteDataSourceProvider);
      final info = await dataSource.getPaymentInfo(widget.packageId);

      if (!mounted) return;
      setState(() {
        paymentInfo = info;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
      _showMessage('Failed to load payment information: $e');
    }
  }

  Future<void> _handlePaymentStatus({
    required String? orderId,
    required String paymentStatus,
    String? transactionId,
    String? paymentMethod,
    String? failureReason,
    Map<String, dynamic>? gatewayResponse,
  }) async {
    try {
      if (orderId == null) {
        debugPrint('Cannot verify payment: orderId is null');
        return;
      }

      final dataSource = ref.read(paymentRemoteDataSourceProvider);
      await dataSource.verifyPayment(
        orderId: orderId,
        paymentStatus: paymentStatus,
        transactionId: transactionId,
        paymentMethod: paymentMethod,
        gatewayName: 'razorpay',
        failureReason: failureReason,
        gatewayResponse: gatewayResponse,
      );
    } catch (e) {
      debugPrint('Error verifying payment status: $e');
    }
  }

  Future<void> _startPayment() async {
    final info = paymentInfo;
    if (info == null) return;

    final router = GoRouter.of(context);

    try {
      setState(() {
        isLoading = true;
      });

      final tokenStorage = ref.read(tokenStorageProvider);
      final panNumber = await tokenStorage.getPanNumber();

      if (panNumber == null || panNumber.isEmpty) {
        if (!mounted) return;
        setState(() {
          isLoading = false;
        });
        _showMessage(
          'PAN number not found. Please complete personal information first.',
        );
        return;
      }

      final dataSource = ref.read(paymentRemoteDataSourceProvider);
      late final PaymentInitiateResponse initiateResponse;

      try {
        initiateResponse = await dataSource.initiatePayment(
          packageId: widget.packageId,
          panNumber: panNumber,
        );
      } catch (e) {
        if (!mounted) return;
        setState(() {
          isLoading = false;
        });
        _showMessage('Failed to initiate payment: $e');
        return;
      }

      if (!mounted) return;
      setState(() {
        isLoading = false;
      });

      RazorpayService.openCheckout(
        paymentInfo: info,
        initiateResponse: initiateResponse,
        onSuccess: (response) async {
          final paymentId = response['payment_id'] as String?;
          final orderId = response['order_id'] as String?;
          final signature = response['signature'] as String?;
          final finalOrderId = orderId ?? initiateResponse.orderId;

          final gatewayResponse = <String, dynamic>{
            'razorpay_payment_id': paymentId,
            'razorpay_order_id': finalOrderId,
            if (signature != null) 'razorpay_signature': signature,
          };

          await _handlePaymentStatus(
            orderId: finalOrderId,
            paymentStatus: response['status'],
            transactionId: paymentId,
            paymentMethod: 'card',
            gatewayResponse: gatewayResponse,
          );

          if (!mounted) return;
          router.go('/status', extra: {'orderId': finalOrderId});
        },
        onError: (response) async {
          final orderId = initiateResponse.orderId;
          final paymentFailureMessage = response['message'] as String?;
          final errorCode = response['code'] as String?;

          final gatewayResponse = <String, dynamic>{
            if (errorCode != null) 'error_code': errorCode,
            if (paymentFailureMessage != null)
              'error_message': paymentFailureMessage,
          };

          await _handlePaymentStatus(
            orderId: orderId,
            paymentStatus: 'failed',
            failureReason: paymentFailureMessage ?? 'Payment failed',
            gatewayResponse: gatewayResponse,
          );

          _showMessage(
            paymentFailureMessage ?? 'Payment failed. Please try again.',
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      _showMessage('Invalid payment information: $e');
    }
  }

  PaymentSummaryItem? get _grandTotalItem {
    final info = paymentInfo;
    if (info == null) return null;

    for (final item in info.paymentSummary) {
      if (item.type == 'grand_total') {
        return item;
      }
    }
    return null;
  }

  List<PaymentSummaryItem> get _regularSummaryItems {
    final info = paymentInfo;
    if (info == null) return const [];
    return info.paymentSummary
        .where((item) => item.type != 'grand_total')
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedPackage = ref.watch(selectedPackageProvider);
    final info = paymentInfo;
    final grandTotal = _grandTotalItem;
    final regularItems = _regularSummaryItems;
    final packageLabel =
        selectedPackage?.name ?? 'Package #${widget.packageId}';

    return CoreScaffold(
      includeAppBar: false,
      backgroundColor: AppColors.authBackground,
      useScrollView: true,
      centered: false,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        120,
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        child: SizedBox(
          height: 56,
          child: PrimaryButton(
            text: 'PAY NOW',
            isLoading: isLoading,
            onPressed: info == null || errorMessage != null
                ? null
                : _startPayment,
            borderRadius: AppSpacing.radiusPill,
            foregroundColor: AppColors.authButtonText,
            textStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [AppColors.authMint, AppColors.authMintDark],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x334EDEA3),
                blurRadius: 20,
                spreadRadius: -6,
                offset: Offset(0, 10),
              ),
            ],
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Builder(
            builder: (context) {
              if (isLoading && info == null) {
                return const _PaymentLoadingState();
              }

              if (errorMessage != null) {
                return _PaymentErrorState(onRetry: _fetchPaymentInfo);
              }

              if (info == null) {
                return const _PaymentEmptyState();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PaymentHeader(
                    onBack: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/');
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _PaymentHeroCard(
                    packageLabel: packageLabel,
                    amountLabel:
                        grandTotal?.displayValue ??
                        regularItems.last.displayValue,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _PaymentSectionCard(
                    title: 'Payer details',
                    subtitle:
                        'This information is attached to the order created for your filing.',
                    child: Column(
                      children: [
                        _PaymentDetailRow(
                          label: 'Name',
                          value: info.orderDetails.name,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _PaymentDetailRow(
                          label: 'Phone',
                          value: info.orderDetails.phone,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _PaymentDetailRow(
                          label: 'Email',
                          value: info.orderDetails.email,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _PaymentSectionCard(
                    title: 'Payment summary',
                    subtitle:
                        'Review the charges before continuing to the Razorpay checkout.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (
                          var index = 0;
                          index < regularItems.length;
                          index++
                        ) ...[
                          _PaymentSummaryRow(
                            label: regularItems[index].displayTitle,
                            value: regularItems[index].displayValue,
                            highlight: regularItems[index].type == 'subtotal',
                          ),
                          if (index != regularItems.length - 1)
                            const SizedBox(height: AppSpacing.sm),
                        ],
                        if (grandTotal != null) ...[
                          const SizedBox(height: AppSpacing.lg),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: AppColors.authMint.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusLg,
                              ),
                              border: Border.all(
                                color: AppColors.authMint.withValues(
                                  alpha: 0.18,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.grandTotal,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: AppColors.authHeading,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  grandTotal.displayValue,
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        color: AppColors.authMint,
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          AppStrings.amountNote,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.authMuted,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _PaymentSectionCard(
                    title: 'Secure checkout',
                    subtitle:
                        'Your payment is processed through Razorpay and verified before the filing moves forward.',
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.authAmber.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusLg,
                            ),
                          ),
                          child: const Icon(
                            Icons.lock_outline_rounded,
                            color: AppColors.authAmber,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            'Your payment is processed securely through Razorpay, and we will automatically take you to order status after a successful payment.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.authMuted,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PaymentHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _PaymentHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surfaceVariantDark,
            foregroundColor: AppColors.authHeading,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.payment,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.authHeading,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Review the amount and complete payment securely.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.authMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaymentHeroCard extends StatelessWidget {
  final String packageLabel;
  final String amountLabel;

  const _PaymentHeroCard({
    required this.packageLabel,
    required this.amountLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomCard(
      backgroundColor: AppColors.authCardSurface,
      border: Border.all(color: AppColors.authCardBorder),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ready to complete your filing payment',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppColors.authHeading,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Confirm the selected plan and continue to the secure Razorpay checkout to activate the next step.',
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
              _PaymentChip(
                icon: Icons.inventory_2_outlined,
                label: packageLabel,
                accent: AppColors.authMint,
              ),
              _PaymentChip(
                icon: Icons.payments_outlined,
                label: amountLabel,
                accent: AppColors.authAmber,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentSectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _PaymentSectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomCard(
      backgroundColor: const Color(0x08FFFFFF),
      border: Border.all(color: AppColors.borderOnDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppColors.authHeading,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.authMuted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

class _PaymentDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _PaymentDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantDark.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.authMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.authHeading,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentSummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _PaymentSummaryRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.authAmber.withValues(alpha: 0.1)
            : AppColors.surfaceVariantDark.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.authHeading,
                fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: highlight ? AppColors.authAmber : AppColors.authHeading,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;

  const _PaymentChip({
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

class _PaymentLoadingState extends StatelessWidget {
  const _PaymentLoadingState();

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
            'Loading payment details...',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.authHeading,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Preparing your checkout summary.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.authMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _PaymentErrorState({required this.onRetry});

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
              'Error loading payment information',
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.authHeading,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Please retry to reload the checkout details.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.authMuted,
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

class _PaymentEmptyState extends StatelessWidget {
  const _PaymentEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Text(
        'No payment information available',
        style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.authMuted),
      ),
    );
  }
}
