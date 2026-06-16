
import 'cw_nerva_platform_interface.dart';

class CwNerva {
  Future<String?> getPlatformVersion() {
    return CwNervaPlatform.instance.getPlatformVersion();
  }
}
