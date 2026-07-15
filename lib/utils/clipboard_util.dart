import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/utils/device_info.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensitive_clipboard/sensitive_clipboard.dart';

class ClipboardUtil {
  static Future<void> setSensitiveDataToClipboard(ClipboardData data,
      {bool isSensitive = true}) async {
    if (isSensitive && DeviceInfo.instance.isMobile) {
      await SensitiveClipboard.copy(data.text);
      return;
    }

    return Clipboard.setData(data);
  }

  /// Copies [text] to the clipboard and shows a "Copied to Clipboard"
  /// confirmation toast. Prefer this for any user-facing copy action so the
  /// feedback stays consistent across the app.
  static Future<void> copyToClipboard(
    BuildContext context,
    String text, {
    bool isSensitive = false,
  }) async {
    await setSensitiveDataToClipboard(ClipboardData(text: text), isSensitive: isSensitive);
    if (context.mounted) {
      showBar<void>(context, S.of(context).copied_to_clipboard);
    }
  }
}
