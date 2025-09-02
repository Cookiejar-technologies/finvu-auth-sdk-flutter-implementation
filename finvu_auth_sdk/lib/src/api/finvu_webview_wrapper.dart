import 'package:webview_flutter/webview_flutter.dart';
import '../models.dart';

abstract class IFinvuWebViewWrapper {
  /// Registers the JS channel and wires calls -> host.
  /// Must be called before (or right after) loadRequest.
  Future<void> setupWebView({
    required Environment env,
    required WebViewController controller,
  });

  /// Cleanup underlying native resources.
  Future<void> cleanupAll();
}
