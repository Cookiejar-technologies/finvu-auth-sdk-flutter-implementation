import 'dart:convert';

import 'package:webview_flutter/webview_flutter.dart';

import '../api/finvu_host.dart';
import '../api/finvu_webview_wrapper.dart';
import '../models.dart';

class FinvuWebViewWrapperImpl implements IFinvuWebViewWrapper {
  // MUST match your web polyfill channel name
  static const String _jsChannelName = 'finvu_authentication_bridge';

  final IFinvuHost _host;
  FinvuWebViewWrapperImpl(this._host);

  @override
  Future<void> setupWebView({
    required Environment env,
    required WebViewController controller,
  }) async {
    await _host.setEnvironment(env);

    await controller.addJavaScriptChannel(
      _jsChannelName,
      onMessageReceived: (msg) async {
        Map<String, dynamic> payload;
        try {
          payload = Map<String, dynamic>.from(jsonDecode(msg.message));
        } catch (_) {
          return;
        }

        final method = (payload['method'] as String?) ?? '';
        final callback = (payload['callback'] as String?) ?? '';

        // Every branch below hands back exactly what the native Android/iOS
        // SDK returned via _host — no field allow-list, no reshaping. This
        // matches the native and React Native bridges: the web page gets the
        // same JSON the native SDK produced.
        Future<Map<String, dynamic>> call() async {
          switch (method) {
            // Both the original and the factor-explicit names reach the same
            // host call, so a page can move to initSNA/startSNA at its own pace.
            case 'initAuth':
            case 'initSNA':
              {
                final initConfig = payload['initConfig'];
                final m = initConfig is String
                    ? jsonDecode(initConfig)
                    : (initConfig ?? {});
                return _host.initSNA(
                  InitConfig(
                    requestId: '${m['requestId'] ?? ''}',
                    entityId: m['entityId'] == null ? null : '${m['entityId']}',
                  ),
                );
              }
            case 'startAuth':
            case 'startSNA':
              return _host.startSNA('${payload['snaLink'] ?? ''}');
            default:
              return {
                'error': {
                  'status': 'FAILURE',
                  'errorCode': 'UNSUPPORTED_METHOD',
                  'errorMessage': 'Unsupported method: $method',
                },
              };
          }
        }

        final map = await call();
        if (callback.isEmpty) return;

        final resultJsonString = jsonEncode(map); // '{"status":"...", ...}'
        final quotedForJs = jsonEncode(
          resultJsonString,
        ); // '"{\"status\":\"...\",...}"'

        final js =
            '''
                (function(){
                  try {
                    var cb = window["$callback"];
                    if (typeof cb === "function") { cb($quotedForJs); } // pass STRING
                    else { console.warn("Finvu callback '$callback' not found"); }
                  } catch (e) { console.error(e); }
                })();
            ''';
        await controller.runJavaScript(js);
      },
    );
  }

  @override
  Future<void> cleanupAll() => _host.cleanupAll();
}
