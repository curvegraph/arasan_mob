import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'features/splash/widgets/branded_splash.dart';
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
import 'providers/shared_provider.dart';
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
  final binding = WidgetsFlutterBinding.ensureInitialized();

  // Keep the native launch splash (the peacock on navy) on screen until the
  // app has finished starting up, so the user sees ONE logo splash and then
  // the homepage — no intermediate Flutter loading screen. [_AppBootstrap]
  // calls FlutterNativeSplash.remove() the moment it's ready (or has to show
  // the offline retry screen).
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  // Bump Flutter's decoded-image cache so scrolling back to an already-seen
  // product/banner doesn't force a re-decode. Defaults are 1000 entries /
  // 100MB which a multi-section homepage easily exceeds.
  PaintingBinding.instance.imageCache.maximumSize = 3000;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 400 << 20; // 400MB

  // Load environment variables.
  // Override at build time with --dart-define=ENV=demo to use the demo project.
  const env = String.fromEnvironment('ENV', defaultValue: 'live');
  await dotenv.load(fileName: '.env.$env');

  // Native secure encrypted storage for Supabase session persistence. This is
  // local-only, so it's safe to do before we have network.
  final secureStorage = SecureLocalStorage();
  await secureStorage.initialize();

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

  // The remaining startup steps need the network (they fetch the Supabase
  // url/anon key from the backend, then init Supabase). If they ran here,
  // before runApp, a cold start with no internet would throw and leave the
  // engine on a black screen with no way to recover until the app is killed
  // and reopened. Defer them into [_AppBootstrap], which keeps a UI mounted
  // and shows a retry-able "no connection" screen that self-heals when the
  // network returns.
  runApp(_AppBootstrap(localStorage: secureStorage));
}

/// Gates the app on the async, network-dependent startup steps (backend
/// Supabase config + `Supabase.initialize`). Guarantees a widget tree is
/// always mounted, so a boot-time network failure shows a retry-able screen
/// and self-heals on reconnect instead of a black screen.
class _AppBootstrap extends StatefulWidget {
  final LocalStorage localStorage;
  const _AppBootstrap({required this.localStorage});

