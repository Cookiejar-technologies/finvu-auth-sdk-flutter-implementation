# Feature: WebView + JavaScript bridge

## Purpose

Lets a **hosted web app** (or local HTML) drive Finvu authentication **without** reimplementing the flow in Dart: the page posts JSON to a `JavaScriptChannel`, and Dart forwards to native via `IFinvuHost`.

## Where it lives

- Implementation: `lib/src/impl/finvu_webview_wrapper_impl.dart`
- Example: `example/lib/src/pages/webview_page.dart`
- Channel name: **`finvu_authentication_bridge`** (must match web polyfill)

## How to change behavior

1. **New auth method from JS:** Add handling in the `switch (method)` block; mirror native/Pigeon if a new API is added.
2. **Rename channel:** Change `_jsChannelName` and update every web client.
3. **Security:** Only load **trusted** URLs; see [security.md](./security.md).

## Dependencies

- `webview_flutter` (plugin `pubspec.yaml`)
