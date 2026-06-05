/// Global flag tracking whether Firebase initialised successfully.
///
/// Phone login depends on Firebase Auth; if the project is still using
/// placeholder `firebase_options.dart` values (or the config file is missing),
/// `Firebase.initializeApp` throws and phone-based sign-in must be hidden or
/// shown with a clear error rather than letting the app crash.
///
/// `main.dart` calls [markAvailable] / [markUnavailable] after attempting
/// `Firebase.initializeApp(...)`. UI code reads [isAvailable] / [lastError].
class FirebaseAvailability {
  FirebaseAvailability._();

  static bool _available = false;
  static String? _lastError;

  static bool get isAvailable => _available;
  static String? get lastError => _lastError;

  static void markAvailable() {
    _available = true;
    _lastError = null;
  }

  static void markUnavailable(String error) {
    _available = false;
    _lastError = error;
  }
}
