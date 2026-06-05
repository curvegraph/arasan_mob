import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';

class OtpInput extends StatefulWidget {
  final ValueChanged<String> onCompleted;
  final VoidCallback? onResend;
  final int length;

  const OtpInput({
    super.key,
    required this.onCompleted,
    this.onResend,
    this.length = 6,
  });

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  Timer? _timer;
  int _remainingSeconds = 30;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.length,
      (_) => TextEditingController(),
    );
    _focusNodes = List.generate(
      widget.length,
      (_) => FocusNode(),
    );
    _startTimer();

    // Auto-focus the first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _remainingSeconds = 30;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
        setState(() => _canResend = true);
      }
    });
  }

  void _onChanged(int index, String value) {
    if (value.length == 1 && index < widget.length - 1) {
      // Move to next field
      _focusNodes[index + 1].requestFocus();
    }

    // Check if all fields are filled
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length == widget.length) {
      widget.onCompleted(otp);
    }
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      // Move to previous field and clear it
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
    }
  }

  void _handleResend() {
    if (!_canResend) return;
    _startTimer();
    // Clear all fields
    for (final controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
    widget.onResend?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // OTP fields
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.length, (index) {
            final isFilled = _controllers[index].text.isNotEmpty;
            return Container(
              width: 46,
              height: 52,
              margin: EdgeInsets.only(
                right: index < widget.length - 1 ? AppSpacing.sm : 0,
              ),
              child: KeyboardListener(
                focusNode: FocusNode(),
                onKeyEvent: (event) => _onKeyEvent(index, event),
                child: TextField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(1),
                  ],
                  onChanged: (value) => _onChanged(index, value),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.glassWhite),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: isFilled
                            ? AppColors.userPrimary
                            : AppColors.glassWhite,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppColors.userPrimary,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: isFilled
                        ? AppColors.surfaceVariant.withValues(alpha: 0.3)
                        : AppColors.surface,
                  ),
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Timer and resend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_canResend) ...[
              const Icon(
                Icons.timer_outlined,
                size: 16,
                color: AppColors.textHint,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Resend OTP in ${_remainingSeconds}s',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textHint,
                ),
              ),
            ] else
              TextButton(
                onPressed: _handleResend,
                child: const Text(
                  'Resend OTP',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.userPrimary,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
