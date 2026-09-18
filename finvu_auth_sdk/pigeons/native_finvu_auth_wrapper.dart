import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/generated/native_finvu_auth_wrapper.g.dart',
    kotlinOut:
        'android/src/main/kotlin/com/finvu/finvu_auth_sdk/generated/NativeFinvuAuthWrapper.g.kt',
    swiftOut: 'ios/Classes/generated/NativeFinvuAuthWrapper.g.swift',
    kotlinOptions: KotlinOptions(
      package: 'com.finvu.finvu_auth_sdk',
      // Remove if your Pigeon version doesn't support it
      errorClassName: 'NativeFinvuAuthError',
    ),
    dartPackageName: 'finvu_authentication_sdk',
  ),
)
class InitConfig {
  String? requestId;
  String? entityId;
}

enum Environment { production, development }

/// Every call below hands back exactly the JSON the native Android/iOS SDK
/// produced, as a raw string — deliberately untyped. This mirrors the React
/// Native bridge (`FinvuAuthSdkRnModule`), which does `result.toString()` /
/// `JSONSerialization` passthrough rather than mapping onto a fixed schema.
/// Do NOT reintroduce a typed success/failure model here: previous versions
/// of this schema declared fields (statusCode, authType, token, requestId,
/// userId, timestamp) that neither native SDK has ever actually returned,
/// while real fields (mcc, mnc, httpStatusCode) got silently dropped into a
/// catch-all map — inconsistently between Android and iOS. Returning the raw
/// string sidesteps that class of bug entirely: whatever native sends is
/// exactly what the Dart caller gets, decoded but not filtered.
///
/// The one shape this bridge imposes is on failure: native calls throw an
/// exception rather than returning JSON, so something has to serialize it.
/// Both platform plugins wrap that into the same small
/// `{"error": {"status", "errorCode", "errorMessage"}}` envelope the RN
/// module uses, so failures look identical across RN, Android-native, and
/// iOS-native callers.
@HostApi()
abstract class FinvuHostApi {
  void setUp(Environment env);

  // SNA factor. Returns the native SDK's own response JSON, unmodified.
  @async
  String initSNA(InitConfig config);

  @async
  String startSNA(String snaLink);

  void cleanupAll();
}
