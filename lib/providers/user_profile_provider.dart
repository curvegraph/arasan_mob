import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/user_profile.dart';
import '../data/models/address.dart';
import '../data/services/api_service.dart';

/// Holds profile + addresses fetched from the backend.
///
/// All identity (name/email/phone/id) comes from `GET /api/auth/me`. We never
/// trust `Supabase.instance.client.auth.currentUser` metadata as the display
/// source — that's how stale OAuth metadata bleeds into the UI.
///
/// Supabase auth events are still observed, but only as a *trigger* to refetch
/// from the backend. The session's existence tells us "have a token to send";
/// the backend's response tells us "who you actually are".
class UserProfileProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ApiService _api = ApiService();
  StreamSubscription<AuthState>? _authSubscription;

  UserProfile _profile = UserProfile(
    id: '',
    name: '',
    email: '',
    phone: '',
    addresses: [],
  );
  bool _isLoading = false;
  bool _isInitialized = false;

  UserProfileProvider() {
    _initAuthListener();
  }

  void _initAuthListener() {
    if (_supabase.auth.currentSession != null) {
      loadProfile();
    }
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      if (data.session != null) {
        loadProfile();
      } else {
        clear();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  UserProfile get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  List<UserAddress> get addresses => _profile.addresses;

  UserAddress? get defaultAddress {
    if (_profile.addresses.isEmpty) return null;
    return _profile.addresses.firstWhere(
      (a) => a.isDefault,
      orElse: () => _profile.addresses.first,
    );
  }

  /// Fetch the canonical profile from the backend and reload addresses.
  Future<void> loadProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _api.get('/auth/me', requireAuth: true);
      Map<String, dynamic>? user;
      if (data is Map) {
        if (data['user'] is Map) {
          user = Map<String, dynamic>.from(data['user'] as Map);
        } else {
          user = Map<String, dynamic>.from(data);
        }
      }

      if (user == null || user['id'] == null) {
        // Backend has no record of us — drop local state.
        clear();
        return;
      }

      _profile = UserProfile(
        id: user['id'] as String? ?? '',
        name: user['name'] as String? ?? '',
        email: user['email'] as String? ?? '',
        phone: user['phone'] as String? ?? '',
        addresses: _profile.addresses,
      );
      _isInitialized = true;
      notifyListeners();

      await loadAddresses();
    } on ApiException catch (e) {
      debugPrint('UserProfileProvider.loadProfile: $e');
      if (e.statusCode == 401 || e.statusCode == 403) {
        clear();
      }
    } catch (e) {
      debugPrint('UserProfileProvider.loadProfile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAddresses() async {
    try {
      final data = await _api.get('/addresses', requireAuth: true);
      final list = (data is Map && data['addresses'] is List)
          ? data['addresses'] as List
          : (data is List ? data : const []);
      final addresses = list
          .whereType<Map>()
          .map((e) => UserAddress.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      _profile = _profile.copyWith(addresses: addresses);
      notifyListeners();
    } on ApiException catch (e) {
      // 401/403 → just leave addresses empty; loadProfile() handles signout.
      debugPrint('UserProfileProvider.loadAddresses: $e');
    } catch (e) {
      debugPrint('UserProfileProvider.loadAddresses: $e');
    }
  }

  /// Initialize from auth data (kept for callers that pass id/name/email/phone
  /// directly). Triggers a backend refresh so the canonical state still wins.
  Future<void> initFromAuth({
    required String id,
    String? name,
    String? email,
    String? phone,
  }) async {
    _profile = UserProfile(
      id: id,
      name: name ?? '',
      email: email ?? '',
      phone: phone ?? '',
      addresses: [],
    );
    notifyListeners();
    await loadProfile();
  }

  Future<void> updateProfile({
    String? name,
    String? email,
    String? phone,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _api.patch('/auth/profile',
          body: {
            if (name != null) 'name': name,
            if (email != null) 'email': email,
            if (phone != null) 'phone': phone,
          },
          requireAuth: true);

      _profile = _profile.copyWith(
        name: name ?? _profile.name,
        email: email ?? _profile.email,
        phone: phone ?? _profile.phone,
      );
    } catch (e) {
      debugPrint('UserProfileProvider.updateProfile: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set (or replace) the user's default address using the simple form in
  /// My Details. Creates a new address if no default exists; updates the
  /// existing default otherwise.
  Future<void> upsertDefaultAddress({
    required String fullName,
    required String phone,
    required String addressLine1,
    String? addressLine2,
    required String city,
    required String state,
    required String pincode,
  }) async {
    final existing = defaultAddress;
    if (existing == null) {
      await addAddress(UserAddress(
        id: '',
        label: 'Home',
        fullName: fullName,
        phone: phone,
        addressLine1: addressLine1,
        addressLine2: addressLine2,
        city: city,
        state: state,
        pincode: pincode,
        isDefault: true,
      ));
    } else {
      await updateAddress(existing.copyWith(
        fullName: fullName,
        phone: phone,
        addressLine1: addressLine1,
        addressLine2: addressLine2,
        city: city,
        state: state,
        pincode: pincode,
        isDefault: true,
      ));
    }
  }

  Map<String, dynamic> _addressBody(UserAddress address) => {
        'label': address.label,
        'name': address.fullName,
        'phone': address.phone,
        'addressLine1': address.addressLine1,
        'addressLine2': address.addressLine2,
        'city': address.city,
        'state': address.state,
        'pincode': address.pincode,
        'isDefault': address.isDefault,
      };

  Future<void> addAddress(UserAddress address) async {
    _isLoading = true;
    notifyListeners();

    try {
      final body = _addressBody(address);
      if (_profile.addresses.isEmpty) body['isDefault'] = true;

      final res = await _api.post('/addresses', body: body, requireAuth: true);
      final m = (res is Map && res['address'] is Map)
          ? Map<String, dynamic>.from(res['address'] as Map)
          : Map<String, dynamic>.from(res as Map);
      final newAddress = UserAddress.fromJson(m);

      List<UserAddress> updatedAddresses = List.from(_profile.addresses);
      if (newAddress.isDefault) {
        updatedAddresses = updatedAddresses
            .map((a) => a.copyWith(isDefault: false))
            .toList();
      }
      updatedAddresses.insert(0, newAddress);
      _profile = _profile.copyWith(addresses: updatedAddresses);
    } catch (_) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateAddress(UserAddress address) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _api.patch('/addresses/${address.id}',
          body: _addressBody(address), requireAuth: true);

      List<UserAddress> updatedAddresses = List.from(_profile.addresses);
      if (address.isDefault) {
        updatedAddresses = updatedAddresses
            .map((a) => a.copyWith(isDefault: false))
            .toList();
      }
      final index = updatedAddresses.indexWhere((a) => a.id == address.id);
      if (index >= 0) {
        updatedAddresses[index] = address;
      }
      _profile = _profile.copyWith(addresses: updatedAddresses);
    } catch (_) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeAddress(String addressId) async {
    try {
      await _api.delete('/addresses/$addressId', requireAuth: true);
      final updatedAddresses = List<UserAddress>.from(_profile.addresses)
        ..removeWhere((a) => a.id == addressId);
      _profile = _profile.copyWith(addresses: updatedAddresses);
      notifyListeners();
    } catch (_) {
      rethrow;
    }
  }

  Future<void> setDefaultAddress(String addressId) async {
    try {
      await _api.patch('/addresses/$addressId/set-default', requireAuth: true);
      final updatedAddresses = _profile.addresses
          .map((a) => a.copyWith(isDefault: a.id == addressId))
          .toList();
      _profile = _profile.copyWith(addresses: updatedAddresses);
      notifyListeners();
    } catch (_) {
      rethrow;
    }
  }

  void clear() {
    _profile = UserProfile(
      id: '',
      name: '',
      email: '',
      phone: '',
      addresses: [],
    );
    _isInitialized = false;
    notifyListeners();
  }
}
