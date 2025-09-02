import '../api/finvu_host.dart';
import '../models.dart' as pub;
import '../generated/native_finvu_auth_wrapper.g.dart' as pig;
import 'mapper.dart';

class FinvuHostImpl implements IFinvuHost {
  final pig.FinvuHostApi _api = pig.FinvuHostApi();

  @override
  Future<void> setEnvironment(pub.Environment env) => _api.setUp(toPigEnv(env));

  @override
  Future<pub.FinvuAuthResult> initAuth(pub.InitConfig cfg) async =>
      toPubResult(await _api.initAuth(toPigInit(cfg)));

  @override
  Future<pub.FinvuAuthResult> startAuth(String phoneNumber) async =>
      toPubResult(await _api.startAuth(phoneNumber));

  @override
  Future<pub.FinvuAuthResult> verifyOtp(pub.VerifyOtpReq req) async =>
      toPubResult(await _api.verifyOtp(toPigVerify(req)));

  @override
  Future<void> cleanupAll() => _api.cleanupAll();
}
