import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/razorpay_helper.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/order_error_messages.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/checkout_provider.dart';
import '../../../providers/store_settings_provider.dart';
import '../../../providers/user_order_provider.dart';
import '../../../providers/user_profile_provider.dart';
import '../../../data/models/order.dart';
import '../../auth/screens/login_dialog.dart';
import '../widgets/address_selection.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLoginAndLoadData();
    });
  }

  Future<void> _checkLoginAndLoadData() async {
    final auth = context.read<AuthProvider>();

    // If not logged in, show login dialog
    if (!auth.isLoggedIn) {
      final loggedIn = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const LoginDialog(),
      );

      if (loggedIn != true && mounted) {
        // User cancelled login, go back to cart
        context.go('/shop/cart');
        return;
      }
    }

    // Load user addresses after login
    if (mounted) {
      final profileProvider = context.read<UserProfileProvider>();
      if (!profileProvider.isInitialized) {
        await profileProvider.loadAddresses();
      }
      // Re-fetch on every checkout entry so admin toggles (payment methods,
      // tax) take effect immediately instead of waiting for the 60s poll.
      await context.read<StoreSettingsProvider>().loadSettings(force: true);
      _ensureValidPaymentSelection();
    }
  }

  void _ensureValidPaymentSelection() {
    if (!mounted) return;
    final settings = context.read<StoreSettingsProvider>();
    final checkout = context.read<CheckoutProvider>();
    final current = checkout.paymentMethod;
    final isCurrentEnabled = switch (current) {
      PaymentMethod.cod => settings.codEnabled,
      // Treat any online variant as enabled if the merged flag is on.
      PaymentMethod.online || PaymentMethod.upi || PaymentMethod.card =>
        settings.onlineEnabled,
    };
    if (isCurrentEnabled) return;
    if (settings.onlineEnabled) {
      checkout.setPaymentMethod(PaymentMethod.online);
    } else if (settings.codEnabled) {
      checkout.setPaymentMethod(PaymentMethod.cod);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cart = context.watch<CartProvider>();
    final checkout = context.watch<CheckoutProvider>();

    // Show loading while checking auth
    if (!auth.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 70,
        title: const Text(
          'Checkout',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.5,
            height: 1.0,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => context.go('/shop/cart'),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step indicator
            _buildStepIndicator(checkout.currentStep),
            const SizedBox(height: 24),

            // Step content
            if (checkout.currentStep == 0)
              const AddressSelection()
            else if (checkout.currentStep == 1)
              _buildPaymentStep(checkout)
            else
              _buildReviewStep(cart, checkout),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context, cart, checkout),
    );
  }

  Widget _buildStepIndicator(int currentStep) {
    const steps = ['Address', 'Payment', 'Review'];

    return Row(
      children: List.generate(steps.length, (index) {
        final isActive = index <= currentStep;
        final isCompleted = index < currentStep;

        return Expanded(
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? AppColors.primary : AppColors.border,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isActive ? Colors.white : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  steps[index],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
              ),
              if (index < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    color: isCompleted ? AppColors.primary : AppColors.border,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildPaymentStep(CheckoutProvider checkout) {
    final settings = context.watch<StoreSettingsProvider>();
    final methods = <Widget>[];
    final online = checkout.requiresOnlinePayment;

    if (settings.onlineEnabled) {
      methods.add(_PaymentMethodCard(
        icon: Icons.lock_outline,
        title: 'Online Payment',
        subtitle: 'UPI, Cards, Netbanking, Wallets — powered by Razorpay',
        isSelected: online,
        onTap: () => checkout.setPaymentMethod(PaymentMethod.online),
      ));
    }
    if (settings.codEnabled) {
      if (methods.isNotEmpty) methods.add(const SizedBox(height: 12));
      methods.add(_PaymentMethodCard(
        icon: Icons.money,
        title: 'Cash on Delivery',
        subtitle: 'Pay when you receive your order',
        isSelected: checkout.paymentMethod == PaymentMethod.cod,
        onTap: () => checkout.setPaymentMethod(PaymentMethod.cod),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'How would you like to pay?',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        if (methods.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Column(
              children: [
                Icon(Icons.payment_outlined, size: 36, color: AppColors.textSecondary),
                SizedBox(height: 10),
                Text(
                  'No payment methods available right now',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4),
                Text(
                  'Please try again later or contact support.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ...methods,
      ],
    );
  }

  Widget _buildReviewStep(CartProvider cartProvider, CheckoutProvider checkout) {
    final cart = cartProvider.cart;
    final address = checkout.selectedAddress;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Review Your Order',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),

        // Delivery Address Summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'Delivering to',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => checkout.setStep(0),
                    child: const Text('Change', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
              if (address != null) ...[
                Text(
                  address.fullName,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  address.formattedAddress,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  address.phone,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Payment Method Summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Icon(
                checkout.paymentMethod == PaymentMethod.cod
                    ? Icons.money
                    : Icons.lock_outline,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Payment: ${checkout.paymentMethodLabel}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => checkout.setStep(1),
                child: const Text('Change', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Order Items
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order Items (${cart.itemCount})',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ...cart.activeItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.product.imageUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 50,
                          height: 50,
                          color: AppColors.background,
                          child: const Icon(Icons.image, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product.name,
                            style: const TextStyle(fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Qty: ${item.quantity}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(item.totalPrice),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Price Summary
        _buildPriceSummary(cart),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildPriceSummary(cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal'),
              Text(CurrencyFormatter.format(cart.subtotal)),
            ],
          ),
          const SizedBox(height: 8),
          Builder(builder: (ctx) {
            final settings = ctx.watch<StoreSettingsProvider>();
            final delivery = settings.deliveryChargeFor(cart.subtotal);
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Delivery'),
                Text(
                  delivery == 0 ? 'FREE' : CurrencyFormatter.format(delivery),
                  style: TextStyle(
                    color: delivery == 0 ? AppColors.success : null,
                  ),
                ),
              ],
            );
          }),
          Builder(builder: (ctx) {
            final settings = ctx.watch<StoreSettingsProvider>();
            final tax = settings.taxFor(cart.subtotal);
            if (tax <= 0) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(settings.taxLabel()),
                  Text(CurrencyFormatter.format(tax)),
                ],
              ),
            );
          }),
          if (cart.couponDiscount > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Coupon Discount'),
                Text(
                  '-${CurrencyFormatter.format(cart.couponDiscount)}',
                  style: const TextStyle(color: AppColors.success),
                ),
              ],
            ),
          ],
          const Divider(height: 24),
          Builder(builder: (ctx) {
            final settings = ctx.watch<StoreSettingsProvider>();
            final tax = settings.taxFor(cart.subtotal);
            final delivery = settings.deliveryChargeFor(cart.subtotal);
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  CurrencyFormatter.format(
                      cart.totalAmountWith(tax, delivery: delivery)),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.primary,
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, CartProvider cartProvider, CheckoutProvider checkout) {
    final cart = cartProvider.cart;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Back button (except on first step)
            if (checkout.currentStep > 0)
              OutlinedButton(
                onPressed: checkout.previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: const Text('Back'),
              ),
            if (checkout.currentStep > 0) const SizedBox(width: 12),

            // Main action button
            Expanded(
              child: Consumer<UserOrderProvider>(
                builder: (context, orderProvider, _) {
                  final isLastStep = checkout.currentStep == 2;
                  final canProceed = _canProceedToNextStep(checkout);

                  return ElevatedButton(
                    onPressed: (cart.isEmpty || orderProvider.isLoading || !canProceed)
                        ? null
                        : () => _handleStepAction(context, checkout, isLastStep),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.border,
                    ),
                    child: orderProvider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            isLastStep ? 'Place Order' : 'Continue',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canProceedToNextStep(CheckoutProvider checkout) {
    switch (checkout.currentStep) {
      case 0:
        return checkout.selectedAddress != null;
      case 1:
        return true; // Payment method always has a default
      case 2:
        return checkout.selectedAddress != null;
      default:
        return false;
    }
  }

  void _handleStepAction(BuildContext context, CheckoutProvider checkout, bool isLastStep) {
    if (isLastStep) {
      _placeOrder(context);
    } else {
      checkout.nextStep();
    }
  }

  void _placeOrder(BuildContext context) async {
    final cartProvider = context.read<CartProvider>();
    final cart = cartProvider.cart;
    final auth = context.read<AuthProvider>();
    final checkout = context.read<CheckoutProvider>();
    final orderProvider = context.read<UserOrderProvider>();

    if (cart.isEmpty) return;

    // Must be logged in
    if (!auth.isLoggedIn || auth.authToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to place order'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Must have address selected
    final address = checkout.selectedAddress;
    if (address == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a delivery address'),
          backgroundColor: AppColors.error,
        ),
      );
      checkout.setStep(0);
      return;
    }

    // Build items list — only product IDs and quantities.
    final orderItems = cart.activeItems.map((item) {
      return {
        'product_id': item.product.id,
        'quantity': item.quantity,
      };
    }).toList();

    final deliveryOption = checkout.deliveryOption == DeliveryOption.express
        ? 'express'
        : 'standard';

    try {
      if (checkout.paymentMethod == PaymentMethod.cod) {
        // COD — create order directly via create-order Edge Function
        final orderNumber = await orderProvider.placeOrder(
          items: orderItems,
          shippingAddressLine1: address.addressLine1,
          shippingCity: address.city,
          shippingState: address.state,
          shippingPincode: address.pincode,
          paymentMethod: 'cod',
          couponCode: cart.appliedCouponCode,
          deliveryOption: deliveryOption,
        );

        if (mounted) {
          cartProvider.clearCart();
          checkout.reset();
          context.go('/shop/order-success/$orderNumber');
        }
      } else {
        // Online payment — create Razorpay order, then open payment sheet
        final orderCreated = await checkout.createRazorpayOrder(
          items: orderItems,
          couponCode: cart.appliedCouponCode,
        );

        if (!orderCreated) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(checkout.paymentError != null
                    ? friendlyOrderError(checkout.paymentError!)
                    : 'Failed to initiate payment'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }

        // Open Razorpay checkout (web uses Razorpay.js, native uses SDK)
        if (mounted) {
          _openRazorpayCheckout(
            context: context,
            checkout: checkout,
            cartProvider: cartProvider,
            orderItems: orderItems,
            couponCode: cart.appliedCouponCode,
            deliveryOption: deliveryOption,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyOrderError(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _openRazorpayCheckout({
    required BuildContext context,
    required CheckoutProvider checkout,
    required CartProvider cartProvider,
    required List<Map<String, dynamic>> orderItems,
    String? couponCode,
    required String deliveryOption,
  }) {
    // Use Razorpay.js on web via JS interop
    final options = <String, dynamic>{
      'key': checkout.razorpayKeyId,
      'amount': checkout.razorpayAmount,
      'currency': 'INR',
      'name': 'Arasan Mobiles',
      'description': 'Order Payment',
      'order_id': checkout.razorpayOrderId,
      'prefill': {
        'name': checkout.customerName ?? '',
        'email': checkout.customerEmail ?? '',
        'contact': checkout.customerPhone ?? '',
      },
      'theme': {
        'color': '#D32F2F',
      },
    };

    // Call Razorpay (web JS or mobile native)
    RazorpayHelper.openCheckout(
      options: options,
      onSuccess: (String paymentId, String orderId, String signature) async {
        // Verify payment and create order server-side
        final orderData = await checkout.verifyPaymentAndCreateOrder(
          razorpayPaymentId: paymentId,
          razorpaySignature: signature,
          items: orderItems,
          couponCode: couponCode,
        );

        if (orderData != null && mounted) {
          cartProvider.clearCart();
          checkout.reset();
          final orderNumber = orderData['order_number'] as String?;
          context.go('/shop/order-success/$orderNumber');
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(checkout.paymentError != null
                  ? friendlyOrderError(checkout.paymentError!)
                  : 'Payment verification failed'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      onError: (String message) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment failed: $message'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
    );
  }

}

class _PaymentMethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.textHint,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
