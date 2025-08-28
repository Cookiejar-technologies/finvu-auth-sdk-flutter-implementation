import '../models.dart';

abstract class IFinvuNativeWrapper {
  Future<void> setEnvironment(Environment env);
  Future<FinvuAuthResult> initAuth(InitConfig cfg);
  Future<FinvuAuthResult> startAuth(String phoneNumber);
  Future<FinvuAuthResult> verifyOtp(VerifyOtpReq req);
  Future<void> cleanupAll();
}
