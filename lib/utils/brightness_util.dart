import 'package:cake_wallet/utils/device_info.dart';
import 'package:screen_brightness/screen_brightness.dart';

class BrightnessUtil {
  static Future<void> changeBrightnessForFunction(Future<void> Function() func) async {
    // if not mobile, just navigate
    if (!DeviceInfo.instance.isMobile) {
      func();
      return;
    }

    // Get the current brightness:
    final double brightness = await ScreenBrightness().current;

    // ignore: unawaited_futures
    await ScreenBrightness().setScreenBrightness(1.0);

    await func();

    // ignore: unawaited_futures
    await ScreenBrightness().setScreenBrightness(brightness);
  }
}