import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class QuantitySelector extends StatelessWidget {
  final int quantity;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  const QuantitySelector({
    super.key,
    required this.quantity,
    required this.onChanged,
    this.min = 1,
    this.max = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(980),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPillButton(
            icon: Icons.remove,
            onTap: quantity > min ? () => onChanged(quantity - 1) : null,
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 32),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          _buildPillButton(
            icon: Icons.add,
            onTap: quantity < max ? () => onChanged(quantity + 1) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPillButton({required IconData icon, VoidCallback? onTap}) {
    final isEnabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(980),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isEnabled ? AppColors.primary : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 16,
            color: isEnabled ? Colors.white : AppColors.textHint,
          ),
        ),
      ),
    );
  }
}