  @override
  State<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<_AppBootstrap> {
  String? _error; // null while trying; set when the last attempt failed.
  bool _booting = false;
  bool _supabaseReady = false; // Supabase.initialize may run only once.
  UserActivityProvider? _activityProvider;
  SearchProvider? _searchProvider;
  Timer? _retryTimer;
  int _attempt = 0;

  @override
  void initState() {
    super.initState();
    // Drop the native OS splash as soon as Flutter has painted its first frame
    // (our BrandedSplash — same navy + same centred logo). This is what makes
    // the logo appear on EVERY launch path: on a normal home-icon launch the OS
    // splash already shows the logo and Flutter continues it seamlessly; on a
    // deep-link launch (e.g. a product tapped in WhatsApp) the OS splash shows
    // only the navy background — Vivo/Oppo skip the icon for VIEW intents — so
    // the Flutter logo is the ONLY way the logo shows there.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
    _boot();
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  Future<void> _boot() async {
    if (_booting) return; // guard manual-retry + timer firing together
    _booting = true;
    _retryTimer?.cancel();
    if (mounted && _error != null) setState(() => _error = null);
    try {
      // Fetch Supabase url/anon key from the backend (idempotent — no-ops once
      // it has succeeded, so a retry after a partial failure is cheap).
      await SupabaseConfig.loadFromBackend();

      // Init Supabase exactly once, even across retries.
      if (!_supabaseReady) {
        await Supabase.initialize(
          url: SupabaseConfig.supabaseUrl,
          anonKey: SupabaseConfig.supabaseAnonKey,
          authOptions: FlutterAuthClientOptions(
            authFlowType: AuthFlowType.pkce,
            localStorage: widget.localStorage,
          ),
        );
        _supabaseReady = true;
      }

      // Local (non-network) providers.
      final activity = UserActivityProvider();
      await activity.init();
      final search = SearchProvider()..setActivityProvider(activity);

      _attempt = 0;
      if (mounted) {
        setState(() {
          _activityProvider = activity;
          _searchProvider = search;
          _error = null;
        });
      }
    } catch (e) {
      debugPrint('[AppBootstrap] startup failed: $e');
      if (mounted) setState(() => _error = e.toString());
      _scheduleRetry();
    } finally {
      _booting = false;
    }
  }

  /// Auto-retry on a capped backoff (2s, 4s, 8s, 16s, then 20s) so the app
  /// comes up within seconds of the connection recovering, without the user
  /// having to tap Retry.
  void _scheduleRetry() {
    _retryTimer?.cancel();
    final secs = (2 * (1 << _attempt)).clamp(2, 20);
    if (_attempt < 4) _attempt++;
    _retryTimer = Timer(Duration(seconds: secs), _boot);
  }

  @override
  Widget build(BuildContext context) {
    // Network startup done — hand off to the real app.
    if (_activityProvider != null && _searchProvider != null) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => PhoneAuthProvider()),
          ChangeNotifierProvider(create: (_) => ProductProvider()),
          ChangeNotifierProvider(create: (_) => BannerProvider()),
          ChangeNotifierProvider(create: (_) => OfferProvider()),
          ChangeNotifierProvider(create: (_) => CartProvider()),
          ChangeNotifierProvider(create: (_) => WishlistProvider()),
          ChangeNotifierProvider(create: (_) => SharedProvider()..load()),
          ChangeNotifierProvider(create: (_) => UserOrderProvider()),
          ChangeNotifierProvider(create: (_) => ReviewProvider()),
          ChangeNotifierProvider(create: (_) => NotificationProvider()),
          ChangeNotifierProvider.value(value: _searchProvider!),
          ChangeNotifierProvider(create: (_) => CheckoutProvider()),
          ChangeNotifierProvider(create: (_) => UserProfileProvider()),
          ChangeNotifierProvider(create: (_) => SupportProvider()),
          ChangeNotifierProvider(create: (_) => UserNavigationProvider()),
          ChangeNotifierProvider(create: (_) => HomepageProvider()),
          ChangeNotifierProvider.value(value: _activityProvider!),
          ChangeNotifierProvider(create: (_) => StoreSettingsProvider()),
        ],
        child: const ArasanUserApp(),
      );
    }

    // First attempt failed (offline) — reveal the retry-able "no connection"
    // screen (which self-heals when the network returns).
    if (_error != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: _BootScreen(error: _error, onRetry: _boot),
      );
    }

    // Still starting up for the first time — show the Flutter branded splash
    // (the same centred logo on the same navy as the OS splash) so the logo is
    // visible while backend/Supabase init runs, on every launch path.
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BrandedSplash(),
    );
  }
}

/// Branded pre-app screen. Renders the Arasan peacock + shop name on the
/// logo's navy background so it continues seamlessly from the native launch
/// splash (see the flutter_native_splash config in pubspec.yaml). Shows a
/// quiet spinner while startup is in flight, or a "no connection" message
/// with a Retry button when it has failed.
class _BootScreen extends StatelessWidget {
  final String? error;
  final Future<void> Function() onRetry;
  const _BootScreen({required this.error, required this.onRetry});

  // Sampled from assets/logo_round.png's ring so the circular logo blends
  // seamlessly into the background (no visible rectangle).
  static const Color _navy = Color(0xFF1F5593);
  static const Color _lime = Color(0xFFC6DE22);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            // logo_round has transparent corners, so it renders as a clean
            // disc on the matching background instead of a rectangle.
            Image.asset('assets/logo_round.png', width: 150),
            const SizedBox(height: 18),
            const Text.rich(
              TextSpan(children: [
                TextSpan(
                  text: 'Arasan ',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: 'Mobiles',
                  style: TextStyle(
                      color: _lime,
                      fontSize: 26,
                      fontWeight: FontWeight.bold),
                ),
              ]),
              textAlign: TextAlign.center,
            ),
            const Spacer(flex: 3),
            if (error == null)
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(Colors.white70),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_rounded,
                        size: 44, color: Colors.white70),
                    const SizedBox(height: 12),
                    const Text(
                      'No internet connection',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Check your connection. We'll reconnect "
                      "automatically once you're back online.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      onPressed: () => onRetry(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _navy,
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 56),
          ],
        ),
      ),
    );
  }
}
