import 'package:flutter/foundation.dart';
import '../data/models/address.dart';
import '../data/services/secure_api_service.dart';

enum DeliveryOption { standard, express }

/// Payment methods recorded on orders.
/// * [online] — unified online payment via Razorpay (UPI / card / netbanking,
///   user picks inside the Razorpay sheet).
/// * [cod] — Cash on Delivery.
/// * [upi] / [card] are legacy values kept so old orders still deserialize.
enum PaymentMethod { online, cod, upi, card }

enum PaymentStatus { idle, processing, success, failed }

class CheckoutProvider extends ChangeNotifier {
  final List<UserAddress> _addresses = [];
  UserAddress? _selectedAddress;
  DeliveryOption _deliveryOption = DeliveryOption.standard;
  PaymentMethod _paymentMethod = PaymentMethod.online;
  bool _isProcessing = false;
  int _currentStep = 0;
  PaymentStatus _paymentStatus = PaymentStatus.idle;
  String? _paymentError;
  String? _transactionId;

  // Razorpay order data (from server)
  String? _razorpayOrderId;
  String? _razorpayKeyId;
  int? _razorpayAmount;
  String? _customerName;
  String? _customerEmail;
  String? _customerPhone;

  UserAddress? get selectedAddress => _selectedAddress;
  DeliveryOption get deliveryOption => _deliveryOption;
  PaymentMethod get paymentMethod => _paymentMethod;
  bool get isProcessing => _isProcessing;
  int get currentStep => _currentStep;
  List<UserAddress> get addresses => List.unmodifiable(_addresses);
  PaymentStatus get paymentStatus => _paymentStatus;
  String? get paymentError => _paymentError;
  String? get transactionId => _transactionId;

  // Razorpay getters
  String? get razorpayOrderId => _razorpayOrderId;
  String? get razorpayKeyId => _razorpayKeyId;
  int? get razorpayAmount => _razorpayAmount;
  String? get customerName => _customerName;
  String? get customerEmail => _customerEmail;
  String? get customerPhone => _customerPhone;

  /// Flat surcharge added on top of the standard delivery charge when the
  /// user picks express. Standard delivery itself is admin-configured and
  /// pulled from [StoreSettingsProvider.deliveryChargeFor] at the UI layer.
  double get expressSurcharge => _deliveryOption == DeliveryOption.express ? 99 : 0;

  /// Legacy getter — kept so any caller that still reads it doesn't crash.
  /// Returns only the express surcharge (not including admin's base charge),
  /// because the base charge depends on cart subtotal which this provider
  /// doesn't know about. UI should compute the full delivery via
  /// [StoreSettingsProvider.deliveryChargeFor] + [expressSurcharge].
  @Deprecated('Use StoreSettingsProvider.deliveryChargeFor + expressSurcharge')
  double get deliveryCharge => expressSurcharge;

  String get deliveryEstimate {
    return _deliveryOption == DeliveryOption.express
        ? '1-2 business days'
        : '3-5 business days';
  }

  String get paymentMethodLabel {
    switch (_paymentMethod) {
      case PaymentMethod.online:
        return 'Online';
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.cod:
        return 'COD';
    }
  }

  /// Lowercase value matching the database enum.
  String get paymentMethodValue {
    switch (_paymentMethod) {
      case PaymentMethod.online:
        return 'online';
      case PaymentMethod.upi:
        return 'upi';
      case PaymentMethod.card:
        return 'card';
      case PaymentMethod.cod:
        return 'cod';
    }
  }

  /// True when this method requires an external gateway (Razorpay) flow
  /// rather than a "create COD order directly" flow.
  bool get requiresOnlinePayment =>
      _paymentMethod == PaymentMethod.online ||
      _paymentMethod == PaymentMethod.upi ||
      _paymentMethod == PaymentMethod.card;

  void addAddress(UserAddress address) {
    if (address.isDefault) {
      _clearDefaultFlag();
    }
    _addresses.add(address);
    notifyListeners();
  }

  void updateAddress(UserAddress address) {
    if (address.isDefault) {
      _clearDefaultFlag();
    }
    final index = _addresses.indexWhere((a) => a.id == address.id);
    if (index >= 0) {
      _addresses[index] = address;
    }
    if (_selectedAddress?.id == address.id) {
      _selectedAddress = address;
    }
    notifyListeners();
  }

  void removeAddress(String addressId) {
    _addresses.removeWhere((a) => a.id == addressId);
    if (_selectedAddress?.id == addressId) {
      _selectedAddress = _addresses.isNotEmpty ? _addresses.first : null;
    }
    notifyListeners();
  }

  void _clearDefaultFlag() {
    for (int i = 0; i < _addresses.length; i++) {
      if (_addresses[i].isDefault) {
        _addresses[i] = _addresses[i].copyWith(isDefault: false);
      }
    }
  }

