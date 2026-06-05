import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/razorpay_helper.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/order_error_messages.dart';
import '../../../data/models/address.dart';
import '../../../data/models/order.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/checkout_provider.dart';
import '../../../providers/store_settings_provider.dart';
import '../../../providers/user_order_provider.dart';
import '../../../providers/user_profile_provider.dart';
import '../../../shared/widgets/image_placeholder.dart';
import '../../auth/screens/login_dialog.dart';

/// Indian states list for dropdown
const _indianStates = [
  'Andhra Pradesh',
  'Arunachal Pradesh',
  'Assam',
  'Bihar',
  'Chhattisgarh',
  'Goa',
  'Gujarat',
  'Haryana',
  'Himachal Pradesh',
  'Jharkhand',
  'Karnataka',
  'Kerala',
  'Madhya Pradesh',
  'Maharashtra',
  'Manipur',
  'Meghalaya',
  'Mizoram',
  'Nagaland',
  'Odisha',
  'Punjab',
  'Rajasthan',
  'Sikkim',
  'Tamil Nadu',
  'Telangana',
  'Tripura',
  'Uttar Pradesh',
  'Uttarakhand',
  'West Bengal',
  'Delhi',
  'Jammu & Kashmir',
  'Ladakh',
  'Puducherry',
  'Chandigarh',
  'Andaman & Nicobar Islands',
  'Dadra & Nagar Haveli and Daman & Diu',
  'Lakshadweep',
];

class UserCheckoutScreen extends StatefulWidget {
  const UserCheckoutScreen({super.key});

  @override
  State<UserCheckoutScreen> createState() => _UserCheckoutScreenState();
}

