import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tax_client/core/common/widgets/core_scaffold.dart';
import 'package:tax_client/core/common/widgets/primary_button.dart';
import 'package:tax_client/core/config/strings/app_strings.dart';
import 'package:tax_client/core/payments/razorpay_service.dart';
import 'package:tax_client/core/network/token_storage.dart';
import 'package:tax_client/features/payment/data/datasources/payment_remote_data_source.dart';
import 'package:tax_client/features/payment/data/models/payment_info_data.dart';
import 'package:tax_client/features/payment/data/models/payment_initiate_response.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final int packageId;
  
  const PaymentScreen({
    super.key,
    this.packageId = 1,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen>
    with SingleTickerProviderStateMixin {
  bool eVerification = true;
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
    
    // Fetch payment info
    _fetchPaymentInfo();
  }

  Future<void> _fetchPaymentInfo() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final dataSource = ref.read(paymentRemoteDataSourceProvider);
      final info = await dataSource.getPaymentInfo(widget.packageId);

      if (mounted) {
        setState(() {
          paymentInfo = info;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load payment information: ${e.toString()}'),
          ),
        );
      }
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
      // Payment status has been recorded in the database via API
    } catch (e) {
      // Log error but don't block user navigation
      debugPrint('Error verifying payment status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return CoreScaffold(
      title: AppStrings.payment,
      centered: false,
      useScrollView: false,
      padding: EdgeInsets.zero,
      showBackButton: true,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        child: PrimaryButton(
          text: AppStrings.payNow,
          isLoading: isLoading,
          onPressed: () async {
            if (paymentInfo == null) return;
            
            try {
              setState(() {
                isLoading = true;
              });
              
              // Step 1: Get PAN number from storage
              final tokenStorage = ref.read(tokenStorageProvider);
              final panNumber = await tokenStorage.getPanNumber();
              
              if (panNumber == null || panNumber.isEmpty) {
                if (!mounted) return;
                setState(() {
                  isLoading = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PAN number not found. Please complete personal information first.'),
                  ),
                );
                return;
              }
              
              // Step 2: Initiate payment to get payment_id and order_id
              final dataSource = ref.read(paymentRemoteDataSourceProvider);
              PaymentInitiateResponse? initiateResponse;
              
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to initiate payment: ${e.toString()}'),
                  ),
                );
                return;
              }
              
              if (!mounted) return;
              setState(() {
                isLoading = false;
              });
              
              // Step 2: Open payment gateway with initiate payment response
              RazorpayService.openCheckout(
                paymentInfo: paymentInfo!,
                initiateResponse: initiateResponse,
                onSuccess: (response) async {
                  // Extract payment_id and order_id from Razorpay response
                  final paymentId = response['payment_id'] as String?;
                  final orderId = response['order_id'] as String?;
                  final signature = response['signature'] as String?;
                  
                  // Use order_id from initiate response (more reliable)
                  final finalOrderId = orderId ?? initiateResponse?.orderId;
                  
                  // Build gateway response object
                  final gatewayResponse = <String, dynamic>{
                    'razorpay_payment_id': paymentId,
                    'razorpay_order_id': finalOrderId,
                    if (signature != null) 'razorpay_signature': signature,
                  };
                  
                  // Call API to verify and record payment status
                  await _handlePaymentStatus(
                    orderId: finalOrderId,
                    paymentStatus: response['status'],
                    transactionId: paymentId,
                    paymentMethod: 'card', // Default, can be enhanced based on Razorpay response
                    gatewayResponse: gatewayResponse,
                  );
                  
                  // Check mounted before using context
                  if (!mounted) return;
                  context.go('/status', extra: {'orderId': finalOrderId});
                },
                onError: (response) async {
                  // Use order_id from initiate response
                  final orderId = initiateResponse?.orderId;
                  final errorMessage = response['message'] as String?;
                  final errorCode = response['code'] as String?;
                  
                  // Build gateway response object for error
                  final gatewayResponse = <String, dynamic>{
                    if (errorCode != null) 'error_code': errorCode,
                    if (errorMessage != null) 'error_message': errorMessage,
                  };
                  
                  // Call API to verify and record payment failure
                  await _handlePaymentStatus(
                    orderId: orderId,
                    paymentStatus: 'failed',
                    failureReason: errorMessage ?? 'Payment failed',
                    gatewayResponse: gatewayResponse,
                  );
                  
                  // Check mounted before using context
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        errorMessage ?? 'Payment failed. Please try again.',
                      ),
                    ),
                  );
                },
              );
            } catch (e) {
              // Handle any errors during payment initiation
              if (!mounted) return;
              setState(() {
                isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Invalid payment information: ${e.toString()}'),
                ),
              );
            }
          },
        ),
      ),
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Error loading payment information',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: scheme.error,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _fetchPaymentInfo,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : paymentInfo == null
                      ? const Center(child: Text('No payment information available'))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // User Details Section
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  color: scheme.surface,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  border: Border.all(color: scheme.outlineVariant),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'User Details',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    _buildUserDetailRow('Name', paymentInfo!.orderDetails.name),
                                    const SizedBox(height: 12),
                                    _buildUserDetailRow('Phone', paymentInfo!.orderDetails.phone),
                                    const SizedBox(height: 12),
                                    _buildUserDetailRow('Email', paymentInfo!.orderDetails.email),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              // Main card
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  color: scheme.surface,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  border: Border.all(color: scheme.outlineVariant),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppStrings.paymentSummary,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    ..._buildPaymentSummaryItems(theme, scheme),

                                    const SizedBox(height: 22),

                                    // Text(
                                    //   AppStrings.optionalServices,
                                    //   style: theme.textTheme.titleMedium?.copyWith(
                                    //     fontWeight: FontWeight.w700,
                                    //   ),
                                    // ),

                                    // const SizedBox(height: 10),
                                    //
                                    // GestureDetector(
                                    //   onTap: () {
                                    //     setState(() {
                                    //       eVerification = !eVerification;
                                    //     });
                                    //   },
                                    //   child: AnimatedContainer(
                                    //     duration: const Duration(milliseconds: 250),
                                    //     padding: const EdgeInsets.symmetric(
                                    //       horizontal: 14,
                                    //       vertical: 12,
                                    //     ),
                                    //     decoration: BoxDecoration(
                                    //       borderRadius: BorderRadius.circular(12),
                                    //       color: eVerification
                                    //           ? scheme.primary.withOpacity(0.10)
                                    //           : scheme.surfaceVariant.withOpacity(0.3),
                                    //       border: Border.all(
                                    //         color: eVerification
                                    //             ? scheme.primary
                                    //             : scheme.outlineVariant,
                                    //       ),
                                    //     ),
                                    //     child: Row(
                                    //       children: [
                                    //         AnimatedSwitcher(
                                    //           duration: const Duration(milliseconds: 250),
                                    //           child: eVerification
                                    //               ? Icon(
                                    //                   Icons.check_circle_rounded,
                                    //                   key: const ValueKey(1),
                                    //                   color: scheme.primary,
                                    //                 )
                                    //               : Icon(
                                    //                   Icons.circle_outlined,
                                    //                   key: const ValueKey(2),
                                    //                   color: scheme.onSurface,
                                    //                 ),
                                    //         ),
                                    //         const SizedBox(width: 12),
                                    //         Text(
                                    //           AppStrings.eVerificationFeeFull,
                                    //           style: theme.textTheme.bodyLarge,
                                    //         ),
                                    //       ],
                                    //     ),
                                    //   ),
                                    // ),
                                    //
                                    // const SizedBox(height: 25),

                                    // Text(
                                    //   AppStrings.applyCoupon,
                                    //   style: theme.textTheme.titleMedium?.copyWith(
                                    //     fontWeight: FontWeight.w700,
                                    //   ),
                                    // ),
                                    //
                                    // const SizedBox(height: 12),
                                    //
                                    // Row(
                                    //   children: [
                                    //     Expanded(
                                    //       child: Container(
                                    //         padding: const EdgeInsets.symmetric(
                                    //           horizontal: 14,
                                    //         ),
                                    //         decoration: BoxDecoration(
                                    //           borderRadius: BorderRadius.circular(12),
                                    //           border: Border.all(
                                    //             color: scheme.outlineVariant,
                                    //           ),
                                    //         ),
                                    //         child: TextField(
                                    //           decoration: InputDecoration(
                                    //             hintText: AppStrings.couponHint,
                                    //             border: InputBorder.none,
                                    //           ),
                                    //         ),
                                    //       ),
                                    //     ),
                                    //     const SizedBox(width: 10),
                                    //     Container(
                                    //       padding: const EdgeInsets.symmetric(
                                    //         horizontal: 22,
                                    //         vertical: 14,
                                    //       ),
                                    //       decoration: BoxDecoration(
                                    //         borderRadius: BorderRadius.circular(12),
                                    //         color: scheme.primary.withOpacity(0.12),
                                    //       ),
                                    //       child: Text(
                                    //         AppStrings.apply,
                                    //         style: theme.textTheme.bodyLarge?.copyWith(
                                    //           fontWeight: FontWeight.w600,
                                    //           color: scheme.primary,
                                    //         ),
                                    //       ),
                                    //     ),
                                    //   ],
                                    // ),

                                    const SizedBox(height: 16),
                                    Text(
                                      AppStrings.amountNote,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: scheme.onSurface.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 80),
                            ],
                          ),
                        ),
        ),
      ),
    );
  }

  Widget _buildUserDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPaymentSummaryItems(ThemeData theme, ColorScheme scheme) {
    if (paymentInfo == null) return [];

    final items = <Widget>[];
    bool dividerAdded = false;

    for (int i = 0; i < paymentInfo!.paymentSummary.length; i++) {
      final item = paymentInfo!.paymentSummary[i];
      
      // Add divider before subtotal items
      if (item.type == 'subtotal' && !dividerAdded) {
        items.add(Divider(color: scheme.outline.withOpacity(0.3)));
        dividerAdded = true;
      }

      // Handle grand total separately with special styling
      if (item.type == 'grand_total') {
        items.add(const SizedBox(height: 12));
        items.add(
          Text(
            AppStrings.grandTotal,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        );
        items.add(
          Text(
            item.displayValue,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: scheme.primary,
            ),
          ),
        );
      } else {
        // Regular summary row
        items.add(
          summaryRow(item.displayTitle, item.displayValue),
        );
      }
    }

    return items;
  }

  Widget summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
