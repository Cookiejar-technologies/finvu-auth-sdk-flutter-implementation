import '../models.dart';

/// Native entry point for both authentication factors.
///
/// **SNA**: [initSNA] reads MCC/MNC; [startSNA] runs the cellular SNA request.
///
/// **Device binding**: [getDeviceBindingState], [enrollDeviceBinding] and
/// [signDeviceBindingChallenge] manage a hardware-backed key pair. Each takes
/// the same config keys as the native Android/iOS and React Native SDKs, as a
/// map that is JSON-encoded and handed to the native SDK unchanged.
///
/// `initAuth` and `startAuth` are the original method names, kept permanently
/// so apps built against earlier versions keep working.
///
/// Every method returns the native Android/iOS SDK's own JSON response,
/// decoded into a `Map<String, dynamic>` and otherwise untouched — no field
/// allow-list, no reshaping, exactly like the React Native bridge. A failure
/// comes back as the native SDK's flat
/// `{"status": "FAILURE", "errorCode", "errorMessage"}` map rather than a
/// thrown exception.
abstract class IFinvuNativeWrapper {
  Future<void> setEnvironment(Environment env);

  // ── SNA factor ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> initSNA(InitConfig cfg);
  Future<Map<String, dynamic>> startSNA(String snaLink);

  /// Original name for [initSNA], kept for apps built against earlier versions.
  Future<Map<String, dynamic>> initAuth(InitConfig cfg);

  /// Original name for [startSNA], kept for apps built against earlier versions.
  Future<Map<String, dynamic>> startAuth(String snaLink);

  // ── Device binding factor ─────────────────────────────────────────────────

  /// Reports whether `config['keyId']` from a previous [enrollDeviceBinding]
  /// still has a usable key. Local only, so it may be called before [initSNA].
  Future<Map<String, dynamic>> getDeviceBindingState(
    Map<String, dynamic> config,
  );

  /// Prompts for the device lock, then creates a fresh key pair and returns
  /// its keyId and public key for your backend to store.
  Future<Map<String, dynamic>> enrollDeviceBinding(Map<String, dynamic> config);

  /// Signs a server-issued challenge with whichever of `allowedKeyIds` exists
  /// on this device, after a device-lock prompt.
  Future<Map<String, dynamic>> signDeviceBindingChallenge(
    Map<String, dynamic> config,
  );

  /// Describes what this installed native SDK build supports.
  Future<Map<String, dynamic>> getCapabilities();

  /// Ends the authentication session. Call this once when the user leaves the flow.
  Future<void> cleanupAll();
}
