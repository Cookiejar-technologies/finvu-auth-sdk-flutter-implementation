# finvu_authentication_sdk

Flutter plugin for Finvu Authentication, supporting both native and WebView integration flows.

It wraps the same underlying native SDKs as the [React Native wrapper](https://github.com/Cookiejar-technologies/finvu-auth-sdk-react-native-implementation): the Android SDK from Maven Central and the iOS xcframework fetched by the podspec. Neither binary is checked into this repository.

## Installation

```bash
flutter pub add finvu_authentication_sdk
```

### iOS

```bash
cd ios && pod install
```

The iOS xcframework is downloaded automatically by the plugin's podspec — no manual `pod 'FinvuAuthenticationSDK', ...` line in your `Podfile`.

**Requirement:** iOS deployment target **≥ 16.0**. Bump it in `ios/Podfile` and in your Xcode project's "Minimum Deployments" setting.

For device binding, add a Face ID usage string to `ios/Runner/Info.plist`:

```xml
<key>NSFaceIDUsageDescription</key>
<string>Confirms it is you before signing in with this device.</string>
```

Add the carrier endpoints to your `ios/Runner/Info.plist` so Silent Network Authentication can make its HTTP calls:

```xml
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSExceptionDomains</key>
  <dict>
    <key>80.in.safr.sekuramobile.com</key>
    <dict>
      <key>NSExceptionAllowsInsecureHTTPLoads</key><true/>
      <key>NSIncludesSubdomains</key><true/>
    </dict>
    <key>api-csp.airtel.in</key>
    <dict>
      <key>NSExceptionAllowsInsecureHTTPLoads</key><true/>
      <key>NSIncludesSubdomains</key><true/>
    </dict>
    <key>in-vil.ipification.com</key>
    <dict>
      <key>NSExceptionAllowsInsecureHTTPLoads</key><true/>
      <key>NSIncludesSubdomains</key><true/>
    </dict>
    <key>partnerapi.jio.com</key>
    <dict>
      <key>NSExceptionAllowsInsecureHTTPLoads</key><true/>
      <key>NSIncludesSubdomains</key><true/>
    </dict>
  </dict>
</dict>
```

### Android

Flutter's plugin registration is automatic. For device binding, your
`MainActivity` must extend `FlutterFragmentActivity` instead of
`FlutterActivity`, because the device-lock prompt needs a FragmentActivity:

```kotlin
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity()
```

**Requirements:**

- `minSdkVersion` **≥ 25**.
- Add these permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.CHANGE_NETWORK_STATE" />
```

The Android SDK is pulled from Maven Central — no GitHub Packages credentials needed.

## Usage

### Option 1: Native integration

Use this when you build your own UI and call the SDK directly.

```dart
import 'package:finvu_authentication_sdk/finvu_authentication_sdk.dart';

final native = FinvuAuthSdk.nativeWrapper();

// 1. Set the environment (call once)
await native.setEnvironment(Environment.development);

// 2. Initialize authentication
final init = await native.initAuth(
  const InitConfig(requestId: 'your-request-id'),
);

if (init['status'] != 'FAILURE') {
  // 3. Start authentication with the SNA link
  final result = await native.startAuth('https://sna-url...');

  if (result['status'] != 'FAILURE') {
    debugPrint('Native SDK response: $result');
  } else {
    debugPrint('Failed: ${result['errorCode']} ${result['errorMessage']}');
  }
}

// 4. Cleanup when done
await native.cleanupAll();
```

Every call returns a `Map<String, dynamic>` decoded straight from the native
Android/iOS SDK's own JSON response — the same fields the native SDK
documents, unfiltered, exactly as the [React Native
wrapper](https://github.com/Cookiejar-technologies/finvu-auth-sdk-react-native-implementation)
hands back to JS. Nothing here reshapes it into a fixed schema, so read
whichever key the native SDK's own docs say a given call returns (for
example `mcc`/`mnc` from `initSNA`, `snaToken` from `startSNA`). Failures
come back in the native SDKs' own flat shape,
`{"status": "FAILURE", "errorCode", "errorMessage"}`, the same as the RN
wrapper.

#### Device binding

Each config is a plain map, passed to the native SDK unchanged. The keys are
the native SDK's own: see the Android/iOS SDK docs.

```dart
// Is the key from an earlier enrollment still usable? Local only.
final state = await native.getDeviceBindingState({'keyId': savedKeyId});

// Prompt for the device lock, create a key pair, store keyId + publicKey on your backend.
final enrolled = await native.enrollDeviceBinding({
  'requestId': requestId,
  'attestationChallenge': serverNonce, // optional, Android only
});

// Sign a server-issued challenge with whichever allowed key exists on this device.
final signed = await native.signDeviceBindingChallenge({
  'allowedKeyIds': [savedKeyId],
  'challenge': serverChallenge,
  'requestId': requestId,
});

// What this installed SDK build supports.
final caps = await native.getCapabilities();
```

### Option 2: WebView integration

Use this to load a web app that drives the UI, with the plugin bridging its calls to the native SDK.

```dart
import 'package:finvu_authentication_sdk/finvu_authentication_sdk.dart';
import 'package:webview_flutter/webview_flutter.dart';

final controller = WebViewController()
  ..setJavaScriptMode(JavaScriptMode.unrestricted);

final wrapper = FinvuAuthSdk.webViewBridge();

await wrapper.setupWebView(
  env: Environment.development,
  controller: controller,
);

await controller.loadRequest(Uri.parse('https://your-web-app.com'));

// In State.dispose():
await wrapper.cleanupAll();
```

Then render it with `WebViewWidget(controller: controller)`.

The web page talks to the plugin over the `finvu_authentication_bridge` JavaScript channel, posting messages of the form:

```js
finvu_authentication_bridge.postMessage(JSON.stringify({
  method: 'initAuth',          // see the table below
  callback: 'onFinvuInitAuth', // name of a function on `window`
  initConfig: { requestId: '...' },
}));
```

| `method` | Payload key |
|---|---|
| `initAuth` / `initSNA` | `initConfig` (object or JSON string) |
| `startAuth` / `startSNA` | `snaLink` |
| `getDeviceBindingState`, `enrollDeviceBinding`, `signDeviceBindingChallenge` | `config` (object or JSON string, passed to the native SDK unchanged) |
| `getCapabilities` | none |

The result is handed back as a JSON **string** to `window[callback]`, which
must be a global function (`window.onFinvuInitAuth = function (json) {...}`).
An unknown `method` gets an `UNSUPPORTED_METHOD` failure.

## API reference

`FinvuAuthSdk` is the factory for the three entry points:

| Factory | Returns | Use for |
|---|---|---|
| `FinvuAuthSdk.nativeWrapper()` | `IFinvuNativeWrapper` | Native flow |
| `FinvuAuthSdk.webViewBridge()` | `IFinvuWebViewWrapper` | WebView flow |
| `FinvuAuthSdk.host()` | `IFinvuHost` | Direct access to the platform channel |

Core types: `Environment`, `InitConfig`. Device binding configs are plain `Map<String, dynamic>`s. There is no typed response model — every call resolves to a raw `Map<String, dynamic>` (see "Usage" above).

## Example

A runnable demo covering both flows lives in [`example/`](example).

## Development

```bash
./scripts/build.sh verify    # codegen check, format, analyze, test, publish dry-run
./scripts/build.sh android   # build the example for Android
./scripts/build.sh ios       # build the example for iOS
```

Publishing is automated: push a `vX.Y.Z` tag matching `version` in `pubspec.yaml` and the
`Build and publish to pub.dev` workflow does the rest.

## Support

support@cookiejar.co.in · [finvu.in](https://finvu.in)
