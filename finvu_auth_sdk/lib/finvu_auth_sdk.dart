
import 'finvu_auth_sdk_platform_interface.dart';

class FinvuAuthSdk {
  Future<String?> getPlatformVersion() {
    return FinvuAuthSdkPlatform.instance.getPlatformVersion();
  }
}
