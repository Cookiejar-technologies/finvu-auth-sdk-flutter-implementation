## 1.0.3

Device binding is back, now on native SDKs that actually provide it.

* Added `getDeviceBindingState`, `enrollDeviceBinding`,
  `signDeviceBindingChallenge` and `getCapabilities` to the native wrapper and
  the WebView bridge. Each config is a plain `Map<String, dynamic>` (or, from a
  web page, an object or JSON string) handed to the native SDK unchanged, and
  each response is the native SDK's own JSON, the same as the React Native SDK.
* Native SDKs updated: Android `finvuauthenticationsdk` 1.0.3 → 1.1.4, iOS
  `finvu-auth-sdk-ios` v1.0.5 → v1.1.3. Both add device binding and
  certificate pinning on auth event logging.
* **Breaking:** failures now come back in the native SDKs' flat shape,
  `{"status": "FAILURE", "errorCode", "errorMessage"}`, instead of
  `{"error": {...}}`. Check `result['status'] == 'FAILURE'` rather than
  `result['error']`. This matches React Native SDK 1.0.3.
* Android apps using device binding must use `FlutterFragmentActivity` as
  their `MainActivity`; iOS apps need `NSFaceIDUsageDescription` in
  `Info.plist`.

## 1.0.2

**Breaking:** Removed `getDeviceBindingState`, `enrollDeviceBinding`,
`signDeviceBindingChallenge` and `getCapabilities`, along with
`DeviceBindingConfig`, `DeviceBindingEnrollConfig` and
`DeviceBindingSignConfig`.

* Why: the native SDK versions this plugin pins (Android
  `finvuauthenticationsdk:1.0.3`, iOS `finvu-auth-sdk-ios` tag `v1.0.5`) only
  ever exposed `initAuth`/`startAuth` — no device binding API exists on
  either at those versions. The plugin's Kotlin/Swift code called
  `initSNA`/`startSNA`/device-binding methods that don't exist on the pinned
  dependency, which failed to compile in any consuming app. Fixed by having
  the plugin call the native SDK's real `initAuth`/`startAuth` methods (the
  Dart-facing `initSNA`/`startSNA`/`initAuth`/`startAuth` names are
  unaffected) and removing the device-binding surface this SDK version
  cannot actually deliver.

## 1.0.1

**Breaking:** `initSNA`, `startSNA`, `getDeviceBindingState`, `enrollDeviceBinding`,
`signDeviceBindingChallenge` and `getCapabilities` now resolve to a raw
`Map<String, dynamic>` decoded straight from the native Android/iOS SDK's own
JSON response, instead of a typed `FinvuAuthResult` / `DeviceBindingResult` /
`FinvuCapabilities` object.

* Removed `FinvuAuthResult`, `FinvuAuthSuccess`, `FinvuAuthFailure`,
  `FinvuStatus`, `DeviceBindingResult`, `DeviceBindingSuccess`,
  `DeviceBindingState` and `FinvuCapabilities` — the plugin no longer maps
  responses onto a fixed field list.
* Why: that field list (`statusCode`, `authType`, `token`, `requestId`,
  `userId`, `timestamp`) was never actually returned by either native SDK.
  The fields the SDKs do return (`mcc`, `mnc`, `httpStatusCode`, iOS's
  `statusCode`) were falling into a catch-all `extra` map — and doing so
  *inconsistently* between Android and iOS, since the two platform plugins'
  "known field" lists didn't agree on where the native `status` string
  belonged. Returning the native JSON unmodified (matching the [React Native
  wrapper](https://github.com/Cookiejar-technologies/finvu-auth-sdk-react-native-implementation),
  which has always done a raw passthrough) removes that class of bug rather
  than patching one more instance of it.
* On failure the map carries a single `error` key
  (`{"status", "errorCode", "errorMessage"}`), matching the RN wrapper's own
  error shape.
* Native SDK dependency versions: `io.github.cookiejar-technologies:finvuauthenticationsdk:1.0.3`
  (Android), `finvu-auth-sdk-ios` tag `v1.0.5` (iOS). These are pinned
  deliberately and no longer track the React Native wrapper's versions.

## 1.0.0


Initial release of `finvu_authentication_sdk`.

* Silent Network Authentication (SNA) for Finvu Account Aggregator flows on
  Android and iOS.
* Native integration via `FinvuAuthSdk.nativeWrapper()`.
* WebView integration via `FinvuAuthSdk.webViewBridge()`, bridging the
  `finvu_authentication_bridge` JavaScript channel to the native SDK.

> Supersedes the unmaintained `finvu_auth_sdk` and `finvu_auth_sdk_flutter`
> packages, which are no longer updated.
