
import 'cw_monero_platform_interface.dart';

class CwMonero {
  Future<String?> getPlatformVersion() {
    return CwMoneroPlatform.instance.getPlatformVersion();
  }
}
