// Public enums the app will use
enum Environment { production, development }

enum FinvuStatus { success, failure }

// Public success/failure models
class FinvuAuthSuccess {
  final String? token;
  final String? authType;
  final Map<String, Object?> extra;
  const FinvuAuthSuccess({this.token, this.authType, this.extra = const {}});
}

class FinvuAuthFailure {
  final String? errorCode;
  final String? errorMessage;
  final Map<String, Object?> details;
  const FinvuAuthFailure({
    this.errorCode,
    this.errorMessage,
    this.details = const {},
  });
}

class FinvuAuthResult {
  final FinvuStatus status;
  final FinvuAuthSuccess? data;
  final FinvuAuthFailure? error;
  const FinvuAuthResult.success(FinvuAuthSuccess d)
    : status = FinvuStatus.success,
      data = d,
      error = null;
  const FinvuAuthResult.failure(FinvuAuthFailure e)
    : status = FinvuStatus.failure,
      data = null,
      error = e;
}

// Convenience input DTOs
class InitConfig {
  final String appId;
  final String requestId;
  const InitConfig({required this.appId, required this.requestId});
}

class VerifyOtpReq {
  final String phoneNumber;
  final String? otp;
  const VerifyOtpReq({required this.phoneNumber, this.otp});
}
