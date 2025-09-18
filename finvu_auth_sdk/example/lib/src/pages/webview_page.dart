import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:finvu_auth_sdk_flutter/finvu_auth_sdk.dart';

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});
  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late final WebViewController _controller;
  late final IFinvuWebViewWrapper _wrapper;
  bool _ready = false;
  static const _webUrl = 'https://test-web-app-8a50c.web.app/?v=debug-1';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted);
    _wrapper = FinvuAuthSdk.webViewBridge();
    _init();
  }

  Future<void> _init() async {
    await _wrapper.setupWebView(
      env: Environment.development,
      controller: _controller,
    );
    await _controller.loadRequest(Uri.parse(_webUrl));
    setState(() => _ready = true);
  }

  @override
  void dispose() {
    _wrapper.cleanupAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WebView Flow')),
      body: _ready
          ? WebViewWidget(controller: _controller)
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
