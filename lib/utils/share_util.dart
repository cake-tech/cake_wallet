import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';

class ShareUtil {
  static void share({required String text, required BuildContext context}) {
    Share.share(
      text,
      sharePositionOrigin: _sharePosition(context),
    );
  }

  static Future<void> shareFile({
    required String filePath,
    required String fileName,
    required BuildContext context,
  }) async {
    const _mimeType = 'application/*';
    await Share.shareXFiles(
      <XFile>[
        XFile(
          filePath,
          name: fileName,
          mimeType: _mimeType,
        )
      ],
      sharePositionOrigin: _sharePosition(context),
    );
  }

  static Rect _sharePosition(BuildContext context) {
    if (!context.mounted) {
      return Rect.zero;
    }

    final box = context.findRenderObject() as RenderBox?;

    return box!.localToGlobal(Offset.zero) & box.size;
  }
}
