import '../api/finvu_host.dart' show IFinvuHost;
import '../api/finvu_native_wrapper.dart';
import '../models.dart';

class FinvuNativeWrapperImpl implements IFinvuNativeWrapper {
  final IFinvuHost _host;
  FinvuNativeWrapperImpl(this._host);

  @override
  Future<void> setEnvironment(Environment env) => _host.setEnvironment(env);

  @override
  Future<FinvuAuthResult> initAuth(InitConfig cfg) => _host.initAuth(cfg);

  @override
  Future<FinvuAuthResult> startAuth(String phoneNumber) =>
      _host.startAuth(phoneNumber);

  @override
  Future<FinvuAuthResult> verifyOtp(VerifyOtpReq req) => _host.verifyOtp(req);

  @override
  Future<void> cleanupAll() => _host.cleanupAll();
}
