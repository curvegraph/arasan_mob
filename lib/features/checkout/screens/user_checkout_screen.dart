import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/order_error_messages.dart';
import '../../../data/models/address.dart';
import '../../../data/models/order.dart';
import '../../../data/models/cart.dart';
import '../../../data/models/product.dart';
import '../../../data/services/auth_api_service.dart';
import '../../../data/services/secure_api_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/checkout_provider.dart';
import '../../../providers/store_settings_provider.dart';
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
  /// When set, this is a standalone "Buy Now" checkout for THIS product only —
  /// the existing cart is ignored so cart items never get folded into the
  /// order (qty stays exactly what the user chose on the Order Summary page).
  final Product? buyNowProduct;
  final int buyNowQty;

  const UserCheckoutScreen({
    super.key,
    this.buyNowProduct,
    this.buyNowQty = 1,
  });

  @override
  State<UserCheckoutScreen> createState() => _UserCheckoutScreenState();
}

class _UserCheckoutScreenState extends State<UserCheckoutScreen> {
  /// The items actually being purchased: just the Buy-Now product when this is
  /// a Buy-Now checkout, otherwise the live cart's active items.
  List<CartItem> _effectiveItems(Cart cart) {
    final p = widget.buyNowProduct;
    if (p != null) {
      return [CartItem(id: 'buynow', product: p, quantity: widget.buyNowQty)];
    }
    return cart.activeItems;
  }

  double _effectiveSubtotal(Cart cart) =>
      _effectiveItems(cart).fold(0.0, (s, i) => s + i.totalPrice);

  /// Coupons only apply to the cart flow — a Buy-Now never carries one.
  double _effectiveCoupon(Cart cart) =>
      widget.buyNowProduct != null ? 0 : cart.couponDiscount;

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

  // ── "Get updates by email" opt-in ──
  // Null = not chosen yet, true = Yes (email box shown), false = No (skip).
  bool? _wantsEmailUpdates;
  final _updatesEmailController = TextEditingController();
  bool _emailPrefilled = false;
  // The account's existing real email (e.g. from Google sign-in). It's already
  // verified, so it needs no OTP. Any *different* email the user types does.
  String _trustedEmail = '';
  // Emails proven this session via OTP.
  final Set<String> _verifiedEmails = {};
  bool _sendingEmailOtp = false;

  /// The email in the box is "verified" if it's the account's trusted email or
  /// it was OTP-verified this session.
  bool get _updatesEmailVerified {
    final e = _updatesEmailController.text.trim().toLowerCase();
    if (e.isEmpty) return false;
    if (_trustedEmail.isNotEmpty && e == _trustedEmail) return true;
    return _verifiedEmails.contains(e);
  }

  // Use existing saved address
  bool _useSavedAddress = false;
  UserAddress? _selectedSavedAddress;

