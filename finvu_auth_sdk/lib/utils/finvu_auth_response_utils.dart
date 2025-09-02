import '../src/generated/native_finvu_auth_wrapper.g.dart';

class AuthResponseUtils {
  /// Returns the error code string for an [ErrorCode] enum.
  static String getErrorCode(ErrorCode code) {
    switch (code) {
      case ErrorCode.invalidRequest:
        return "1001";
      case ErrorCode.genericError:
        return "1002";
    }
  }

  /// Returns a capitalised string for a [FinvuStatus] enum.
  /// Example: FinvuStatus.success -> "Success"
  static String getStatusString(FinvuStatus status) {
    switch (status) {
      case FinvuStatus.success:
        return "SUCCESS";
      case FinvuStatus.failure:
        return "FAILURE";
    }
  }
}
