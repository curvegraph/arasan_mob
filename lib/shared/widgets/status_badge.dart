import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/order.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
  });

  factory StatusBadge.fromOrderStatus(OrderStatus status) {
    Color color;
    switch (status) {
      case OrderStatus.pending:
        color = AppColors.warning;
      case OrderStatus.confirmed:
        color = AppColors.info;
      case OrderStatus.shipped:
        color = AppColors.userPrimary;
      case OrderStatus.outForDelivery:
        color = AppColors.info;
      case OrderStatus.delivered:
        color = AppColors.success;
      case OrderStatus.cancelled:
        color = AppColors.error;
      case OrderStatus.returned:
        color = Colors.deepOrange;
      case OrderStatus.outForDelivery:
        color = AppColors.userPrimary;
    }
    return StatusBadge(label: status.name.toUpperCase(), color: color);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