  // Razorpay must be kept alive for the lifetime of this screen — a transient
  // instance can be garbage-collected before the payment result arrives, so its
  // success/error callbacks silently never fire. The pending-order context is
  // stashed here when the sheet opens and read back in the result handlers.
  late final Razorpay _razorpay;
  CheckoutProvider? _pendingCheckout;
  CartProvider? _pendingCartProvider;
  List<Map<String, dynamic>>? _pendingItems;
  String? _pendingCoupon;
  String _pendingCustomerName = '';
  String _pendingCustomerEmail = '';
  String _pendingCustomerPhone = '';

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initCheckoutDefaults());
  }

  /// Sets up the checkout defaults: re-fetch store settings, load saved
  /// addresses, and — once they're available — default to the saved (default)
  /// address with its phone pre-filled. The user can still switch to "New
  /// Address". Awaiting the load matters: addresses arrive asynchronously, so
  /// reading them synchronously would miss them and wrongly show the new-address
  /// form on first open.
  Future<void> _initCheckoutDefaults() async {
    if (!mounted) return;
    context.read<CheckoutProvider>().reset();
    context.read<StoreSettingsProvider>().loadSettings(force: true);
    final profileProvider = context.read<UserProfileProvider>();
    if (!profileProvider.isInitialized) {
      await profileProvider.loadAddresses();
    }
    if (!mounted) return;
    final addresses = profileProvider.addresses;
    final authPhone = context.read<AuthProvider>().userPhone;
    if (addresses.isNotEmpty) {
      final defaultAddr = profileProvider.defaultAddress ?? addresses.first;
      setState(() {
        _useSavedAddress = true;
        _selectedSavedAddress = defaultAddr;
        _phoneController.text = _stripPhonePrefix(
          defaultAddr.phone.isNotEmpty ? defaultAddr.phone : (authPhone ?? ''),
        );
      });
      context.read<CheckoutProvider>().setAddress(defaultAddr);
    } else if (authPhone != null && authPhone.isNotEmpty) {
      setState(() => _phoneController.text = _stripPhonePrefix(authPhone));
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _apartmentController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _updatesEmailController.dispose();
    super.dispose();
  }

  /// Strips a leading "+91 " (and stray spaces) so the contact field shows the
  /// bare 10-digit number that the +91 prefix in the UI expects.
  String _stripPhonePrefix(String phone) =>
      phone.replaceFirst('+91', '').trim();

  /// The last 10 digits of a phone string (drops "+91", spaces, etc.) — the
  /// safe form for Razorpay's prefill.contact.
  String _bareContact(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length > 10 ? digits.substring(digits.length - 10) : digits;
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
    final authProvider = context.read<AuthProvider>();
    final profileProvider = context.read<UserProfileProvider>();
    final cart = cartProvider.cart;

    // If the user opted into email updates, the email must be verified first.
    if (_wantsEmailUpdates == true && !_updatesEmailVerified) {
      _showCheckoutSnack('Please verify your email to get updates, or choose "No".');
      return;
    }

    // Send order emails (confirmation + invoice) ONLY when the user opted into
    // email updates AND verified the address. If they chose "No" (or left it
    // unset), pass an empty email so the backend skips the confirmation/invoice
    // email entirely.
    final orderEmail = (_wantsEmailUpdates == true && _updatesEmailVerified)
        ? _updatesEmailController.text.trim()
        : '';

    UserAddress? address;

    if (_useSavedAddress && _selectedSavedAddress != null) {
      // The backend requires a contact number on every order, and a saved
      // address may not carry one — so the Contact field is mandatory here too.
      if (_phoneController.text.trim().length != 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please enter a valid 10-digit mobile number'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        return;
      }
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

    // Build items list — Buy-Now uses only the chosen product, never the cart.
    // Backend's validateAndCalculateOrder reads `productId` (camelCase) — the
    // payment/cod endpoints recompute prices server-side from this.
    final orderItems = _effectiveItems(cart).map((item) {
      return {
        'productId': item.product.id,
        'quantity': item.quantity,
      };
    }).toList();

    final deliveryOption = checkoutProvider.deliveryOption == DeliveryOption.express
        ? 'express'
        : 'standard';

    try {
      if (checkoutProvider.paymentMethod == PaymentMethod.cod) {
        // COD — create the order through the secure endpoint that validates
        // stock and computes totals server-side (same flow the online path
        // uses). The older /orders endpoint expected flat shipping fields +
        // client-supplied totals and silently produced null-address orders.
        final result = await SecureApiService().createOrder(
          items: orderItems,
          customerName: address.fullName,
          customerEmail: orderEmail,
          // Prefer the number the user typed in the Contact field; fall back to
          // the saved address's phone when they left it untouched.
          customerPhone: _phoneController.text.trim().length == 10
              ? '+91 ${_phoneController.text.trim()}'
              : address.phone,
          shippingAddressLine1: address.addressLine1,
          shippingCity: address.city,
          shippingState: address.state,
          shippingPincode: address.pincode,
          paymentMethod: 'cod',
          couponCode: cart.appliedCouponCode,
          deliveryOption: deliveryOption,
        );

        final orderNumber = result['orderNumber'];
        final orderDbId = result['orderId'];
        // A Buy-Now order never touched the cart, so leave the cart intact.
        if (widget.buyNowProduct == null) cartProvider.clearCart();
        if (mounted) {
          context.go('/shop/order-success/$orderNumber?oid=$orderDbId');
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

        // Open Razorpay payment sheet. Pass the customer details captured from
        // the form/profile — the /verify endpoint requires them to create the
        // order after payment succeeds.
        if (mounted) {
          _openRazorpayWeb(
            checkout: checkoutProvider,
            cartProvider: cartProvider,
            orderItems: orderItems,
            couponCode: cart.appliedCouponCode,
            customerName: address.fullName,
            customerEmail: orderEmail,
            customerPhone: _phoneController.text.trim().length == 10
                ? '+91 ${_phoneController.text.trim()}'
                : address.phone,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyOrderError(e)),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
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
    required String customerName,
    required String customerEmail,
    required String customerPhone,
  }) {
    // Stash the context the result handlers need. They run later (after the
    // user returns from the Razorpay sheet) so they can't rely on locals.
    _pendingCheckout = checkout;
    _pendingCartProvider = cartProvider;
    _pendingItems = orderItems;
    _pendingCoupon = couponCode;
    _pendingCustomerName = customerName;
    _pendingCustomerEmail = customerEmail;
    _pendingCustomerPhone = customerPhone;

    final options = {
      'key': checkout.razorpayKeyId ?? '',
      'amount': checkout.razorpayAmount ?? 0,
      'currency': 'INR',
      'name': 'Arasan Mobiles',
      'description': 'Order Payment',
      'order_id': checkout.razorpayOrderId ?? '',
      // Razorpay's checkout can fail to load ("Something went wrong") on a
      // malformed prefill.contact — anything other than a bare number (a "+91 "
      // label, spaces, country code) is risky. Send only the last 10 digits,
      // and omit any prefill field we don't actually have.
      'prefill': {
        if (customerName.trim().isNotEmpty) 'name': customerName.trim(),
        if (customerEmail.trim().isNotEmpty) 'email': customerEmail.trim(),
        if (_bareContact(customerPhone).isNotEmpty)
          'contact': _bareContact(customerPhone),
      },
      'theme': {
        'color': '#D32F2F',
      },
    };

    _razorpay.open(options);
  }

  Future<void> _onPaymentSuccess(PaymentSuccessResponse response) async {
    final checkout = _pendingCheckout;
    final cartProvider = _pendingCartProvider;
    final items = _pendingItems;
    if (checkout == null || cartProvider == null || items == null) return;

    final orderData = await checkout.verifyPaymentAndCreateOrder(
      razorpayPaymentId: response.paymentId ?? '',
      razorpaySignature: response.signature ?? '',
      items: items,
      customerName: _pendingCustomerName,
      customerEmail: _pendingCustomerEmail,
      customerPhone: _pendingCustomerPhone,
      couponCode: _pendingCoupon,
    );

    if (!mounted) return;
    if (orderData != null) {
      // Buy-Now never added to the cart, so don't wipe it.
      if (widget.buyNowProduct == null) cartProvider.clearCart();
      checkout.reset();
      context.go(
          '/shop/order-success/${orderData['orderNumber']}?oid=${orderData['orderId']}');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(checkout.paymentError != null
              ? friendlyOrderError(checkout.paymentError!)
              : 'Payment verification failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment failed: ${response.message ?? 'Cancelled'}'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    // No external-wallet handling needed; the order completes via the standard
    // success/verify flow.
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
        // No header at all — the "Checkout" title sits at the top of the
        // scrollable form. SafeArea keeps it clear of the status bar / notch.
        body: SafeArea(
          child: checkoutProvider.isProcessing
              ? _buildProcessingOverlay()
              : isWide
                  ? _buildWideLayout(cart, checkoutProvider)
                  : _buildNarrowLayout(cart, checkoutProvider),
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
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: _buildFormSectionCompact(checkoutProvider),
                ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Just the page title — no "Home > Your shopping cart > Checkout".
          const Text(
            'Checkout',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 20),
          // Order Summary (Products) at top on mobile
          _buildOrderSummary(cart, checkoutProvider),
          const SizedBox(height: 20),
          // Form — all sections (contact, address, updates, payment) in one box.
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: _buildFormSection(checkoutProvider),
          ),
          const SizedBox(height: 24),
          // Place order button
          _buildPlaceOrderButton(checkoutProvider),
          const SizedBox(height: 24),
        ],
      ),
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
            enabled: true,
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

          // ── Get updates by email ──
          _buildEmailUpdatesSection(),
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
            enabled: true,
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

          // ── Get updates by email ──
          _buildEmailUpdatesSection(),
          const SizedBox(height: 16),

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
                setState(() {
                  _selectedSavedAddress = address;
                  _phoneController.text = _stripPhonePrefix(address.phone);
                });
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
    // Buy-Now → just the chosen product; otherwise the live cart.
    final items = _effectiveItems(cartData);
    final subtotal = _effectiveSubtotal(cartData);
    final coupon = _effectiveCoupon(cartData);
    final standardDelivery = settings.deliveryChargeFor(subtotal);
    final deliveryCharge =
        checkoutProvider.deliveryOption == DeliveryOption.express
            ? standardDelivery + checkoutProvider.expressSurcharge
            : standardDelivery;
    final tax = settings.taxFor(subtotal);
    final total = subtotal - coupon + deliveryCharge + tax;

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
                  'Order Summary',
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
                    '${items.length}'.padLeft(2, '0'),
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
          ...items.map(
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
                  CurrencyFormatter.format(subtotal),
                ),
                if (coupon > 0) ...[
                  const SizedBox(height: 8),
                  _buildPriceRow(
                    'Coupon Discount',
                    '- ${CurrencyFormatter.format(coupon)}',
                    valueColor: AppColors.success,
                  ),
                ],
                const SizedBox(height: 8),
                _buildPriceRow(
                  'Shipping',
                  deliveryCharge == 0
                      ? 'Free'
                      : CurrencyFormatter.format(deliveryCharge),
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
          // Price block — effective price, struck original, and the offer %
          // shown HERE (in the pricing place) as a bold, distinct-colour chip
          // instead of a badge on the image.
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.format(item.totalPrice),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              if (item.product.hasDiscount) ...[
                const SizedBox(height: 2),
                Text(
                  CurrencyFormatter.format(item.totalOriginalPrice),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6D00).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${item.product.discountPercent.toInt()}% OFF',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFF6D00),
                    ),
                  ),
                ),
              ],
            ],
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

  /// The account's existing real email (empty for phone-only/synthetic). This
  /// is already verified (e.g. from Google sign-in) so it needs no OTP.
  String _realProfileEmail() {
    final raw = context.read<UserProfileProvider>().profile.email.trim();
    if (raw.isEmpty) return '';
    if (raw.toLowerCase().endsWith('@phone.arasanmobiles.invalid')) return '';
    return raw;
  }

  /// Centered "Get updates by email" opt-in shown between the delivery address
  /// and payment sections. Yes reveals an email box that must be verified
  /// (existing account email is trusted; any changed email needs an OTP).
  Widget _buildEmailUpdatesSection() {
    _trustedEmail = _realProfileEmail().toLowerCase();
    final wants = _wantsEmailUpdates == true;
    final verified = _updatesEmailVerified;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Heading on the left (like "Delivery Address") + Yes/No on the right.
        Row(
          children: [
            const Expanded(
              child: Text(
                'Get updates by email',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            _buildYesNoChip(
              label: 'Yes',
              selected: _wantsEmailUpdates == true,
              onTap: () {
                setState(() {
                  _wantsEmailUpdates = true;
                  // Prefill the account's email once (e.g. the Google address).
                  if (!_emailPrefilled &&
                      _updatesEmailController.text.trim().isEmpty) {
                    final real = _realProfileEmail();
                    if (real.isNotEmpty) _updatesEmailController.text = real;
                    _emailPrefilled = true;
                  }
                });
              },
            ),
            const SizedBox(width: 8),
            _buildYesNoChip(
              label: 'No',
              selected: _wantsEmailUpdates == false,
              onTap: () => setState(() => _wantsEmailUpdates = false),
            ),
          ],
        ),
        if (wants) ...[
          const SizedBox(height: 10),
          // Email box with a compact "Verify" / "Verified" marker inside, right.
          TextFormField(
            controller: _updatesEmailController,
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Enter your email',
              hintStyle: const TextStyle(fontSize: 14, color: AppColors.textHint),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              suffixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(left: 8, right: 12),
                child: verified
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.check_circle,
                              size: 16, color: AppColors.success),
                          SizedBox(width: 4),
                          Text(
                            'Verified',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      )
                    : _sendingEmailOtp
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : GestureDetector(
                            onTap: _verifyUpdatesEmail,
                            child: const Text(
                              'Verify',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildYesNoChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  void _showCheckoutSnack(String message, {bool error = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Sends an OTP to the typed email then opens the code-entry dialog. Requires
  /// login (the backend scopes the code to the authenticated user).
  Future<void> _verifyUpdatesEmail() async {
    final email = _updatesEmailController.text.trim();
    final emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRe.hasMatch(email)) {
      _showCheckoutSnack('Please enter a valid email address');
      return;
    }

    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn || auth.authToken == null) {
      final ok = await LoginDialog.showWithMessage(
        context,
        'Please login to verify your email',
      );
      if (!ok || !mounted) return;
    }

    setState(() => _sendingEmailOtp = true);
    try {
      await AuthApiService().sendEmailOtp(email);
    } catch (e) {
      if (mounted) {
        setState(() => _sendingEmailOtp = false);
        _showCheckoutSnack(e.toString());
      }
      return;
    }
    if (!mounted) return;
    setState(() => _sendingEmailOtp = false);
    await _showOtpDialog(email);
  }

  /// Modal to enter the 6-digit code and verify it. On success the email is
  /// recorded as verified (and saved to the account by the backend).
  Future<void> _showOtpDialog(String email) async {
    final codeController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        bool verifying = false;
        String? errorText;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Verify your email'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enter the 6-digit code sent to $email',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    autofocus: true,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 6,
                    ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '••••••',
                      errorText: errorText,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: verifying ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: verifying
                      ? null
                      : () async {
                          final code = codeController.text.trim();
                          if (code.length != 6) {
                            setDialogState(() => errorText = 'Enter the 6-digit code');
                            return;
                          }
                          setDialogState(() {
                            verifying = true;
                            errorText = null;
                          });
                          try {
                            await AuthApiService()
                                .verifyEmailOtp(email: email, code: code);
                            if (!mounted) return;
                            _verifiedEmails.add(email.toLowerCase());
                            // Refresh the profile so the saved email is reflected.
                            context.read<UserProfileProvider>().loadProfile();
                            Navigator.pop(dialogContext);
                            setState(() {});
                            _showCheckoutSnack('Email verified', error: false);
                          } catch (e) {
                            setDialogState(() {
                              verifying = false;
                              errorText = e.toString();
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: verifying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Verify'),
                ),
              ],
            );
          },
        );
      },
    );
    codeController.dispose();
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
    void Function(String)? onChanged,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
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
