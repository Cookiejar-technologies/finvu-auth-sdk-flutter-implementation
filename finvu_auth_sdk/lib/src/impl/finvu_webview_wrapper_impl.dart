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

        Future<Map<String, Object?>> call() async {
          switch (method) {
            case 'initAuth':
              {
                final initConfig = payload['initConfig'];
                final m = initConfig is String
                    ? jsonDecode(initConfig)
                    : (initConfig ?? {});
                final res = await _host.initAuth(
                  InitConfig(
                    appId: '${m['appId'] ?? ''}',
                    requestId: '${m['requestId'] ?? ''}',
                  ),
                );
                return _outgoing(res);
              }
            case 'startAuth':
              {
                final res = await _host.startAuth(
                  '${payload['phoneNumber'] ?? ''}',
                );
                return _outgoing(res);
              }
            case 'verifyOtp':
              {
                final res = await _host.verifyOtp(
                  VerifyOtpReq(
                    phoneNumber: '${payload['phoneNumber'] ?? ''}',
                    otp: (payload['otp'] as String?)?.trim(),
                  ),
                );
                return _outgoing(res);
              }
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

        final resultJsonString = jsonEncode(map); // '{"status":"SUCCESS", ...}'
        final quotedForJs = jsonEncode(
          resultJsonString,
        ); // '"{\"status\":\"SUCCESS\",...}"'

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

  Map<String, Object?> _outgoing(FinvuAuthResult r) {
    if (r.status == FinvuStatus.success) {
      return {
        'status': 'SUCCESS',
        if (r.data?.token != null) 'token': r.data!.token,
        if (r.data?.authType != null) 'authType': r.data!.authType,
        ...r.data?.extra ?? const {},
      };
    } else {
      return {
        'error': {
          'status': 'FAILURE',
          if (r.error?.errorCode != null) 'errorCode': r.error!.errorCode,
          if (r.error?.errorMessage != null)
            'errorMessage': r.error!.errorMessage,
          ...r.error?.details ?? const {},
        },
      };
    }
  }
}
