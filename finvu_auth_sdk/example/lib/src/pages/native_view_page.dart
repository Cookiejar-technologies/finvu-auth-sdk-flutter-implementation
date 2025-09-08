import 'dart:convert';
import 'package:finvu_auth_sdk_flutter/finvu_auth_sdk.dart';
import 'package:flutter/material.dart';

class NativeViewPage extends StatefulWidget {
  const NativeViewPage({super.key});

  @override
  State<NativeViewPage> createState() => _NativeViewPageState();
}

class _NativeViewPageState extends State<NativeViewPage> {
  // Constants you can edit at compile time
  static const String APP_ID = '';
  static const String REQUEST_ID = '';

  late final IFinvuNativeWrapper _native = FinvuAuthSdk.nativeWrapper();

  final _phoneCtrl = TextEditingController();

  bool _initDone = false;
  String? _busy; // 'init' | 'start' | null
  Map<String, Object?>? _lastResponse;

  void _onPhoneChanged() => setState(() {});

  @override
  void initState() {
    super.initState();
    _native.setEnvironment(Environment.development);
    _phoneCtrl.addListener(_onPhoneChanged);
  }

  @override
  void dispose() {
    _phoneCtrl.removeListener(_onPhoneChanged);
    _phoneCtrl.dispose();
    _native.cleanupAll();
    super.dispose();
  }

  Future<void> _handleInitAuth() async {
    setState(() {
      _busy = 'init';
      _lastResponse = null;
    });

    try {
      final res = await _native.initAuth(
        InitConfig(appId: APP_ID, requestId: REQUEST_ID),
      );

      setState(() {
        _lastResponse = _toDisplayMap(res);
        _initDone = res.status == FinvuStatus.success;
      });
    } catch (e) {
      setState(() {
        _lastResponse = {'error': e.toString()};
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
      _lastResponse = null;
    });

    try {
      final res = await _native.startAuth(_phoneCtrl.text.trim());
      setState(() {
        _lastResponse = _toDisplayMap(res);
      });
    } catch (e) {
      setState(() {
        _lastResponse = {'error': e.toString()};
      });
    } finally {
      setState(() => _busy = null);
    }
  }

  bool get _canStart => _initDone && _phoneCtrl.text.trim().isNotEmpty;

  Map<String, Object?> _toDisplayMap(FinvuAuthResult r) {
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

  Future<bool> _onWillPop() async {
    try {
      await _native.cleanupAll();
    } catch (_) {}
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(10));
    final isInitBusy = _busy == 'init';
    final isStartBusy = _busy == 'start';

    return WillPopScope(
      onWillPop: _onWillPop,
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
            // Init button only
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _busy == null ? _handleInitAuth : null,
                child: Text(isInitBusy ? 'Initializing…' : 'Init Auth'),
              ),
            ),

            const Divider(height: 32),

            // Start inputs
            const Text(
              'Start / Verify',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                hintText: 'Enter phone number',
                border: border,
                enabled: _initDone && !isStartBusy,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_canStart && _busy == null)
                    ? _handleStartAuth
                    : null,
                child: Text(isStartBusy ? 'Starting…' : 'Start Auth'),
              ),
            ),

            const Divider(height: 32),

            const Text('SDK Response'),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _lastResponse != null
                    ? const JsonEncoder.withIndent('  ').convert(_lastResponse)
                    : 'No response yet.',
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
