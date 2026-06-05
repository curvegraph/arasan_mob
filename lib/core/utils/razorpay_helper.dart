import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayHelper {
  static void openCheckout({
    required Map<String, dynamic> options,
    required Function(String paymentId, String orderId, String signature) onSuccess,
    required Function(String message) onError,
  }) {
    final razorpay = Razorpay();

    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse response) {
      onSuccess(
        response.paymentId ?? '',
        response.orderId ?? '',
        response.signature ?? '',
      );
      razorpay.clear();
    });

    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) {
      onError(response.message ?? 'Payment failed');
      razorpay.clear();
    });

    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse response) {
      razorpay.clear();
    });

    razorpay.open(options);
  }
}
