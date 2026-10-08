import '../models.dart';

/// Thin seam over the Pigeon channel. Both factors funnel through here so the
/// wrappers stay free of platform-channel detail.
///
/// Every call hands back exactly what the native Android/iOS SDK returned,
/// JSON-decoded and otherwise untouched — no field allow-list, no reshaping.
/// This mirrors the React Native bridge, which does the same (`JSON.parse` on
/// whatever the native module resolves with) rather than mapping onto a fixed
/// schema. On failure it is the native SDK's own flat
/// `{"status": "FAILURE", "errorCode", "errorMessage"}` object, matching RN.
abstract class IFinvuHost {
  Future<void> setEnvironment(Environment env);

  // SNA factor.
  Future<Map<String, dynamic>> initSNA(InitConfig cfg);
  Future<Map<String, dynamic>> startSNA(String snaLink);

  // Device binding factor. Each takes the call's config as a JSON string and
  // forwards it to the native SDK unchanged, like RN's native module.
  Future<Map<String, dynamic>> getDeviceBindingState(String configJson);
  Future<Map<String, dynamic>> enrollDeviceBinding(String configJson);
  Future<Map<String, dynamic>> signDeviceBindingChallenge(String configJson);

  Future<Map<String, dynamic>> getCapabilities();

  Future<void> cleanupAll();
}
