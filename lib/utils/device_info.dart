import 'dart:io';

class DeviceInfo {
  DeviceInfo._();

  static DeviceInfo get instance => DeviceInfo._();

  bool get isMobile => Platform.isAndroid || Platform.isIOS;
  
  bool get isDesktop => Platform.isMacOS || Platform.isWindows || Platform.isLinux;
}