import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/validators.dart';

class PhoneInput extends StatelessWidget {
  final TextEditingController controller;
  final String? errorText;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;

  const PhoneInput({
    super.key,
    required this.controller,
    this.errorText,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      maxLength: 10,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      validator: Validators.phone,
      onChanged: onChanged,
      onFieldSubmitted: (_) => onSubmitted?.call(),
      style: const TextStyle(
        fontSize: 16,
        color: AppColors.textPrimary,
        letterSpacing: 1,
      ),
      decoration: InputDecoration(
        hintText: 'Enter 10-digit mobile number',
        hintStyle: TextStyle(
          color: AppColors.textHint,
          fontSize: 15,
          letterSpacing: 0,
        ),
        errorText: errorText,
        counterText: '',
        prefixIcon: Container(
          width: 72,
          alignment: Alignment.center,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '\u{1F1EE}\u{1F1F3}',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(width: 4),
                Text(
                  '+91',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 80,
          minHeight: 48,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.glassWhite),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.glassWhite),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.userPrimary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.glassWhite.withValues(alpha: 0.5)),
        ),
        filled: true,
        fillColor: enabled ? AppColors.surfaceVariant : AppColors.surfaceVariant,
      ),
    );
  }
}
