import 'package:flutter/services.dart';

import 'package:cake_wallet/utils/device_info.dart';
import 'package:sensitive_clipboard/sensitive_clipboard.dart';

class ClipboardUtil {
  static Future<void> setSensitiveDataToClipboard(ClipboardData data, {bool isSensitive = true}) async {
    if (isSensitive && DeviceInfo.instance.isMobile) {
      await SensitiveClipboard.copy(data.text);
      return;
    }

    return Clipboard.setData(data);
  }
}
