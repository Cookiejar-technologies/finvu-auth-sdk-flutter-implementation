import '../models.dart' as pub;
import '../generated/native_finvu_auth_wrapper.g.dart' as pig;

// This file only maps *inputs* (app config -> Pigeon args). Responses are no
// longer mapped at all: FinvuHostImpl decodes the native JSON straight into a
// Map<String, dynamic> and hands it back untouched. Do not add a
// toPubResult/toPubCapabilities-style function back here — that's the pattern
// that caused Android and iOS to disagree on what ended up in a response.

pig.Environment toPigEnv(pub.Environment e) => e == pub.Environment.development
    ? pig.Environment.development
    : pig.Environment.production;

pig.InitConfig toPigInit(pub.InitConfig c) =>
    pig.InitConfig(requestId: c.requestId, entityId: c.entityId);

/// One Pigeon config carries the union of every device binding call's arguments;
/// each overload below fills in only the fields its call actually uses.
pig.DeviceBindingConfig toPigDeviceBinding(pub.DeviceBindingConfig c) {
  if (c is pub.DeviceBindingSignConfig) {
    return pig.DeviceBindingConfig(
      userId: c.userId,
      entityId: c.entityId,
      challenge: c.challenge,
      promptTitle: c.promptTitle,
      promptSubtitle: c.promptSubtitle,
    );
  }
  if (c is pub.DeviceBindingEnrollConfig) {
    return pig.DeviceBindingConfig(
      userId: c.userId,
      entityId: c.entityId,
      attestationChallenge: c.attestationChallenge,
    );
  }
  return pig.DeviceBindingConfig(userId: c.userId, entityId: c.entityId);
}
