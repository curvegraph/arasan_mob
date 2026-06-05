import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/user_order_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/order.dart';
import '../../auth/screens/login_dialog.dart';
import 'package:intl/intl.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Orders'),
        centerTitle: false,
      ),
      body: Consumer2<AuthProvider, UserOrderProvider>(
        builder: (context, auth, orderProvider, _) {
          if (!auth.isLoggedIn) {
            return _buildLoginPrompt(context);
          }

          if (orderProvider.allOrders.isEmpty) {
            return _buildEmptyOrders(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orderProvider.allOrders.length,
            itemBuilder: (context, index) {
              return _OrderCard(order: orderProvider.allOrders[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: AppColors.textHint.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 24),
          const Text(
            'Login to view your orders',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Track your orders and view order history',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => LoginDialog.show(context),
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyOrders(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 100,
            color: AppColors.textHint.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 24),
          const Text(
            'No orders yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your orders will appear here',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => context.go('/shop'),
            child: const Text('Start Shopping'),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => context.push('/shop/account/orders/${order.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.orderNumber}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM dd, yyyy').format(order.createdAt),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  _buildStatusBadge(order.status),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              // Order items preview
              ...order.items.take(3).map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: item.imageUrl.isNotEmpty
                          ? Image.network(
                              item.imageUrl,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 50,
                                height: 50,
                                color: AppColors.background,
                                child: const Icon(Icons.image, size: 20),
                              ),
                            )
                          : Container(
                              width: 50,
                              height: 50,
                              color: AppColors.background,
                              child: const Icon(Icons.image, size: 20),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.productName,
                        style: const TextStyle(fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      'x${item.quantity}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )),
              if (order.items.length > 3)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '+${order.items.length - 3} more items',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${order.itemCount} items',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  Text(
                    CurrencyFormatter.format(order.totalAmount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              if (order.trackingId != null && (order.status == OrderStatus.shipped || order.status == OrderStatus.outForDelivery)) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_shipping_outlined, size: 18, color: AppColors.info),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tracking: ${order.trackingId}',
                          style: const TextStyle(
                            color: AppColors.info,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.info),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(OrderStatus status) {
    Color color;
    String text;

    switch (status) {
      case OrderStatus.pending:
        color = AppColors.warning;
        text = 'Pending';
        break;
      case OrderStatus.confirmed:
        color = AppColors.info;
        text = 'Confirmed';
        break;
      case OrderStatus.shipped:
        color = AppColors.primary;
        text = 'Shipped';
        break;
      case OrderStatus.outForDelivery:
        color = Colors.purple;
        text = 'Out for Delivery';
        break;
      case OrderStatus.delivered:
        color = AppColors.success;
        text = 'Delivered';
        break;
      case OrderStatus.cancelled:
        color = AppColors.error;
        text = 'Cancelled';
        break;
      case OrderStatus.returned:
        color = AppColors.warning;
        text = 'Returned';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
