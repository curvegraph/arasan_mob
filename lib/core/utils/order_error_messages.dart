/// Convert raw exceptions thrown during checkout into a short, user-friendly
/// sentence we can put on a SnackBar.
///
/// The server-side trigger `validate_order_payment_method` raises errors with
/// clean human messages ("Cash on Delivery is currently disabled" /
/// "Online payment is currently disabled"). When those propagate through the
/// Edge Function and the supabase client, they end up wrapped in
/// `PostgrestException`, `FunctionException`, or a plain `Exception` — so the
/// raw `e.toString()` is something like:
///   `PostgrestException(message: Cash on Delivery is currently disabled, ...)`
/// We extract the inner message so the user sees only the clean part.
String friendlyOrderError(Object error) {
  final raw = error.toString();

  // Trigger-rejected payment methods — match by phrase to be resilient to
  // whatever wrapper the SDK puts around the message.
  if (raw.contains('Cash on Delivery is currently disabled')) {
    return 'Cash on Delivery is currently unavailable. Please choose another payment method.';
  }
  if (raw.contains('Online payment is currently disabled')) {
    return 'Online payment is currently unavailable. Please choose Cash on Delivery.';
  }

  // Session expired / not authenticated — the request is rejected (or never
  // sent) because there's no valid JWT. Tell the user to log in again rather
  // than showing the generic "try again".
  if (raw.contains('Authentication required') ||
      raw.contains('Authorization token required') ||
      raw.toLowerCase().contains('unauthorized') ||
      raw.contains('statusCode: 401')) {
    return 'Your session has expired. Please log in again to place your order.';
  }

  // Out-of-stock / coupon errors come back as plain text already.
  if (raw.toLowerCase().contains('out of stock')) {
    return 'One or more items in your cart are out of stock.';
  }
  if (raw.toLowerCase().contains('coupon')) {
    return 'There was a problem with the coupon. Please remove it and try again.';
  }

  // Generic fallback — never expose the stack trace or class name to the user.
  return 'We couldn\'t place your order. Please try again.';
}
