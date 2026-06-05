import 'address.dart';

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? avatarUrl;
  final List<UserAddress> addresses;
  final DateTime joinedAt;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.avatarUrl,
    this.addresses = const [],
    DateTime? joinedAt,
  }) : joinedAt = joinedAt ?? DateTime.now();

  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    List<UserAddress>? addresses,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      addresses: addresses ?? this.addresses,
      joinedAt: joinedAt,
    );
  }

  UserAddress? get defaultAddress {
    try {
      return addresses.firstWhere((a) => a.isDefault);
    } catch (_) {
      return addresses.isNotEmpty ? addresses.first : null;
    }
  }
}
