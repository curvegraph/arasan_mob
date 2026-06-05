import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/config/firebase_availability.dart';
import 'core/config/supabase_config.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/phone_auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/banner_provider.dart';
import 'providers/offer_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/wishlist_provider.dart';
import 'providers/user_order_provider.dart';
import 'providers/review_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/search_provider.dart';
import 'providers/checkout_provider.dart';
import 'providers/user_profile_provider.dart';
import 'providers/support_provider.dart';
import 'providers/user_navigation_provider.dart';
import 'providers/homepage_provider.dart';
import 'providers/user_activity_provider.dart';
import 'providers/store_settings_provider.dart';

/// Secure local storage for Supabase session persistence on native platforms.
/// Uses flutter_secure_storage for encrypted storage on Android/iOS/Desktop.
class SecureLocalStorage extends LocalStorage {
  static const _sessionKey = 'supabase_session';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  String? _cachedSession;

  @override
  Future<void> initialize() async {
    // Pre-load session for faster access. If the stored blob isn't valid JSON
    // (corruption from a prior install / encryption-key reset), drop it now
    // so Supabase doesn't blow up on initial recovery.
    final stored = await _storage.read(key: _sessionKey);
    if (stored == null) {
      _cachedSession = null;
      return;
    }
    try {
      jsonDecode(stored);
      _cachedSession = stored;
    } catch (_) {
      debugPrint('SecureLocalStorage: stored session is not valid JSON, purging');
      await _storage.delete(key: _sessionKey);
      _cachedSession = null;
    }
  }

  @override
  Future<String?> accessToken() async {
    // Supabase's `LocalStorage.accessToken()` is contractually the WHOLE
    // persisted-session JSON string (Supabase parses it itself). Returning
    // only the inner access_token JWT here causes Supabase's setInitialSession
    // to throw FormatException on every boot.
    final sessionStr = _cachedSession ?? await _storage.read(key: _sessionKey);
    if (sessionStr == null) return null;
    try {
      jsonDecode(sessionStr);
      return sessionStr;
    } catch (_) {
      // Corrupted blob — purge so we don't keep crashing.
      await _storage.delete(key: _sessionKey);
      _cachedSession = null;
      return null;
    }
  }

  @override
  Future<bool> hasAccessToken() async {
    return await accessToken() != null;
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    _cachedSession = persistSessionString;
    await _storage.write(key: _sessionKey, value: persistSessionString);
  }

  @override
  Future<void> removePersistedSession() async {
    _cachedSession = null;
    await _storage.delete(key: _sessionKey);
  }

  Future<String?> getItem({required String key}) async {
    if (key == _sessionKey) return _cachedSession;
    return await _storage.read(key: key);
  }

  Future<void> setItem({required String key, required String value}) async {
    if (key == _sessionKey) _cachedSession = value;
    await _storage.write(key: key, value: value);
  }

  Future<void> removeItem({required String key}) async {
    if (key == _sessionKey) _cachedSession = null;
    await _storage.delete(key: key);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bump Flutter's decoded-image cache so scrolling back to an already-seen
  // product/banner doesn't force a re-decode. Defaults are 1000 entries /
  // 100MB which a multi-section homepage easily exceeds.
  PaintingBinding.instance.imageCache.maximumSize = 3000;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 400 << 20; // 400MB

  // Load environment variables.
  // Override at build time with --dart-define=ENV=demo to use the demo project.
  const env = String.fromEnvironment('ENV', defaultValue: 'live');
  await dotenv.load(fileName: '.env.$env');

  // Pull Supabase URL + anon key from the backend. This repo carries no
  // Supabase credentials anymore — `backend/.env` is the only source.
  await SupabaseConfig.loadFromBackend();

  // Native secure encrypted storage for Supabase session persistence.
  final secureStorage = SecureLocalStorage();
  await secureStorage.initialize();
  final LocalStorage localStorage = secureStorage;

  // Initialize Firebase for phone authentication.
  // Tolerate missing/placeholder config so the app still boots; phone login
  // simply reports itself unavailable until `flutterfire configure` is run.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseAvailability.markAvailable();
  } catch (e) {
    debugPrint('Firebase init failed (phone login will be disabled): $e');
    FirebaseAvailability.markUnavailable(e.toString());
  }

  // Initialize Supabase with persistent session storage
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
    authOptions: FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      localStorage: localStorage,
    ),
  );

  // Initialize UserActivityProvider (loads persisted data from SharedPreferences)
  final activityProvider = UserActivityProvider();
  await activityProvider.init();

  // Link SearchProvider to UserActivityProvider
  final searchProvider = SearchProvider();
  searchProvider.setActivityProvider(activityProvider);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PhoneAuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => BannerProvider()),
        ChangeNotifierProvider(create: (_) => OfferProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => UserOrderProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider.value(value: searchProvider),
        ChangeNotifierProvider(create: (_) => CheckoutProvider()),
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
        ChangeNotifierProvider(create: (_) => SupportProvider()),
        ChangeNotifierProvider(create: (_) => UserNavigationProvider()),
        ChangeNotifierProvider(create: (_) => HomepageProvider()),
        ChangeNotifierProvider.value(value: activityProvider),
        ChangeNotifierProvider(create: (_) => StoreSettingsProvider()),
      ],
      child: const ArasanUserApp(),
    ),
  );
}
