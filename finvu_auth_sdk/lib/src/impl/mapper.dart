import '../models.dart' as pub;
import '../generated/native_finvu_auth_wrapper.g.dart' as pig;

pig.Environment toPigEnv(pub.Environment e) => e == pub.Environment.development
    ? pig.Environment.development
    : pig.Environment.production;

pub.FinvuStatus _toPubStatus(pig.FinvuStatus? s) => s == pig.FinvuStatus.success
    ? pub.FinvuStatus.success
    : pub.FinvuStatus.failure;

pub.FinvuAuthResult toPubResult(pig.FinvuAuthResult r) {
  final status = _toPubStatus(r.status);
  if (status == pub.FinvuStatus.success) {
    final d = r.data;
    return pub.FinvuAuthResult.success(
      pub.FinvuAuthSuccess(
        token: d?.token,
        authType: d?.authType,
        extra: Map<String, Object?>.from(d?.extra ?? const {}),
      ),
    );
  } else {
    final e = r.error;
    return pub.FinvuAuthResult.failure(
      pub.FinvuAuthFailure(
        errorCode: e?.errorCode,
        errorMessage: e?.errorMessage,
        details: Map<String, Object?>.from(e?.details ?? const {}),
      ),
    );
  }
}

pig.InitConfig toPigInit(pub.InitConfig c) =>
    pig.InitConfig(appId: c.appId, requestId: c.requestId);

pig.VerifyOtpReq toPigVerify(pub.VerifyOtpReq r) =>
    pig.VerifyOtpReq(phoneNumber: r.phoneNumber, otp: r.otp);