class _UserCheckoutScreenState extends State<UserCheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _apartmentController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  String? _selectedState;
  bool _saveInfo = true;
  bool _isShipping = true;
  bool _isSaving = false;

  // Use existing saved address
  bool _useSavedAddress = false;
  UserAddress? _selectedSavedAddress;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CheckoutProvider>().reset();
      // Re-fetch on every checkout entry so admin toggles (payment methods,
      // tax) take effect immediately instead of waiting for the 60s poll.
      context.read<StoreSettingsProvider>().loadSettings(force: true);
      final profileProvider = context.read<UserProfileProvider>();
      if (!profileProvider.isInitialized) {
        profileProvider.loadAddresses();
      }
      // If user has saved addresses, pre-select the default
      final addresses = profileProvider.addresses;
      if (addresses.isNotEmpty) {
        final defaultAddr = profileProvider.defaultAddress ?? addresses.first;
        setState(() {
          _useSavedAddress = true;
          _selectedSavedAddress = defaultAddr;
        });
        context.read<CheckoutProvider>().setAddress(defaultAddr);
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _apartmentController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  void _populateFormFromAddress(UserAddress address) {
    final names = address.fullName.split(' ');
    _firstNameController.text = names.first;
    _lastNameController.text = names.length > 1 ? names.sublist(1).join(' ') : '';
    _phoneController.text = address.phone.replaceFirst('+91 ', '');
    _addressController.text = address.addressLine1;
    _apartmentController.text = address.addressLine2 ?? '';
    _cityController.text = address.city;
    _selectedState = address.state;
    _pincodeController.text = address.pincode;
  }

  Future<void> _placeOrder() async {
    final checkoutProvider = context.read<CheckoutProvider>();
    final cartProvider = context.read<CartProvider>();
    final orderProvider = context.read<UserOrderProvider>();
    final authProvider = context.read<AuthProvider>();
    final profileProvider = context.read<UserProfileProvider>();
    final cart = cartProvider.cart;

    UserAddress? address;

    if (_useSavedAddress && _selectedSavedAddress != null) {
      address = _selectedSavedAddress;
      checkoutProvider.setAddress(address!);
    } else {
      // Validate form
      if (!_formKey.currentState!.validate()) return;
      if (_selectedState == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select a state'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        return;
      }

      final fullName = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'.trim();
      final phone = '+91 ${_phoneController.text.trim()}';

      address = UserAddress(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        label: 'Home',
        fullName: fullName,
        phone: phone,
        addressLine1: _addressController.text.trim(),
        addressLine2: _apartmentController.text.trim().isEmpty
            ? null
            : _apartmentController.text.trim(),
        city: _cityController.text.trim(),
        state: _selectedState!,
        pincode: _pincodeController.text.trim(),
        isDefault: _saveInfo,
      );
      checkoutProvider.setAddress(address);
    }

    // Require login
    if (!authProvider.isLoggedIn || authProvider.authToken == null) {
      final loggedIn = await LoginDialog.showWithMessage(
        context,
        'Please login to place your order',
      );
      if (!loggedIn || !mounted) return;
    }

    if (!authProvider.isLoggedIn || authProvider.authToken == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please login to place order'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
      return;
    }

    // Save address if requested
    if (_saveInfo && !_useSavedAddress) {
      setState(() => _isSaving = true);
      try {
        await profileProvider.addAddress(address);
      } catch (_) {}
      if (mounted) setState(() => _isSaving = false);
    }

    // Build items list
    final orderItems = cart.activeItems.map((item) {
      return {
        'product_id': item.product.id,
        'quantity': item.quantity,
      };
    }).toList();

    final deliveryOption = checkoutProvider.deliveryOption == DeliveryOption.express
        ? 'express'
        : 'standard';

    try {
      if (checkoutProvider.paymentMethod == PaymentMethod.cod) {
        // COD — create order directly
        final orderNumber = await orderProvider.placeOrder(
          items: orderItems,
          customerName: address.fullName,
          customerEmail: authProvider.userEmail,
          customerPhone: address.phone,
          shippingAddressLine1: address.addressLine1,
          shippingCity: address.city,
          shippingState: address.state,
          shippingPincode: address.pincode,
          paymentMethod: 'cod',
          couponCode: cart.appliedCouponCode,
          deliveryOption: deliveryOption,
        );

        cartProvider.clearCart();
        if (mounted) {
          context.go('/shop/order-success/$orderNumber');
        }
      } else {
        // Online payment — create Razorpay order
        final orderCreated = await checkoutProvider.createRazorpayOrder(
          items: orderItems,
          couponCode: cart.appliedCouponCode,
        );

        if (!orderCreated) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(checkoutProvider.paymentError != null
                    ? friendlyOrderError(checkoutProvider.paymentError!)
                    : 'Failed to initiate payment'),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            );
          }
          return;
        }

        // Open Razorpay payment sheet via JS
        if (mounted) {
          _openRazorpayWeb(
            checkout: checkoutProvider,
            cartProvider: cartProvider,
            orderItems: orderItems,
            couponCode: cart.appliedCouponCode,
          );
        }
      }
    } catch (e, st) {
      debugPrint('[Checkout] placeOrder failed: $e');
      debugPrint('$st');
      if (mounted) {
        // TEMP: show raw exception text to surface the underlying cause
        // while we debug. Swap back to friendlyOrderError(e) once stable.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('DEBUG: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  void _openRazorpayWeb({
    required CheckoutProvider checkout,
    required CartProvider cartProvider,
    required List<Map<String, dynamic>> orderItems,
    String? couponCode,
  }) {
    final options = {
      'key': checkout.razorpayKeyId ?? '',
      'amount': checkout.razorpayAmount ?? 0,
      'currency': 'INR',
      'name': 'Arasan Mobiles',
      'description': 'Order Payment',
      'order_id': checkout.razorpayOrderId ?? '',
      'prefill': {
        'name': checkout.customerName ?? '',
        'email': checkout.customerEmail ?? '',
        'contact': checkout.customerPhone ?? '',
      },
      'theme': {
        'color': '#D32F2F',
      },
    };

    RazorpayHelper.openCheckout(
      options: options,
      onSuccess: (String paymentId, String orderId, String signature) async {
        final orderData = await checkout.verifyPaymentAndCreateOrder(
          razorpayPaymentId: paymentId,
          razorpaySignature: signature,
          items: orderItems,
          couponCode: couponCode,
        );

        if (orderData != null && mounted) {
          cartProvider.clearCart();
          checkout.reset();
          context.go('/shop/order-success/${orderData['order_number']}');
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
            SnackBar(content: Text('Payment failed: $message'), backgroundColor: AppColors.error),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final checkoutProvider = context.watch<CheckoutProvider>();
    final cartProvider = context.watch<CartProvider>();
    final cart = cartProvider.cart;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 900;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/shop/cart');
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            // Breadcrumb header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: AppColors.primary,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/shop'),
                    child: const Text('Home', style: TextStyle(fontSize: 13, color: Colors.white70)),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.chevron_right, size: 16, color: Colors.white54),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/shop/cart'),
                    child: const Text('Cart', style: TextStyle(fontSize: 13, color: Colors.white70)),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.chevron_right, size: 16, color: Colors.white54),
                  ),
                  const Text('Checkout', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                ],
              ),
            ),
            // Body
            Expanded(
              child: checkoutProvider.isProcessing
            ? _buildProcessingOverlay()
            : isWide
                ? _buildWideLayout(cart, checkoutProvider)
                : _buildNarrowLayout(cart, checkoutProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideLayout(cart, CheckoutProvider checkoutProvider) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Form
            Expanded(
              flex: 3,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: _buildFormSectionCompact(checkoutProvider),
              ),
            ),
            // Right: Order Summary
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 24, 8),
                child: _buildOrderSummary(cart, checkoutProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNarrowLayout(cart, CheckoutProvider checkoutProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.userPagePadding),
      child: Column(
        children: [
          // Breadcrumb
          _buildBreadcrumb(),
          const SizedBox(height: 20),
          // Order Summary (Products) at top on mobile
          _buildOrderSummary(cart, checkoutProvider),
          const SizedBox(height: 20),
          // Form
          _buildFormSection(checkoutProvider),
          const SizedBox(height: 24),
          // Place order button
          _buildPlaceOrderButton(checkoutProvider),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildBreadcrumb() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.go('/shop'),
          child: const Text(
            'Home',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Icon(Icons.chevron_right, size: 16, color: AppColors.textHint),
        ),
        GestureDetector(
          onTap: () => context.go('/shop/cart'),
          child: const Text(
            'Your shopping cart',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Icon(Icons.chevron_right, size: 16, color: AppColors.textHint),
        ),
        const Text(
          'Checkout',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildFormSectionCompact(CheckoutProvider checkoutProvider) {
    final profileProvider = context.watch<UserProfileProvider>();
    final addresses = profileProvider.addresses;
    final authProvider = context.watch<AuthProvider>();
    final settings = context.watch<StoreSettingsProvider>();

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Contact Section ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Contact',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (!authProvider.isLoggedIn)
                GestureDetector(
                  onTap: () async {
                    await showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (ctx) => const LoginDialog(),
                    );
                  },
                  child: const Text(
                    'Signin',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _phoneController,
            hint: 'Mobile number',
            keyboardType: TextInputType.phone,
            maxLength: 10,
            prefix: '+91  ',
            validator: (v) {
              if (_useSavedAddress) return null;
              if (v == null || v.trim().isEmpty) return 'Phone is required';
              if (v.trim().length < 10) return 'Enter valid 10-digit number';
              return null;
            },
            enabled: !_useSavedAddress,
          ),

          const SizedBox(height: 16),

          // ── Delivery Address Section ──
          const Text(
            'Delivery Address',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          // Saved addresses selector
          if (addresses.isNotEmpty) ...[
            _buildSavedAddressSelector(addresses),
            const SizedBox(height: 10),
          ],

          // Address form (shown when not using saved address)
          if (!_useSavedAddress) ...[
            // First name + Last name row
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _firstNameController,
                    hint: 'First name',
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTextField(
                    controller: _lastNameController,
                    hint: 'Last name (optional)',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Address
            _buildTextField(
              controller: _addressController,
              hint: 'Address',
              suffixIcon: Icons.search,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Address is required' : null,
            ),
            const SizedBox(height: 8),

            // Apartment
            _buildTextField(
              controller: _apartmentController,
              hint: 'Apartment, Suite, etc (optional)',
            ),
            const SizedBox(height: 8),

            // City/State + Pincode
            Row(
              children: [
                Expanded(
                  child: _buildStateDropdown(),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTextField(
                    controller: _pincodeController,
                    hint: 'Pincode',
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (v.trim().length != 6) return 'Invalid pincode';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // City
            _buildTextField(
              controller: _cityController,
              hint: 'City',
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'City is required' : null,
            ),
            const SizedBox(height: 8),

            // Save info checkbox
            GestureDetector(
              onTap: () => setState(() => _saveInfo = !_saveInfo),
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: Checkbox(
                      value: _saveInfo,
                      onChanged: (v) => setState(() => _saveInfo = v ?? true),
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      side: const BorderSide(color: AppColors.textHint, width: 1.5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Save the information for the next time shipping',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // ── Payment Method Section ──
          const Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          if (settings.onlineEnabled)
            _buildPaymentOption(
              icon: Icons.lock_outline,
              label: 'Online Payment',
              description: 'UPI, Cards, Netbanking, Wallets via Razorpay',
              method: PaymentMethod.online,
              checkoutProvider: checkoutProvider,
            ),
          if (settings.onlineEnabled && settings.codEnabled)
            const SizedBox(height: 6),
          if (settings.codEnabled)
            _buildPaymentOption(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Cash on Delivery',
              description: 'Pay when you receive your order',
              method: PaymentMethod.cod,
              checkoutProvider: checkoutProvider,
            ),
          if (!settings.onlineEnabled && !settings.codEnabled)
            _buildNoPaymentMethodsHint(),
        ],
      ),
    );
  }

  Widget _buildFormSection(CheckoutProvider checkoutProvider) {
    final profileProvider = context.watch<UserProfileProvider>();
    final addresses = profileProvider.addresses;
    final authProvider = context.watch<AuthProvider>();
    final settings = context.watch<StoreSettingsProvider>();

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Contact Section ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Contact',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              if (!authProvider.isLoggedIn)
                GestureDetector(
                  onTap: () async {
                    await showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (ctx) => const LoginDialog(),
                    );
                  },
                  child: const Text(
                    'Signin',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _phoneController,
            hint: 'Mobile number',
            keyboardType: TextInputType.phone,
            maxLength: 10,
            prefix: '+91  ',
            validator: (v) {
              if (_useSavedAddress) return null;
              if (v == null || v.trim().isEmpty) return 'Phone is required';
              if (v.trim().length < 10) return 'Enter valid 10-digit number';
              return null;
            },
            enabled: !_useSavedAddress,
          ),

          const SizedBox(height: 28),

          // ── Delivery Address Section ──
          const Text(
            'Delivery Address',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),

          // Saved addresses selector
          if (addresses.isNotEmpty) ...[
            _buildSavedAddressSelector(addresses),
            const SizedBox(height: 16),
          ],

          // Address form (shown when not using saved address)
          if (!_useSavedAddress) ...[
            // First name + Last name row
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _firstNameController,
                    hint: 'First name',
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _lastNameController,
                    hint: 'Last name (optional)',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Address
            _buildTextField(
              controller: _addressController,
              hint: 'Address',
              suffixIcon: Icons.search,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Address is required' : null,
            ),
            const SizedBox(height: 12),

            // Apartment
            _buildTextField(
              controller: _apartmentController,
              hint: 'Apartment, Suite, etc (optional)',
            ),
            const SizedBox(height: 12),

            // City/State + Pincode
            Row(
              children: [
                Expanded(
                  child: _buildStateDropdown(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _pincodeController,
                    hint: 'Pincode',
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (v.trim().length != 6) return 'Invalid pincode';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // City
            _buildTextField(
              controller: _cityController,
              hint: 'City',
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'City is required' : null,
            ),
            const SizedBox(height: 12),

            // Save info checkbox
            GestureDetector(
              onTap: () => setState(() => _saveInfo = !_saveInfo),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: _saveInfo,
                      onChanged: (v) => setState(() => _saveInfo = v ?? true),
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      side: const BorderSide(color: AppColors.textHint, width: 1.5),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Save the information for the next time shipping',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 28),

          // ── Payment Method Section ──
          const Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          if (settings.onlineEnabled)
            _buildPaymentOption(
              icon: Icons.lock_outline,
              label: 'Online Payment',
              description: 'UPI, Cards, Netbanking, Wallets via Razorpay',
              method: PaymentMethod.online,
              checkoutProvider: checkoutProvider,
            ),
          if (settings.onlineEnabled && settings.codEnabled)
            const SizedBox(height: 8),
          if (settings.codEnabled)
            _buildPaymentOption(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Cash on Delivery',
              description: 'Pay when you receive your order',
              method: PaymentMethod.cod,
              checkoutProvider: checkoutProvider,
            ),
          if (!settings.onlineEnabled && !settings.codEnabled)
            _buildNoPaymentMethodsHint(),
        ],
      ),
    );
  }

  Widget _buildSavedAddressSelector(List<UserAddress> addresses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle between saved and new address
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _useSavedAddress = true;
                    if (_selectedSavedAddress == null && addresses.isNotEmpty) {
                      _selectedSavedAddress = addresses.first;
                      context.read<CheckoutProvider>().setAddress(addresses.first);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _useSavedAddress ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _useSavedAddress ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Saved Address',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _useSavedAddress ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _useSavedAddress = false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: !_useSavedAddress ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: !_useSavedAddress ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'New Address',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: !_useSavedAddress ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        if (_useSavedAddress) ...[
          const SizedBox(height: 12),
          ...addresses.map((address) {
            final isSelected = _selectedSavedAddress?.id == address.id;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedSavedAddress = address);
                context.read<CheckoutProvider>().setAddress(address);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.04)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.only(top: 2),
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                address.fullName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  address.label.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              if (address.isDefault) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'DEFAULT',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            address.formattedAddress,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            address.phone,
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
          }),
        ],
      ],
    );
  }

  Widget _buildDeliveryToggle({
    required String label,
    required IconData icon,
    required bool isSelected,
    required bool isTop,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.04)
              : AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: isTop ? const Radius.circular(11) : Radius.zero,
            bottom: !isTop ? const Radius.circular(11) : Radius.zero,
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
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.primary : AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShippingOption({
    required String title,
    required String subtitle,
    required String price,
    required Color priceColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.04)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: priceColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoPaymentMethodsHint() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.warning),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'No payment methods available right now. Please try again '
              'later or contact support.',
              style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required String label,
    required String description,
    required PaymentMethod method,
    required CheckoutProvider checkoutProvider,
  }) {
    final isSelected = checkoutProvider.paymentMethod == method;
    return GestureDetector(
      onTap: () => checkoutProvider.setPaymentMethod(method),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.04)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(cart, CheckoutProvider checkoutProvider) {
    final cartProvider = context.watch<CartProvider>();
    final settings = context.watch<StoreSettingsProvider>();
    final cartData = cartProvider.cart;
    final standardDelivery = settings.deliveryChargeFor(cartData.subtotal);
    final deliveryCharge =
        checkoutProvider.deliveryOption == DeliveryOption.express
            ? standardDelivery + checkoutProvider.expressSurcharge
            : standardDelivery;
    final tax = settings.taxFor(cartData.subtotal);
    final total = cartData.subtotal - cartData.couponDiscount + deliveryCharge + tax;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Products header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Products',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${cartData.activeItems.length}'.padLeft(2, '0'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Product items
          ...cartData.activeItems.map(
            (item) => _buildProductItem(item),
          ),

          // Divider
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            height: 1,
            color: AppColors.border,
          ),

          // Price breakdown
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildPriceRow(
                  'Subtotal',
                  CurrencyFormatter.format(cartData.subtotal),
                ),
                if (cartData.couponDiscount > 0) ...[
                  const SizedBox(height: 8),
                  _buildPriceRow(
                    'Coupon Discount',
                    '- ${CurrencyFormatter.format(cartData.couponDiscount)}',
                    valueColor: AppColors.success,
                  ),
                ],
                const SizedBox(height: 8),
                _buildPriceRow(
                  'Shipping',
                  deliveryCharge == 0
                      ? 'Free your address'
                      : CurrencyFormatter.format(deliveryCharge),
                  valueColor: deliveryCharge == 0 ? AppColors.success : null,
                ),
                if (tax > 0) ...[
                  const SizedBox(height: 8),
                  _buildPriceRow(
                    settings.taxLabel(),
                    CurrencyFormatter.format(tax),
                  ),
                ],
                const SizedBox(height: 12),
                Container(height: 1, color: AppColors.border),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Price',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(total),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),

                // Place order button (for wide layout, shown in summary)
                if (MediaQuery.of(context).size.width > 900) ...[
                  const SizedBox(height: 20),
                  _buildPlaceOrderButton(checkoutProvider),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(item) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: [
          // Product image with blue border
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: ImagePlaceholder(
                imageUrl: item.product.imageUrls.isNotEmpty
                    ? item.product.imageUrls.first
                    : null,
                width: 64,
                height: 64,
                icon: Icons.phone_android,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Qty: ${item.quantity}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.format(item.totalPrice),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceOrderButton(CheckoutProvider checkoutProvider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving || checkoutProvider.isProcessing ? null : _placeOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isSaving || checkoutProvider.isProcessing
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Place Order',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    int? maxLength,
    String? prefix,
    IconData? suffixIcon,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLength: maxLength,
      enabled: enabled,
      style: TextStyle(
        fontSize: 14,
        color: enabled ? AppColors.textPrimary : AppColors.textHint,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: AppColors.textHint),
        counterText: '',
        prefixText: prefix,
        prefixStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
        suffixIcon: suffixIcon != null
            ? Icon(suffixIcon, size: 20, color: AppColors.textHint)
            : null,
        filled: true,
        fillColor: enabled ? AppColors.surface : AppColors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }

  Widget _buildStateDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedState,
      isExpanded: true,
      hint: const Text(
        'City/State',
        style: TextStyle(fontSize: 14, color: AppColors.textHint),
      ),
      icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textHint),
      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      validator: (v) {
        if (_useSavedAddress) return null;
        return v == null ? 'State is required' : null;
      },
      items: _indianStates.map((state) {
        return DropdownMenuItem(
          value: state,
          child: Text(
            state,
            style: const TextStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedState = value),
    );
  }

  Widget _buildProcessingOverlay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Processing your order...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please do not close this screen',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
