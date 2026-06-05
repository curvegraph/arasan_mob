class Validators {
  Validators._();

  static String? required(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return 'Enter a valid email';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone is required';
    final phoneRegex = RegExp(r'^[6-9]\d{9}$');
    if (!phoneRegex.hasMatch(value)) return 'Enter a valid 10-digit phone';
    return null;
  }

  static String? price(String? value) {
    if (value == null || value.trim().isEmpty) return 'Price is required';
    final price = double.tryParse(value);
    if (price == null || price <= 0) return 'Enter a valid price';
    return null;
  }

  static String? percentage(String? value) {
    if (value == null || value.trim().isEmpty) return 'Value is required';
    final pct = double.tryParse(value);
    if (pct == null || pct < 0 || pct > 100) return 'Enter 0-100';
    return null;
  }

  static String? otp(String? value) {
    if (value == null || value.trim().isEmpty) return 'OTP is required';
    final otpRegex = RegExp(r'^\d{6}$');
    if (!otpRegex.hasMatch(value)) return 'Enter a valid 6-digit OTP';
    return null;
  }

  static String? pincode(String? value) {
    if (value == null || value.trim().isEmpty) return 'Pincode is required';
    final pincodeRegex = RegExp(r'^\d{6}$');
    if (!pincodeRegex.hasMatch(value)) return 'Enter a valid 6-digit pincode';
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    if (value.trim().length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.trim().isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? address(String? value) {
    if (value == null || value.trim().isEmpty) return 'Address is required';
    if (value.trim().length < 10) return 'Please enter complete address';
    return null;
  }
}
