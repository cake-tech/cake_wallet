import 'package:cake_wallet/utils/device_info.dart';
import 'package:device_display_brightness/device_display_brightness.dart';

class BrightnessUtil {
  static Future<void> changeBrightnessForFunction(Future<void> Function() func) async {
    // if not mobile, just navigate
    if (!DeviceInfo.instance.isMobile) {
      func();
      return;
    }

    // ignore: unawaited_futures
    DeviceDisplayBrightness.setBrightness(1.0);

    await func();

    // ignore: unawaited_futures
    DeviceDisplayBrightness.resetBrightness();
  }
}