import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_animations.dart';
import '../../../core/utils/glass_morphism.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/support_ticket.dart';
import '../../../providers/support_provider.dart';

class UserRaiseTicketScreen extends StatefulWidget {
  const UserRaiseTicketScreen({super.key});

  @override
  State<UserRaiseTicketScreen> createState() => _UserRaiseTicketScreenState();
}

class _UserRaiseTicketScreenState extends State<UserRaiseTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _orderIdController = TextEditingController();
  final _descriptionController = TextEditingController();
  TicketCategory _selectedCategory = TicketCategory.order;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _orderIdController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _categoryLabel(TicketCategory category) {
    switch (category) {
      case TicketCategory.order:
        return 'Order Issue';
      case TicketCategory.payment:
        return 'Payment';
      case TicketCategory.delivery:
        return 'Delivery';
      case TicketCategory.product:
        return 'Product';
      case TicketCategory.account:
        return 'Account';
      case TicketCategory.other:
        return 'Other';
    }
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await context.read<SupportProvider>().raiseTicket(
            subject: _subjectController.text.trim(),
            description: _descriptionController.text.trim(),
            category: _selectedCategory,
            orderId: _orderIdController.text.trim().isEmpty
                ? null
                : _orderIdController.text.trim(),
          );

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    size: 40,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Ticket Submitted!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Our support team will get back to you within 24 hours.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ScaleOnTap(
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('/shop/help');
                  },
                  child: Container(
                    width: double.infinity,
                    height: 44,
                    decoration: PremiumDecorations.goldGlowButton(),
                    child: const Center(
                      child: Text(
                        'Done',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to submit ticket. Please try again.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(AppSpacing.md),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: const Text(
          'Raise a Ticket',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.5,
            height: 1.0,
          ),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.userPagePadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info banner - dark themed
              FadeSlideIn(
                index: 0,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.info.withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.info, size: 22),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Describe your issue clearly so our team can help you faster.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.info,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Subject
              FadeSlideIn(
                index: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Subject'),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _subjectController,
                      validator: (v) => Validators.required(v, 'Subject'),
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: _inputDecoration(
                        hint: 'Brief summary of your issue',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Category
              FadeSlideIn(
                index: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Category'),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.glassWhite),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<TicketCategory>(
                          value: _selectedCategory,
                          isExpanded: true,
                          dropdownColor: AppColors.surfaceVariant,
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: AppColors.textSecondary,
                          ),
                          items: TicketCategory.values.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(
                                _categoryLabel(category),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedCategory = value);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Order ID (optional)
              FadeSlideIn(
                index: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Order ID (optional)'),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _orderIdController,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: _inputDecoration(
                        hint: 'e.g., ORD-1001',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Description
              FadeSlideIn(
                index: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Description'),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 6,
                      maxLength: 1000,
                      style: const TextStyle(color: AppColors.textPrimary),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Description is required';
                        }
                        if (value.trim().length < 20) {
                          return 'Please provide more details (min 20 characters)';
                        }
                        return null;
                      },
                      decoration: _inputDecoration(
                        hint: 'Describe your issue in detail...',
                      ).copyWith(
                        counterStyle: const TextStyle(color: AppColors.textHint),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Submit button - gold gradient
              FadeSlideIn(
                index: 5,
                child: ScaleOnTap(
                  onTap: _isSubmitting ? null : _submitTicket,
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: PremiumDecorations.goldGlowButton(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!_isSubmitting)
                          const Icon(Icons.send, size: 20, color: Colors.white),
                        if (!_isSubmitting) const SizedBox(width: 8),
                        _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Submit Ticket',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sectionSpacing),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
      filled: true,
      fillColor: AppColors.surfaceVariant,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.glassWhite),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.glassWhite),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.userPrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }
}
