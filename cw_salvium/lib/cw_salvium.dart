import 'cw_salvium_platform_interface.dart';

class CwSalvium {
  Future<String?> getPlatformVersion() {
    return CwSalviumPlatform.instance.getPlatformVersion();
  }
}
