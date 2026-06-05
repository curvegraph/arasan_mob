class UserAddress {
  final String id;
  final String? customerId;
  final String label;
  final String fullName;
  final String phone;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String pincode;
  final bool isDefault;

  UserAddress({
    required this.id,
    this.customerId,
    required this.label,
    required this.fullName,
    required this.phone,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.pincode,
    this.isDefault = false,
  });

  /// Create from Supabase JSON
  factory UserAddress.fromJson(Map<String, dynamic> json) {
    return UserAddress(
      id: json['id'] as String,
      customerId: json['customer_id'] as String?,
      label: json['label'] as String? ?? 'Home',
      fullName: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      addressLine1: json['address_line1'] as String,
      addressLine2: json['address_line2'] as String?,
      city: json['city'] as String,
      state: json['state'] as String,
      pincode: json['pincode'] as String,
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  /// Convert to Supabase JSON (for insert/update)
  Map<String, dynamic> toJson({required String customerId}) {
    return {
      'customer_id': customerId,
      'label': label,
      'name': fullName,
      'phone': phone,
      'address_line1': addressLine1,
      'address_line2': addressLine2,
      'city': city,
      'state': state,
      'pincode': pincode,
      'is_default': isDefault,
    };
  }

  UserAddress copyWith({
    String? label,
    String? fullName,
    String? phone,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? pincode,
    bool? isDefault,
  }) {
    return UserAddress(
      id: id,
      label: label ?? this.label,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  String get formattedAddress {
    final parts = [addressLine1];
    if (addressLine2 != null && addressLine2!.isNotEmpty) {
      parts.add(addressLine2!);
    }
    parts.add('$city, $state - $pincode');
    return parts.join(', ');
  }
}
