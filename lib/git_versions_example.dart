import 'dart:io';

/*ANDROID_VERSION*/ const ANDROID_VERSION = "";
/*IOS_VERSION*/ const IOS_VERSION = "";
/*MACOS_VERSION*/ const MACOS_VERSION = "";
/*LINUX_VERSION*/ const LINUX_VERSION = "";
/*WINDOWS_VERSION*/ const WINDOWS_VERSION = "";

String getPluginVersion() {
  if (Platform.isAndroid) {
    return ANDROID_VERSION;
  } else if (Platform.isIOS) {
    return IOS_VERSION;
  } else if (Platform.isMacOS) {
    return MACOS_VERSION;
  } else if (Platform.isLinux) {
    return LINUX_VERSION;
  } else if (Platform.isWindows) {
    return WINDOWS_VERSION;
  } else {
    return "Unknown version";
  }
}