  void setAddress(UserAddress address) {
    _selectedAddress = address;
    notifyListeners();
  }

  void setDeliveryOption(DeliveryOption option) {
    _deliveryOption = option;
    notifyListeners();
  }

  void setPaymentMethod(PaymentMethod method) {
    _paymentMethod = method;
    notifyListeners();
  }

  void setStep(int step) {
    _currentStep = step;
    notifyListeners();
  }

  void nextStep() {
    if (_currentStep < 2) {
      _currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  bool _validateCheckout() {
    if (_selectedAddress == null) {
      _paymentError = 'Please select a delivery address';
      notifyListeners();
      return false;
    }
    return true;
  }

  /// Creates a Razorpay order server-side.
  /// Returns true if order was created successfully.
  /// The checkout screen should then open Razorpay payment sheet using the stored data.
  Future<bool> createRazorpayOrder({
    required List<Map<String, dynamic>> items,
    String? couponCode,
  }) async {
    if (!_validateCheckout()) return false;

    _isProcessing = true;
    _paymentStatus = PaymentStatus.processing;
    _paymentError = null;
    notifyListeners();

    try {
      final secureApi = SecureApiService();
      final data = await secureApi.createRazorpayOrder(
        items: items,
        couponCode: couponCode,
        deliveryOption: _deliveryOption == DeliveryOption.express ? 'express' : 'standard',
      );

      if (data['success'] != true || data['razorpay_order_id'] == null) {
        throw Exception(data['error'] ?? 'Failed to create payment order');
      }

      _razorpayOrderId = data['razorpay_order_id'] as String;
      _razorpayKeyId = data['razorpay_key_id'] as String;
      _razorpayAmount = data['amount'] as int;
      _customerName = data['customer_name'] as String?;
      _customerEmail = data['customer_email'] as String?;
      _customerPhone = data['customer_phone'] as String?;

      _isProcessing = false;
      notifyListeners();
      return true;
    } on SecureApiException catch (e) {
      _paymentError = e.message;
      _paymentStatus = PaymentStatus.failed;
      _isProcessing = false;
      notifyListeners();
      return false;
    } catch (e) {
      _paymentError = 'Failed to create order: ${e.toString()}';
      _paymentStatus = PaymentStatus.failed;
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }

  /// Called after Razorpay payment success.
  /// Verifies payment server-side and creates the order.
  Future<Map<String, dynamic>?> verifyPaymentAndCreateOrder({
    required String razorpayPaymentId,
    required String razorpaySignature,
    required List<Map<String, dynamic>> items,
    String? couponCode,
    String? notes,
  }) async {
    if (_razorpayOrderId == null || _selectedAddress == null) return null;

    _isProcessing = true;
    _paymentStatus = PaymentStatus.processing;
    notifyListeners();

    try {
      final secureApi = SecureApiService();
      final data = await secureApi.verifyRazorpayAndCreateOrder(
        razorpayOrderId: _razorpayOrderId!,
        razorpayPaymentId: razorpayPaymentId,
        razorpaySignature: razorpaySignature,
        items: items,
        shippingAddressLine1: _selectedAddress!.addressLine1,
        shippingCity: _selectedAddress!.city,
        shippingState: _selectedAddress!.state,
        shippingPincode: _selectedAddress!.pincode,
        paymentMethod: paymentMethodValue,
        couponCode: couponCode,
        deliveryOption: _deliveryOption == DeliveryOption.express ? 'express' : 'standard',
        notes: notes,
      );

      if (data['success'] == true) {
        _transactionId = razorpayPaymentId;
        _paymentStatus = PaymentStatus.success;
        _isProcessing = false;
        notifyListeners();
        return data['order'] as Map<String, dynamic>?;
      } else {
        throw Exception(data['error'] ?? 'Payment verification failed');
      }
    } on SecureApiException catch (e) {
      _paymentError = e.message;
      _paymentStatus = PaymentStatus.failed;
      _isProcessing = false;
      notifyListeners();
      return null;
    } catch (e) {
      _paymentError = 'Verification failed: ${e.toString()}';
      _paymentStatus = PaymentStatus.failed;
      _isProcessing = false;
      notifyListeners();
      return null;
    }
  }

  void reset() {
    _currentStep = 0;
    _deliveryOption = DeliveryOption.standard;
    _paymentMethod = PaymentMethod.online;
    _isProcessing = false;
    _paymentStatus = PaymentStatus.idle;
    _paymentError = null;
    _transactionId = null;
    _razorpayOrderId = null;
    _razorpayKeyId = null;
    _razorpayAmount = null;
    _customerName = null;
    _customerEmail = null;
    _customerPhone = null;
    final defaults = _addresses.where((a) => a.isDefault);
    _selectedAddress = defaults.isNotEmpty ? defaults.first : null;
    notifyListeners();
  }
}
