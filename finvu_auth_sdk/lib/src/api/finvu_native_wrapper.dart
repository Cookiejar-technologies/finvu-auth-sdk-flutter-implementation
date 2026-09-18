import '../models.dart';

/// Native entry point for Silent Network Authentication (SNA).
///
/// [initSNA] reads MCC/MNC; [startSNA] runs the cellular SNA request.
///
/// `initAuth` and `startAuth` are the original method names, kept permanently
/// so apps built against earlier versions keep working.
///
/// Every method returns the native Android/iOS SDK's own JSON response,
/// decoded into a `Map<String, dynamic>` and otherwise untouched — no field
/// allow-list, no reshaping, exactly like the React Native bridge. A failure
/// comes back as a map with a single `error` key
/// (`{"status", "errorCode", "errorMessage"}`) rather than a thrown exception.
abstract class IFinvuNativeWrapper {
  Future<void> setEnvironment(Environment env);

  // ── SNA factor ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> initSNA(InitConfig cfg);
  Future<Map<String, dynamic>> startSNA(String snaLink);

  /// Original name for [initSNA], kept for apps built against earlier versions.
  Future<Map<String, dynamic>> initAuth(InitConfig cfg);

  /// Original name for [startSNA], kept for apps built against earlier versions.
  Future<Map<String, dynamic>> startAuth(String snaLink);

  /// Ends the authentication session. Call this once when the user leaves the flow.
  Future<void> cleanupAll();
}
