import 'api/finvu_host.dart';
import 'api/finvu_native_wrapper.dart';
import 'api/finvu_webview_wrapper.dart';
import 'impl/finvu_host_impl.dart';
import 'impl/finvu_native_wrapper_impl.dart';
import 'impl/finvu_webview_wrapper_impl.dart';

/// Single place where we decide which concrete classes to use.
/// We can swap implementations later without breaking app code.
class FinvuAuthSdk {
  /// Default host (Pigeon-based)
  static IFinvuHost host() => FinvuHostImpl();

  /// Default WebView bridge (uses host)
  static IFinvuWebViewWrapper webViewBridge([IFinvuHost? host]) =>
      FinvuWebViewWrapperImpl(host ?? FinvuHostImpl());

  /// Default Native wrapper (uses host)
  static IFinvuNativeWrapper nativeWrapper([IFinvuHost? host]) =>
      FinvuNativeWrapperImpl(host ?? FinvuHostImpl());
}
