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

Flutter's plugin registration is automatic — no `MainActivity` edits required.

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

if (init['error'] == null) {
  // 3. Start authentication with the SNA link
  final result = await native.startAuth('https://sna-url...');

  if (result['error'] == null) {
    debugPrint('Native SDK response: $result');
  } else {
    final error = result['error'] as Map;
    debugPrint('Failed: ${error['errorCode']} ${error['errorMessage']}');
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
example `mcc`/`mnc` from `initSNA`, `snaToken` from `startSNA`). The one
shape this plugin adds is on failure: it wraps the thrown native exception
into `{"error": {"status", "errorCode", "errorMessage"}}`, matching how the
RN wrapper reports failures.

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
  method: 'initAuth',          // or 'startAuth'
  callback: 'onFinvuInitAuth', // name of a function on `window`
  initConfig: { requestId: '...' },
  // for startAuth: snaLink: 'https://...'
}));
```

The result is handed back as a JSON **string** to `window[callback]`.

## API reference

`FinvuAuthSdk` is the factory for the three entry points:

| Factory | Returns | Use for |
|---|---|---|
| `FinvuAuthSdk.nativeWrapper()` | `IFinvuNativeWrapper` | Native flow |
| `FinvuAuthSdk.webViewBridge()` | `IFinvuWebViewWrapper` | WebView flow |
| `FinvuAuthSdk.host()` | `IFinvuHost` | Direct access to the platform channel |

Core types: `Environment`, `InitConfig`, `DeviceBindingConfig` (and its `DeviceBindingEnrollConfig`/`DeviceBindingSignConfig` subtypes). There is no typed response model — every call resolves to a raw `Map<String, dynamic>` (see "Usage" above).

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
