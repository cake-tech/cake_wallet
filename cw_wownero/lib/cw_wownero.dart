
import 'cw_wownero_platform_interface.dart';

class CwWownero {
  Future<String?> getPlatformVersion() {
    return CwWowneroPlatform.instance.getPlatformVersion();
  }
}
