import 'api_service.dart';

class AddressApiService {
  final ApiService _api = ApiService();

  /// Get all addresses
  Future<List<Address>> getAddresses() async {
    final response = await _api.get('/addresses', requireAuth: true);
    return (response['addresses'] as List)
        .map((json) => Address.fromJson(json))
        .toList();
  }

  /// Get address by ID
  Future<Address> getAddressById(String id) async {
    final response = await _api.get('/addresses/$id', requireAuth: true);
    return Address.fromJson(response['address']);
  }

  /// Get default address
  Future<Address?> getDefaultAddress() async {
    final response = await _api.get('/addresses/default', requireAuth: true);
    if (response['address'] == null) return null;
    return Address.fromJson(response['address']);
  }

  /// Add new address
  Future<AddressResponse> addAddress(AddressInput input) async {
    final response = await _api.post('/addresses',
      body: input.toJson(),
      requireAuth: true,
    );
    return AddressResponse.fromJson(response);
  }

  /// Update address
  Future<AddressResponse> updateAddress(String id, AddressInput input) async {
    final response = await _api.patch('/addresses/$id',
      body: input.toJson(),
      requireAuth: true,
    );
    return AddressResponse.fromJson(response);
  }

  /// Set address as default
  Future<AddressResponse> setDefaultAddress(String id) async {
    final response = await _api.patch('/addresses/$id/set-default',
      requireAuth: true,
    );
    return AddressResponse.fromJson(response);
  }

  /// Delete address
  Future<void> deleteAddress(String id) async {
    await _api.delete('/addresses/$id', requireAuth: true);
  }
}

/// Address model
class Address {
  final String id;
  final String name;
  final String phone;
  final String line1;
  final String? line2;
  final String city;
  final String state;
  final String pincode;
  final String country;
  final AddressType type;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  Address({
    required this.id,
    required this.name,
    required this.phone,
    required this.line1,
    this.line2,
    required this.city,
    required this.state,
    required this.pincode,
    this.country = 'India',
    this.type = AddressType.home,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      line1: json['line1'],
      line2: json['line2'],
      city: json['city'],
      state: json['state'],
      pincode: json['pincode'],
      country: json['country'] ?? 'India',
      type: AddressType.fromString(json['type']),
      isDefault: json['is_default'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'line1': line1,
    'line2': line2,
    'city': city,
    'state': state,
    'pincode': pincode,
    'country': country,
    'type': type.value,
    'is_default': isDefault,
  };

  String get fullAddress {
    final parts = [line1];
    if (line2 != null && line2!.isNotEmpty) parts.add(line2!);
    parts.addAll([city, state, pincode]);
    return parts.join(', ');
  }

  Address copyWith({
    String? id,
    String? name,
    String? phone,
    String? line1,
    String? line2,
    String? city,
    String? state,
    String? pincode,
    String? country,
    AddressType? type,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Address(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      line1: line1 ?? this.line1,
      line2: line2 ?? this.line2,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      country: country ?? this.country,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Address input for creating/updating
class AddressInput {
  final String name;
  final String phone;
  final String line1;
  final String? line2;
  final String city;
  final String state;
  final String pincode;
  final String country;
  final AddressType type;
  final bool isDefault;

  AddressInput({
    required this.name,
    required this.phone,
    required this.line1,
    this.line2,
    required this.city,
    required this.state,
    required this.pincode,
    this.country = 'India',
    this.type = AddressType.home,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'line1': line1,
    'line2': line2,
    'city': city,
    'state': state,
    'pincode': pincode,
    'country': country,
    'type': type.value,
    'is_default': isDefault,
  };
}

/// Address type enum
enum AddressType {
  home('home'),
  work('work'),
  other('other');

  final String value;
  const AddressType(this.value);

  static AddressType fromString(String? value) {
    switch (value) {
      case 'home':
        return AddressType.home;
      case 'work':
        return AddressType.work;
      case 'other':
        return AddressType.other;
      default:
        return AddressType.home;
    }
  }

  String get displayName {
    switch (this) {
      case AddressType.home:
        return 'Home';
      case AddressType.work:
        return 'Work';
      case AddressType.other:
        return 'Other';
    }
  }
}

/// Address operation response
class AddressResponse {
  final Address address;
  final String message;

  AddressResponse({required this.address, required this.message});

  factory AddressResponse.fromJson(Map<String, dynamic> json) {
    return AddressResponse(
      address: Address.fromJson(json['address']),
      message: json['message'] ?? '',
    );
  }
}
