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

    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox) {
      return Rect.zero;
    }

    final rect = renderObject.localToGlobal(Offset.zero) & renderObject.size;
    // iOS requires sharePositionOrigin to lie fully within the source view's
    // bounds; clip to the screen so an offset/oversized page rect doesn't spill
    // past the edge and trigger a PlatformException on iPad.
    final screen = Offset.zero & MediaQuery.of(context).size;
    final clipped = rect.intersect(screen);
    if (clipped.isEmpty) {
      return Rect.zero;
    }
    return clipped;
  }
}
