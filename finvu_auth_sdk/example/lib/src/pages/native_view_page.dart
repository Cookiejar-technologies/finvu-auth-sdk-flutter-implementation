import 'dart:convert';
import 'package:finvu_authentication_sdk/finvu_authentication_sdk.dart';
import 'package:flutter/material.dart';

class NativeViewPage extends StatefulWidget {
  const NativeViewPage({super.key});

  @override
  State<NativeViewPage> createState() => _NativeViewPageState();
}

class _NativeViewPageState extends State<NativeViewPage> {
  static const String requestId = '';

  late final IFinvuNativeWrapper _native = FinvuAuthSdk.nativeWrapper();

  final _snaLinkCtrl = TextEditingController();

  bool _initDone = false;
  String? _busy; // 'init' | 'start' | null
  Map<String, dynamic>? _initResponse;
  Map<String, dynamic>? _startResponse;

  void _onSnaLinkChanged() => setState(() {});

  @override
  void initState() {
    super.initState();
    _native.setEnvironment(Environment.development);
    _snaLinkCtrl.addListener(_onSnaLinkChanged);
  }

  @override
  void dispose() {
    _snaLinkCtrl.removeListener(_onSnaLinkChanged);
    _snaLinkCtrl.dispose();
    _native.cleanupAll();
    super.dispose();
  }

  /// True unless the native SDK's response has status FAILURE. The
  /// native SDK decides the field shape entirely; this page doesn't check for
  /// any particular field beyond that.
  bool _isSuccess(Map<String, dynamic> res) => res['status'] != 'FAILURE';

  Future<void> _handleInitAuth() async {
    setState(() {
      _busy = 'init';
      _initResponse = null;
    });

    try {
      final res = await _native.initAuth(InitConfig(requestId: requestId));
      setState(() {
        _initResponse = res;
        _initDone = _isSuccess(res);
      });
    } catch (e) {
      setState(() {
        _initResponse = {'error': e.toString()};
        _initDone = false;
      });
    } finally {
      setState(() => _busy = null);
    }
  }

  Future<void> _handleStartAuth() async {
    if (!_canStart) return;
    setState(() {
      _busy = 'start';
      _startResponse = null;
    });

    try {
      final res = await _native.startAuth(_snaLinkCtrl.text.trim());
      setState(() => _startResponse = res);
    } catch (e) {
      setState(() => _startResponse = {'error': e.toString()});
    } finally {
      setState(() => _busy = null);
    }
  }

  bool get _canStart => _initDone && _snaLinkCtrl.text.trim().isNotEmpty;

  Widget _responseBox(Map<String, dynamic>? response) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        response != null
            ? const JsonEncoder.withIndent('  ').convert(response)
            : 'No response yet.',
        style: const TextStyle(fontFamily: 'monospace'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(10));
    final isInitBusy = _busy == 'init';
    final isStartBusy = _busy == 'start';

    return PopScope(
      onPopInvokedWithResult: (_, __) => _native.cleanupAll(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Finvu Auth — Native View'),
          actions: [
            TextButton.icon(
              onPressed: _busy == null
                  ? () async {
                      await _native.cleanupAll();
                      if (context.mounted) Navigator.pop(context);
                    }
                  : null,
              icon: const Icon(Icons.close),
              label: const Text('Close & Cleanup'),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _busy == null ? _handleInitAuth : null,
                child: Text(isInitBusy ? 'Initializing…' : 'Init Auth'),
              ),
            ),
            const SizedBox(height: 12),
            _responseBox(_initResponse),

            const Divider(height: 32),

            TextField(
              controller: _snaLinkCtrl,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: 'SNA Link',
                hintText: 'Enter SNA link',
                border: border,
                enabled: _initDone && !isStartBusy,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_canStart && _busy == null) ? _handleStartAuth : null,
                child: Text(isStartBusy ? 'Starting…' : 'Start Auth'),
              ),
            ),
            const SizedBox(height: 12),
            _responseBox(_startResponse),
          ],
        ),
      ),
    );
  }
}
