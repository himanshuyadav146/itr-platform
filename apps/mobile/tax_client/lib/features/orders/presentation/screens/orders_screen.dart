import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tax_client/core/common/widgets/core_scaffold.dart';
import 'package:tax_client/core/config/strings/app_strings.dart';
import 'package:tax_client/core/common/widgets/bottom_nav_bar.dart';
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

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(ordersViewModelProvider);

    return CoreScaffold(
      title: AppStrings.orders,
      useScrollView: false,
      centered: false,
      bottomNavigationBar: const BottomNavBar(),
      body: ordersState.when(
        initial: () => const SizedBox.shrink(),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (message) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(message),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(ordersViewModelProvider.notifier).fetchOrders(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        loaded: (orders) {
          if (orders.isEmpty) {
            return const Center(child: Text('No orders found'));
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final o = orders[index];

              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Section: Order ID (Full Width)
                    Row(
                      children: [
                        const Icon(Icons.receipt_long_outlined,
                            size: 20, color: Colors.blue),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            o.orderId ?? 'N/A',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            softWrap: true,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, thickness: 0.5),

                    // Bottom Section: Details, Amount, and View
                    Row(
                      children: [
                        // Details: Date and Status
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today_outlined,
                                      size: 16, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      o.createdAt != null 
                                          ? "${AppStrings.date}: ${DateFormat('dd-MM-yyyy').format(DateTime.parse(o.createdAt!))}"
                                          : "N/A",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: Colors.grey[700]),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _statusBadge(context, o.status ?? 'Pending'),
                            ],
                          ),
                        ),

                        // Amount and View Button
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "₹${o.amount?.grandTotal?.toStringAsFixed(0) ?? '0'}",
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                // Create a dummy ItrPersonalDetailModel to pass the orderId to StatusScreen
                                final itrData = ItrPersonalDetailModel(
                                  id: o.orderId ?? '',
                                  itrId: o.itrId?.toString() ?? '',
                                  userId: '0',
                                  panNumber: o.panNumber ?? '',
                                  firstName: o.firstName ?? 'Order',
                                  lastName: o.lastName ?? (o.orderId ?? ''),
                                  email: o.email ?? '',
                                  mobileNumber: o.mobile ?? '',
                                  aadharCardNumber: '',
                                  gender: '',
                                  financialYear: o.financialYear ?? 'N/A',
                                  address: '',
                                  country: '',
                                  isActive: '1',
                                  createdAt: o.createdAt ?? '',
                                );
                                context.push('/status', extra: itrData);
                              },
                              child: Text(
                                AppStrings.view,
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _statusBadge(BuildContext context, String status) {
    Color color;

    switch (status.toLowerCase()) {
      case "completed":
      case "success":
        color = Colors.green.shade100;
        break;
      case "processing":
      case "pending":
        color = Colors.orange.shade100;
        break;
      default:
        color = Colors.red.shade100;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}