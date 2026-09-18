import '../api/finvu_host.dart' show IFinvuHost;
import '../api/finvu_native_wrapper.dart';
import '../models.dart';

class FinvuNativeWrapperImpl implements IFinvuNativeWrapper {
  final IFinvuHost _host;
  FinvuNativeWrapperImpl(this._host);

  @override
  Future<void> setEnvironment(Environment env) => _host.setEnvironment(env);

  // ── SNA factor ──────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> initSNA(InitConfig cfg) => _host.initSNA(cfg);

  @override
  Future<Map<String, dynamic>> startSNA(String snaLink) =>
      _host.startSNA(snaLink);

  @override
  Future<Map<String, dynamic>> initAuth(InitConfig cfg) => initSNA(cfg);

  @override
  Future<Map<String, dynamic>> startAuth(String snaLink) => startSNA(snaLink);

  @override
  Future<void> cleanupAll() => _host.cleanupAll();
}
