import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:finvu_authentication_sdk/finvu_authentication_sdk.dart';

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});
  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  final _urlController = TextEditingController();
  WebViewController? _controller;
  IFinvuWebViewWrapper? _wrapper;
  bool _loaded = false;

  Future<void> _loadWebView() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {
            debugPrint('WebView error: ${error.description}');
          },
        ),
      );

    final wrapper = FinvuAuthSdk.webViewBridge();
    await wrapper.setupWebView(
      env: Environment.development,
      controller: controller,
    );
    await controller.loadRequest(Uri.parse(url));

    setState(() {
      _controller = controller;
      _wrapper = wrapper;
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _wrapper?.cleanupAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loaded && _controller != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('WebView Flow')),
        body: WebViewWidget(controller: _controller!),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('WebView Flow')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('WebView URL', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                hintText: 'https://...',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
              autocorrect: false,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadWebView,
              child: const Text('Load WebView'),
            ),
          ],
        ),
      ),
    );
  }
}
