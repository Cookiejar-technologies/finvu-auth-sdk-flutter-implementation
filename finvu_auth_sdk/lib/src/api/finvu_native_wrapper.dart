import '../models.dart';

/// Native entry point for both authentication factors.
///
/// **SNA** — [initSNA] reads MCC/MNC; [startSNA] runs the cellular SNA request.
///
/// **Device binding** — [getDeviceBindingState], [enrollDeviceBinding] and
/// [signDeviceBindingChallenge] manage a hardware-backed key pair. Unlike SNA
/// these need no cellular connection, and [getDeviceBindingState] is callable
/// straight after [setEnvironment] with no requestId.
///
/// `initAuth` and `startAuth` are the original SNA method names, kept permanently
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

  // ── Device binding factor ─────────────────────────────────────────────────

  /// Reports whether this user has a usable device binding key.
  ///
  /// Purely local — no network, no cellular requirement, no user interaction — so
  /// unlike the SNA methods this can be called immediately after
  /// [setEnvironment]. Use it to decide whether to enroll or to sign.
  Future<Map<String, dynamic>> getDeviceBindingState(DeviceBindingConfig cfg);

  /// Creates a fresh hardware-backed key pair and returns the public key for the
  /// server to store. Replaces any existing key, so this is also the recovery
  /// path from an INVALIDATED state.
  Future<Map<String, dynamic>> enrollDeviceBinding(
    DeviceBindingEnrollConfig cfg,
  );

  /// Signs a server-issued challenge, prompting for biometric authentication first.
  Future<Map<String, dynamic>> signDeviceBindingChallenge(
    DeviceBindingSignConfig cfg,
  );

  /// Describes what this installed SDK build supports.
  Future<Map<String, dynamic>> getCapabilities();

  /// Ends the whole authentication session.
  ///
  /// Call this once when the user leaves the flow — **not** between factors. An
  /// MFA flow runs SNA and device binding against one session. Enrolled device
  /// binding keys are unaffected; they live in the platform keystore and survive
  /// across sessions by design.
  Future<void> cleanupAll();
}
