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
