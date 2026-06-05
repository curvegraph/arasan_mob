import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';

class OrderSuccessScreen extends StatefulWidget {
  final String orderId;

  const OrderSuccessScreen({super.key, required this.orderId});

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _checkController;
  late AnimationController _contentController;
  late Animation<double> _checkScale;
  late Animation<double> _checkRotate;
  late Animation<double> _cardSlide;
  late Animation<double> _cardFade;

  @override
  void initState() {
    super.initState();

    _checkController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _checkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.elasticOut),
    );
    _checkRotate = Tween<double>(begin: -0.5, end: 0.0).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.easeOutBack),
    );

    _cardSlide = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOutCubic),
    );
    _cardFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
    );

    _checkController.forward().then((_) {
      _contentController.forward();
    });
  }

  @override
  void dispose() {
    _checkController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estimatedDate = DateTime.now().add(const Duration(days: 5));
    final formattedDate = DateFormat('EEE, dd MMM yyyy').format(estimatedDate);
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth > 600 ? 460.0 : screenWidth * 0.9;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/shop');
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: SizedBox(
            width: cardWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated check icon
                ScaleTransition(
                  scale: _checkScale,
                  child: RotationTransition(
                    turns: _checkRotate,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF34D399), Color(0xFF10B981)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.35),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 44),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Card with all details
                AnimatedBuilder(
                  animation: _contentController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _cardSlide.value),
                      child: Opacity(
                        opacity: _cardFade.value,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          blurRadius: 32,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Top section - success message
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withValues(alpha: 0.04),
                                AppColors.primary.withValues(alpha: 0.01),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Order Placed!',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1A1A1A),
                                  letterSpacing: -0.6,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Thank you for shopping with Arasan Mobiles',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Order details
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              _buildInfoTile(
                                icon: Icons.tag_rounded,
                                label: 'Order ID',
                                value: widget.orderId,
                                color: AppColors.primary,
                              ),
                              _divider(),
                              _buildInfoTile(
                                icon: Icons.local_shipping_rounded,
                                label: 'Estimated Delivery',
                                value: formattedDate,
                                color: const Color(0xFF10B981),
                              ),
                              _divider(),
                              _buildInfoTile(
                                icon: Icons.verified_rounded,
                                label: 'Status',
                                value: 'Confirmed',
                                color: const Color(0xFF3B82F6),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Notification banner
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F9FF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFBAE6FD)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.notifications_active_rounded,
                                  size: 16, color: Color(0xFF0EA5E9)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'You\'ll receive updates via SMS & notifications',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: const Color(0xFF0369A1).withValues(alpha: 0.9),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Action buttons
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: Row(
                            children: [
                              // Continue Shopping
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => context.go('/shop'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.textSecondary,
                                    side: const BorderSide(color: AppColors.border),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    'Continue Shopping',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              // View Order
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () =>
                                      context.push('/shop/account/orders/${widget.orderId}'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    'View Order',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textHint,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 1,
      color: AppColors.border.withValues(alpha: 0.5),
    );
  }
}
