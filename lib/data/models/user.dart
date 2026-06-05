class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? avatarUrl;
  final List<Address> addresses;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.avatarUrl,
    this.addresses = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Address? get defaultAddress =>
      addresses.isEmpty ? null : addresses.firstWhere((a) => a.isDefault, orElse: () => addresses.first);
}

class Address {
  final String id;
  final String name;
  final String phone;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String pincode;
  final bool isDefault;

  Address({
    required this.id,
    required this.name,
    required this.phone,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.pincode,
    this.isDefault = false,
  });

  String get fullAddress =>
      '$addressLine1${addressLine2 != null ? ', $addressLine2' : ''}, $city, $state - $pincode';
}
