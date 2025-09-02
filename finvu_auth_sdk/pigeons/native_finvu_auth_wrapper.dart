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
    dartPackageName: 'finvu_auth_sdk',
  ),
)
class InitConfig {
  String? appId;
  String? requestId;
}

enum Environment { production, development }

enum ErrorCode { invalidRequest, genericError }

enum FinvuStatus { success, failure }

class FinvuAuthSuccessResponse {
  String? token; // Authentication token
  String? authType; // Authentication method used
  Map<String, Object?>? extra; // Additional fields
}

class FinvuAuthFailureError {
  String? errorCode;
  String? errorMessage;
  Map<String, Object?>? details; // Additional error details
}

class FinvuAuthResult {
  /// Discriminator: SUCCESS or FAILURE
  FinvuStatus? status;

  /// Present when status == SUCCESS
  FinvuAuthSuccessResponse? data;

  /// Present when status == FAILURE
  FinvuAuthFailureError? error;
}

class VerifyOtpReq {
  String? phoneNumber;
  String? otp;
}

@HostApi()
abstract class FinvuHostApi {
  void setUp(Environment env);

  @async
  FinvuAuthResult initAuth(InitConfig config);

  @async
  FinvuAuthResult startAuth(String phoneNumber);

  @async
  FinvuAuthResult verifyOtp(VerifyOtpReq request);

  void cleanupAll();
}
